#

require 'json'
require 'socket'
require 'facter'
require 'facter/util/ip'
require 'ipaddr'

module Razor
  module WebService
    module Utils

      def request_from_razor_subnet?(remote_addr)
        # First, retrieve a couple of parameters (the Razor server's IP address
        # and the array of interfaces on the local machine)
        razor_server_ip = ProjectRazor.config.to_hash["@mk_uri"].match(/\/\/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/)[1]
        interface_array = Facter::Util::IP.get_interfaces
        # then, test each interface to see if the subnet for that interface
        # includes the remote_addr IP address; return true if any of the interfaces
        # define a subnet that includes that IP address, false if none of them do
        interface_array.map { |val|
          ip_addr = Facter::Util::IP.get_interface_value(val,'ipaddress')
          # skip to next unless looking at loopback interface or IP address is the same as the razor_server_ip
          next unless val == "lo" || ip_addr == razor_server_ip
          netmask = Facter::Util::IP.get_interface_value(val,'netmask')
          # construct a new IPAddr object from the ip_addr and netmask we just
          # retrieved, then test to see if our remote_addr is in that same subnet
          # (if so, map to true, otherwise map to false)
          internal = IPAddr.new("#{ip_addr}/#{netmask}")
          internal.include?(remote_addr) ? true : false
        }.include?(true)
      end
      module_function :request_from_razor_subnet?

      def request_from_razor_server?(remote_addr)
        Socket.ip_address_list.map{|val| val.ip_address}.include?(remote_addr)
      end
      module_function :request_from_razor_server?

      # Checks to make sure an parameter is a format that supports a noun (uuid, etc))
      def validate_parameter(*param)
        param.each do |a|
          return false unless a && (a.to_s =~ /^\{.*\}$/) == nil && a != '' && a != {}
        end
      end
      module_function :validate_parameter

      # gets a reference to the ProjectRazor::Data instance (and checks to make sure it
      # is working before returning the result)
      def get_data
        data = ProjectRazor::Data.instance
        data.check_init
        data
      end
      module_function :get_data

      # used to construct a response to a RESTful request that is similar to the "slice_success"
      # response used previously by Razor
      def rz_slice_success_response(slice, command, response, options = {})
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
        return_hash["client_config"] = ProjectRazor.config.get_client_config_hash if mk_response
        return_hash
      end
      module_function :rz_slice_success_response

      # a method similar rz_slice_success_response method (above) that properly returns
      # a Razor object (or array of Razor objects) as part of the response
      def rz_slice_success_object(slice, command, rz_object, options = { })
        if rz_object.respond_to?(:collect)
          # if here, it's a collection
          if slice.uri_root
            # if here, then we can reduce the details down and just show a URI to access
            # each element of the collection
            rz_object = rz_object.collect do |element|
              elem_hash = element.to_hash
              unless element.respond_to?("is_template") && element.is_template
                # filter down to just the @uuid, @classname, and @noun fields and add a URI
                # to the element we're returning that can be used to access the details for
                # that element
                elem_hash = Hash[elem_hash.reject { |k, v| !%w(@uuid @classname, @noun).include?(k) }]
                slice.add_uri_to_object_hash(elem_hash)
              end
              elem_hash
            end
          else
            # if here, then there is no way to reference each element using
            # a URI, so show the full details for each
            rz_object = rz_object.collect { |element| element.to_hash }
          end
        else
          # if here, then we're dealing with a single object, not a collection
          # so show the full details
          rz_object = rz_object.to_hash
        end
        rz_slice_success_response(slice, command, rz_object, options)
      end
      module_function :rz_slice_success_object

    end
  end
end