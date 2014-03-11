# ProjectOccam Policy Base class
# Root abstract
module ProjectOccam
  module PolicyTemplate
    class XenServerHypervisor < ProjectOccam::PolicyTemplate::Base
      include(ProjectOccam::Logging)

      # @param hash [Hash]
      def initialize(hash)
        super(hash)
        @hidden = false
        @template = :xenserver_hypervisor
        @description = "Policy for deploying a XenServer hypervisor."

        from_hash(hash) unless hash == nil
      end


      def mk_call(node)
        model.mk_call(node, @uuid)
      end


      def boot_call(node)
        model.boot_call(node, @uuid)
      end

    end
  end
end

