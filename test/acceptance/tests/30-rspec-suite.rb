test_name "RSpec based integration tests"
on hosts('hanlon-server'), "cd /opt/hanlon && rspec -I acceptance-spec -fd -c acceptance-spec"
