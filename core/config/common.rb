

module ProjectHanlon
  module Config
    module Common

      attr_reader   :hanlon_uri
      attr_reader   :websvc_root

      # The fixed header injected at the top of any configuration file we write.
      ConfigHeader = <<EOT
#
# This file is the main configuration for ProjectHanlon
#
# -- this was system generated --
#
#
EOT

      def self.instance

        unless @_instance
          if(File.exist?($config_file_path))
            config = YAML.load_file($config_file_path)
          else
            raise "Configuration file missing at #{$config_file_path}"
          end

          # OK, the first round of validation that this is a good config; this
          # also handles upgrading the schema stored in the YAML file, if needed.
          # ToDo::Sankar::Implement - improve configuration file validation
          #    return proper error messages on failed validation keys

          if  config.is_a? ProjectHanlon::Config::Client or
              config.is_a? ProjectHanlon::Config::Server or
              config.is_a? ProjectHanlon::Config::DbMigrate
            config.defaults.each_pair {|key, value| config[key] ||= value }
          else
            raise "Invalid configuration file (#{$config_file_path})"
            config = nil
          end

          @_instance = config
        end
        return @_instance
      end

      # Reset the singleton to the default state, primarily used for testing.
      # @api private
      def self._reset_instance
        @_instance = nil
      end

      def initialize
        defaults.each_pair {|name, value| self[name] = value }
        @noun = "config"
      end
      private "initialize"

      # reader methods for derived parameters are defined here
      def hanlon_uri
        "http://#{hanlon_server}:#{api_port}"
      end

      def websvc_root
        "#{base_path}/#{api_version}"
      end

      # Save the current configuration instance as YAML to disk.
      #
      def save_as_yaml(conf_file_path)
        begin
          #fd = IO.sysopen(filename, Fcntl::O_WRONLY|Fcntl::O_CREAT|Fcntl::O_EXCL, 0600)
          #IO.open(fd, 'wb') {|fh| fh.puts ConfigHeader, YAML.dump(self) }

          if !File.file?(conf_file_path)

            FileUtils.mkdir_p(File.dirname(conf_file_path))
            File.open(conf_file_path, 'w') { |file| file.puts ConfigHeader, YAML.dump(self) }

          end
        rescue Exception => e
          puts "Could not save config to (#{conf_file_path})"
          puts e.backtrace
          #logger.error "Could not save config to (#{conf_file_path})"
          #logger.log_exception e
        end

        return self
      end

      # a few convenience methods that let us treat this class like a Hash map
      # (to a certain extent); first a "setter" method that lets users set
      # key/value pairs using a syntax like "config['param_name'] = param_value"
      def []=(key, val)
        # "@noun" is a "read-only" key for this class (there is no setter)
        return if key == "noun"
        self.send("#{key}=", val)
      end

      # next a "getter" method that lets a user get the value for a key using
      # a syntax like "config['param_name']"
      def [](key)
        self.send(key)
      end

      # next, a method that returns a list of the "key" fields from this class
      #     Note; in this method we are removing the "mk_fact_excl_pattern" key
      #       (if it exists) from the list of keys we return for this configuration.
      #       This is because we have removed this field from the "hanlon_server.conf"
      #       file, but have no way to force it's removal from any pre-existing
      #       "hanlon_server.conf" files (the content in the file overrides any
      #       content defined in the code).
      def keys
        self.to_hash.keys.map { |k| k.sub("@","") } - ["mk_fact_excl_pattern"]
      end

      # and, finally, a method that gives users the ability to check and see
      # if a given parameter name is included in the list of "key" fields for
      # this class
      def include?(key)
        keys = self.to_hash.keys.map { |k| k.sub("@","") }
        keys.include?(key)
      end

      # returns the current "client configuration" parameters as a Hash map
      def get_client_config_hash
        config_hash = self.to_hash
        client_config_hash = {}
        config_hash.each_pair do
        |k,v|
          if k.start_with?("@mk_")
            client_config_hash[k.sub("@","")] = v
          end
        end

        if self.is_a? ProjectHanlon::Config::Server
          # if this is a server config, then add in the 'mk_fact_excl_pattern',
          # which is embedded in the code on purpose (this will also override
          # any definitions of this parameter in existing 'hanlon_server.conf'
          # files; we do his on purpose because, in hindsight, we've come to
          # realize that this parameter really isn't something that the user
          # should be modifying)
          client_config_hash["mk_fact_excl_pattern"] = self.mk_fact_excl_pattern
        end

        client_config_hash
      end

      # override the standard "to_yaml" method so that these configurations
      # are saved in a sorted order (sorted by key)
      def to_yaml (opts = { })
        YAML::quick_emit(object_id, opts) do |out|
          out.map(taguri, to_yaml_style) do |map|
            sorted_keys = keys
            sorted_keys = begin
              sorted_keys.sort
            rescue
              sorted_keys.sort_by { |k| k.to_s } rescue sorted_keys
            end

            map.add("noun", self["noun"])
            sorted_keys.each do |k|
              next if k == "taguri" || k == "to_yaml_style"  || k == "noun"
              map.add(k, self[k])
            end

          end
        end
      end

      # uses the  UDPSocket class to determine the list of IP addresses that are
      # valid for this server (used in the "get_an_ip" method, below, to pick an IP
      # address to use when constructing the Hanlon configuration file)
      def local_ip
        # Base on answer from http://stackoverflow.com/questions/42566/getting-the-hostname-or-ip-in-ruby-on-rails
        orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

        UDPSocket.open do |s|
          s.connect '4.2.2.1', 1 # as this is UDP, no connection will actually be made
          s.addr.select {|ip| ip =~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/}.uniq
        end
      ensure
        Socket.do_not_reverse_lookup = orig
      end

      # This method is used to guess at an appropriate value to use as an IP address
      # for the Hanlon server when constructing the Hanlon configuration file.  It returns
      # a single IP address from the set of IP addresses that are detected by the "local_ip"
      # method (above).  If no IP addresses are returned by the "local_ip" method, then
      # this method returns a default value of 127.0.0.1 (a localhost IP address) instead.
      def get_an_ip
        str_address = local_ip.first
        # if no address found, return a localhost IP address as a default value
        return '127.0.0.1' unless str_address
        # if we're using a version of Ruby other than v1.8.x, force encoding to be UTF-8
        # (to avoid an issue with how these values are saved in the configuration
        # file as YAML that occurs after Ruby 1.8.x)
        return str_address.force_encoding("UTF-8") unless /^1\.8\.\d+/.match(RUBY_VERSION)
        # if we're using Ruby v1.8.x, just return the string
        str_address
      end
    end
  end
end
