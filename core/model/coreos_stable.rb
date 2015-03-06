module ProjectHanlon
  module ModelTemplate

    class CoreosStable < Coreos
      include(ProjectHanlon::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden      = false
        @name        = "coreos_stable"
        @description = "coreos stable"
        @osversion   = "557"

        from_hash(hash) unless hash == nil
      end
    end
  end
end
