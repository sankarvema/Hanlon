#!/usr/bin/env bash

if !(hash jruby 2>/dev/null); then
  echo "$0 must be run under jruby"
  exit -1
fi

# get the location of the script relative to the cwd
SCRIPT="${BASH_SOURCE[0]}"
# while the filename in $SCRIPT is a symlink
while [ -L "$SCRIPT" ]; do
  # similar to above, but -P forces a change to the physical,
  # not symbolic, directory
  DIR="$( cd -P "$( dirname "$SCRIPT" )" && pwd )"
  # value of symbolic link if $SCRIPT is relative (doesn't begin
  # with /), resolve relative path where symlink lives
  SCRIPT="$(readlink "$SCRIPT")" && SCRIPT="$DIR/$SCRIPT"
done
DIR="$( cd -P "$( dirname "$SCRIPT" )" && pwd )"

# now that we know where the script is located, change directories
# to that directory and start up the trinidad server on the correct port
# (based on the 'api_port' set in the hanlon_server.conf file)
cd ${DIR}
PORT=`awk '/api_port/ {print $2}' config/hanlon_server.conf`
trinidad --address 0.0.0.0 -p ${PORT} 2>&1 | tee /tmp/trinidad.log