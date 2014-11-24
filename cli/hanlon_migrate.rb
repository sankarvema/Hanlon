#!/usr/bin/env ruby
#
# database migration tool to migrate from rajor to ProjectHanlon
#
#

# We first add our Lib path to the load path. This is for non-gem ease of use

require 'pathname'
require 'colored'

$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../core').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname + '../util').cleanpath.to_s)
$LOAD_PATH.unshift((Pathname(__FILE__).realpath.dirname))

$app_root = Pathname(__FILE__).realpath.dirname.to_s
$hanlon_root = Pathname(__FILE__).parent.realpath.dirname.to_s
$app_type = "migrate"

require 'rubygems' if RUBY_VERSION < '1.9'

require 'config/migrate'
require 'migrate/global'

$config_file_path = "#{$app_root}/config/hanlon_#{$app_type}.conf"

if !File.exist? $config_file_path then
  migrate_config = ProjectHanlon::Config::Migrate.new
  #puts migrate_config.inspect
  migrate_config.save_as_yaml($config_file_path)

  puts "Migration config file missing at #{$config_file_path}".red
  puts " Default config file generated".white
  puts "   Please re-run hanlon migration tool after editing the configuration file".white
  return ProjectHanlon::Migrate::ErrorCodes[:missing_config_file]
end

require 'migrate/migrate_main'

exit ProjectHanlon::MigrateMain.new.run(*ARGV)