# this file defines the list of classes to be loaded under error
# this is dependency ordering is required for the code to run under compiled model of class loading under jruby
# here all the load files are maintained in the order of dependency
#
# This can be replace if we find a more meaningful method of loading classes

# level 1
require 'error/generic'
require 'error/slice/generic'

require 'error/error_factory'
require 'error/slice'

# level 2

