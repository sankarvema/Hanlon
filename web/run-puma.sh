#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))

require './application'
require 'yaml'
require 'open3'

hanlon_config = YAML::load(File.open('config/hanlon_server.conf'))

cmd_str="puma -p #{hanlon_config['api_port']} 2>&1 | tee /tmp/puma.log"
puts "running #{cmd_str}..."
trap("SIGINT") { throw :ctrl_c }
catch :ctrl_c do
  begin
    Open3.popen3(cmd_str) { |stdin, stdout, stderr, wait_thr|
      while line = stdout.gets
        puts line
      end
    }
  rescue Exception
  end
end