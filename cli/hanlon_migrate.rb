#!/usr/bin/env ruby
#
# database migration tool to migrate from rajor to ProjectHanlon
#
#

# We first add our Lib path to the load path. This is for non-gem ease of use
require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../core').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../util').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname))

$app_root = Pathname(__FILE__).realpath.dirname.to_s
$hanlon_root = Pathname(__FILE__).parent.realpath.dirname.to_s
$app_type = "client"

require 'rubygems' if RUBY_VERSION < '1.9'

require 'db_migrate/main'

exit ProjectHanlon::Main.new.run(*ARGV)