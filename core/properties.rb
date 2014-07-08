require 'version'

module ProjectHanlon

  class Properties

    class << self;
      attr_accessor :app_name
      attr_accessor :app_build_version
      attr_accessor :app_copy_right
    end

    @app_name = "Project Hanlon"
    @app_build_version = ProjectHanlon::VERSION
    @app_copy_right = "#{ProjectHanlon::Properties.app_name} (c) 2014. All rights reserved."
  end

end