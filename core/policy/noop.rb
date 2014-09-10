# ProjectHanlon Policy Base class
# Root abstract
require 'policy/base'

module ProjectHanlon
  module PolicyTemplate
    class Noop < ProjectHanlon::PolicyTemplate::Base
      include(ProjectHanlon::Logging)

      # @param hash [Hash]
      def initialize(hash)
        super(hash)
        @hidden = false
        @template = :noop
        @description = "Policy used for discovery of existing nodes."

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
