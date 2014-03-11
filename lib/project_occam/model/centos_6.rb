module ProjectOccam
  module ModelTemplate

    class Centos6 < Redhat
      include(ProjectOccam::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden      = false
        @name        = "centos_6"
        @description = "CentOS 6 Model"
        @osversion   = "6"

        from_hash(hash) unless hash == nil
      end
    end
  end
end
