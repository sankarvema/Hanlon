require "erb"

# Root ProjectHanlon namespace
module ProjectHanlon
  module ModelTemplate
    # Root Model object
    # @abstract
    class Windows2012R2 < Windows
      include(ProjectHanlon::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden = false
        @template = :windows_deploy
        @name = "windows_2012_r2"
        @description = "Windows 2012 R2"
        @osversion = 'windows_2012_r2'
        # Metadata vars
        from_hash(hash) unless hash == nil
       
      end
    end
  end
end
