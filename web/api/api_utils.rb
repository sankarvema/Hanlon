#

require 'json'
require 'socket'
require 'ipaddr'

module Hanlon
  module WebService
    module Utils

      def request_from_hanlon_subnet?(remote_addr)
        # First, retrieve the list of subnets defined in the Hanlon server
        # configuration (this array is represented by a comma-separated string
        # containing the individual subnets managed by the Hanlon server)
        hanlon_subnets = ProjectHanlon.config.hanlon_subnets.split(',')
        # then, test the subnet value for each interface to see if the subnet for
        # that interface includes the remote_addr IP address; return true if any
        # of the interfaces define a subnet that includes that IP address, false
        # if none of them do
        hanlon_subnets.map { |subnet_str|
          # construct a new IPAddr object from each of the subnet strings retrieved
          # from the Hanlon server configuration, then test to see if our remote_addr
          # is in that subnet (if so, map to true, otherwise map to false)
          internal = IPAddr.new(subnet_str)
          internal.include?(remote_addr) ? true : false
        }.include?(true)
      end
      module_function :request_from_hanlon_subnet?

      def request_from_hanlon_server?(remote_addr)
        Socket.ip_address_list.map{|val| val.ip_address}.include?(remote_addr)
      end
      module_function :request_from_hanlon_server?

      # Checks to make sure an parameter is a format that supports a noun (uuid, etc))
      def validate_parameter(*param)
        param.each do |a|
          return false unless a && (a.to_s =~ /^\{.*\}$/) == nil && a != '' && a != {}
        end
      end
      module_function :validate_parameter

      # gets a reference to the ProjectHanlon::Data instance (and checks to make sure it
      # is working before returning the result)
      def get_data
        data = ProjectHanlon::Data.instance
        data.check_init
        data
      end
      module_function :get_data

      # used to construct a response to a RESTful request that is similar to the "slice_success"
      # response used previously by Hanlon
      def hnl_slice_success_response(slice, command, response, options = {})
        mk_response = options[:mk_response] ? options[:mk_response] : false
        type = options[:success_type] ? options[:success_type] : :generic
        # Slice Success types
        # Created, Updated, Removed, Retrieved. Generic
        return_hash = {}
        return_hash["resource"] = slice.class.to_s
        return_hash["command"] = command.to_s
        return_hash["result"] = slice.success_types[type][:message]
        return_hash["http_err_code"] = slice.success_types[type][:http_code]
        return_hash["errcode"] = 0
        return_hash["response"] = response
        return_hash["client_config"] = ProjectHanlon.config.get_client_config_hash if mk_response
        return_hash
      end
      module_function :hnl_slice_success_response

      # a method similar hnl_slice_success_response method (above) that properly returns
      # a Hanlon object (or array of Hanlon objects) as part of the response
      def hnl_slice_success_object(slice, command, hnl_object, options = { })
        if hnl_object.respond_to?(:collect)
          # if here, it's a collection
          if slice.uri_root
            # if here, then we can reduce the details down and just show a URI to access
            # each element of the collection
            hnl_object = hnl_object.collect do |element|
              elem_hash = element.to_hash
              if element.respond_to?("is_template") && element.is_template
                key_field = ""
                additional_uri_str = ""
                if slice.class.to_s == 'ProjectHanlon::Slice::Broker'
                  key_field = "@plugin"
                  additional_uri_str = "plugins"
                elsif slice.class.to_s == 'ProjectHanlon::Slice::Model'
                  key_field = "@name"
                  additional_uri_str = "templates"
                elsif slice.class.to_s == 'ProjectHanlon::Slice::Policy'
                  key_field = "@template"
                  additional_uri_str = "templates"
                end
                # filter down to just the #{key_field}, @classname, and @noun fields and add a URI
                # (based on the name fo the template) to the element we're returning that can
                # be used to access the details for that element
                test_array = [key_field, "@classname", "@noun"]
                elem_hash = Hash[elem_hash.reject { |k, v| !test_array.include?(k) }]
                slice.add_uri_to_object_hash(elem_hash, key_field, additional_uri_str)
              else
                # filter down to just the @uuid, @classname, and @noun fields and add a URI
                # to the element we're returning that can be used to access the details for
                # that element
                temp_fields = %w(@uuid @classname @noun) + class_from_string(slice.class.to_s).additional_fields
                elem_hash = Hash[elem_hash.reject { |k, v| !temp_fields.include?(k) }]
                slice.add_uri_to_object_hash(elem_hash)
              end
              elem_hash
            end
          else
            # if here, then there is no way to reference each element using
            # a URI, so show the full details for each
            hnl_object = hnl_object.collect { |element| element.to_hash }
          end
        else
          # if here, then we're dealing with a single object, not a collection
          # so show the full details
          hnl_object = hnl_object.to_hash
        end
        hnl_slice_success_response(slice, command, hnl_object, options)
      end
      module_function :hnl_slice_success_object

    end
  end
end
