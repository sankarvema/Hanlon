#!/usr/bin/sh ruby
$LOAD_PATH << "/root/Hanlon/lib"
require "project_hanlon"



@data = ProjectHanlon::Data.instance
@data.check_init
engine = ProjectHanlon::Engine.instance

@data.delete_all_objects(:node)
p @data.fetch_all_objects(:node)

node = ProjectHanlon::Node.new({})
node.hw_id << "12345"
node.hw_id << "67890"
new_node = engine.register_new_node_with_hw_id(node)
puts "#{new_node.uuid} #{new_node.hw_id}"


find_node = engine.lookup_node_by_hw_id(:hw_id => ["12345"])
puts "#{find_node.uuid} #{find_node.hw_id}"

find_node = engine.lookup_node_by_hw_id(:hw_id => ["12345","67890"])
puts "#{find_node.uuid} #{find_node.hw_id}"

node = ProjectHanlon::Node.new({})
node.hw_id << "ABC"
node.hw_id << "CDE"
new_node = engine.register_new_node_with_hw_id(node)
puts "#{new_node.uuid} #{new_node.hw_id}"


@data.delete_all_objects(:node)
p @data.fetch_all_objects(:node)

