test_name "RSpec based integration tests"
on hosts('occam-server'), "cd /opt/occam && rspec -I acceptance-spec -fd -c acceptance-spec"
