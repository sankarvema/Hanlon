module ProjectHanlon
  module ModelTemplate

    class Redhat7 < Redhat
      include(ProjectHanlon::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden      = false
        @name        = "redhat_7"
        @description = "RedHat 7 Model"
        @osversion   = "7"

        from_hash(hash) unless hash == nil
      end
    end
  end
end
