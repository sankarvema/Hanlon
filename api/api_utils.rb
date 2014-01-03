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

    end
  end
end