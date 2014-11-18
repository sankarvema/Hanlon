# Root namespace for ProjectHanlon
module ProjectHanlon
  module BrokerPlugin

    # Root namespace for Brokers defined in ProjectHanlon for node hand off
    # @abstract
    class Base < ProjectHanlon::Object
      attr_accessor :name
      attr_accessor :plugin
      attr_accessor :description
      attr_accessor :user_description
      attr_accessor :hidden
      attr_accessor :req_metadata_hash

      def initialize(hash)
        super()
        @hidden = true
        @plugin = :base
        @noun = "broker"
        @description = "Base broker plugin - not used"
        @_namespace = :broker
        from_hash(hash) if hash
      end

      def template
        @plugin
      end


      def agent_hand_off(options = {})

      end

      def proxy_hand_off(options = {})

      end

      # Method call for validating that a Broker instance successfully received the node
      def validate_broker_hand_off(options = {})
        # return false because the Base object does nothing
        # Child objects do not need to call super
        false
      end

      def print_header
        if @is_template
          return "Plugin", "Description"
        else
          return "Name", "Description", "Plugin", "UUID"
        end
      end

      def print_items
        if @is_template
          return @plugin.to_s, @description.to_s
        else
          return @name, @user_description, @plugin.to_s, @uuid
        end
      end

      def line_color
        :white_on_black
      end

      def header_color
        :red_on_black
      end

      def yaml_read_metadata(yaml_metadata_hash)
        req_metadata_params = {}
        # set instance variables for the required values in the input yaml_metadata_hash
        req_meta_vals = yaml_metadata_hash.select{ |key| req_metadata_hash.keys.include?("@#{key}") }
        req_meta_vals.each { |key, value|
          broker_key = "@#{key}"
          flag = set_metadata_value(broker_key, value)
          if !flag
            raise ProjectHanlon::Error::Slice::InvalidBrokerMetadata, "Invalid Metadata [#{key}:#{value}]"
          end
          req_metadata_params[key] = value
        }
        [(req_metadata_hash.keys - yaml_metadata_hash.keys.map { |key| "@#{key}" } ), req_metadata_params]
      end

      def cli_get_metadata_params(yaml_metadata_hash = {})
        puts "--- Building Broker (#{plugin}): #{name}\n".yellow
        # will return a list of the fields from the req_metadata_hash that were
        # not provided in the input yaml_metadata_hash map
        remaining_keys, req_metadata_params = yaml_read_metadata(yaml_metadata_hash)
        #req_metadata_hash.each { |key, metadata|
        remaining_keys.each { |broker_key|
          params_key = broker_key[1..-1]
          metadata = req_metadata_hash[broker_key]
          metadata = map_keys_to_symbols(metadata)
          flag = false
          val = nil
          until flag
            print "Please enter " + "#{metadata[:description]}".yellow.bold
            print " (example: " + "#{metadata[:example]}".yellow + ") \n"
            puts "default: " + "#{metadata[:default]}".yellow if metadata[:default] != ""
            puts metadata[:required] ? quit_option : skip_quit_option
            print " > "
            response = read_input(metadata[:multiline])
            uc_response = response.upcase
            case uc_response
              when 'SKIP'
                if metadata[:required]
                  puts "Cannot skip, value required".red
                else
                  flag = true
                end
              when 'QUIT'
                puts "#{uc_response} == 'QUIT'? #{uc_response == 'QUIT'}"
                return nil
              when ""
                # if a default value is defined for this parameter (i.e. the metadata[:default]
                # value is non-nil) then use that value as the value for this parameter
                if metadata[:default]
                  flag = validate_metadata_value(metadata[:default], metadata[:validation])
                  val = metadata[:default] if flag
                else
                  puts "No default value, must enter something".red
                end
              else
                flag = validate_metadata_value(response, metadata[:validation])
                puts "Value (".red + "#{response}".yellow + ") is invalid".red unless flag
                val = response if flag
            end
          end
          req_metadata_params[params_key] = val
        }
        req_metadata_params
      end

      def read_input(multiline = false)
        if multiline
          response = ""
          while line = STDIN.gets
            if line =~ /^$/
              break
            else
              response += line
            end
          end
          response
        else
          STDIN.gets.strip
        end
      end

      def map_keys_to_symbols(hash)
        tmp = {}
        hash.each { |key, val|
          key = key.to_sym if !key.is_a?(Symbol)
          tmp[key] = val
        }
        tmp
      end

      def set_metadata_value(key, value)
        md_hash_value = map_keys_to_symbols(req_metadata_hash[key])
        is_required_field = md_hash_value[:required]
        # skip any empty/nil values that aren't required (i.e. continue only if it's a required field or the field
        # is not required but the value is not empty/nil)
        return true unless is_required_field || value
        # otherwise, validate the value and, if is valid, set a corresponding
        # instance variable
        regex = Regexp.new(md_hash_value[:validation])
        if regex =~ value
          self.instance_variable_set(key.to_sym, value)
          true
        else
          false
        end
      end

      def set_default_metadata_value(key)
        md_hash_value = map_keys_to_symbols(req_metadata_hash[key])
        validation_str = md_hash_value[:validation]
        def_value = md_hash_value[:default]
        regex = Regexp.new(validation_str) if validation_str && !validation_str.empty?
        def_is_valid = regex ? regex.match(def_value) : true
        if (md_hash_value[:required] && def_value && def_is_valid)
          self.instance_variable_set(key.to_sym, def_value)
          true
        elsif !md_hash_value[:required]
          true
        else
          false
        end
      end

      def validate_metadata_value(value, validation)
        regex = Regexp.new(validation)
        if regex =~ value
          true
        else
          false
        end
      end

      def skip_quit_option
        "(" + "SKIP".white + " to skip, " + "QUIT".red + " to cancel)"
      end

      def quit_option
        "(" + "QUIT".red + " to cancel)"
      end
    end
  end
end
