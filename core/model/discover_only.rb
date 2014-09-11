# Root ProjectHanlon namespace
module ProjectHanlon
  module ModelTemplate
    # Root Model object
    # @abstract
    class DiscoverOnly < ProjectHanlon::ModelTemplate::Base
      include(ProjectHanlon::Logging)

      attr_reader :image_prefix

      def initialize(hash)
        super(hash)
        # Static config
        @hidden = false
        @template = :discover_only
        @name = "discover_only"
        @description = "Noop model to discover new nodes"
        # there is no image associated with this type of model
        @image_prefix = nil
        # State / must have a starting state
        @current_state = :init
        @final_state = :os_complete
        from_hash(hash) unless hash == nil
      end

      # Defines our FSM for this model
      #  For state => {action => state, ..}
      def fsm_tree
        {
            :init => {
                :mk_call       => :init,
                :boot_call     => :init,
                :timeout       => :timeout_error,
                :error         => :error_catch,
                :else          => :init
            },
            :timeout_error => {
                :mk_call   => :timeout_error,
                :boot_call => :timeout_error,
                :else      => :timeout_error,
                :reset     => :init
            },
            :error_catch => {
                :mk_call   => :error_catch,
                :boot_call => :error_catch,
                :else      => :error_catch,
                :reset     => :init
            },
        }
      end

      def mk_call(node, policy_uuid)
        super(node, policy_uuid)
        case @current_state
          # We need to poweroff
          when :init
            ret = [:poweroff, {}]
          when :timeout_error, :error_catch
            ret = [:acknowledge, {}]
          else
            ret = [:acknowledge, {}]
        end
        fsm_action(:mk_call, :mk_call)
        ret
      end

      def boot_call(node, policy_uuid)
        super(node, policy_uuid)
        # always boot into the Microkernel
        engine = ProjectHanlon::Engine.instance
        ret = engine.default_mk_boot(node.uuid)
        fsm_action(:boot_call, :boot_call)
        ret
      end

      def print_item
        if @is_template
          return @name.to_s, @description.to_s
        else
          image_uuid_str = "n/a"
          return @label, @template.to_s, @description, @uuid, image_uuid_str
        end
      end

    end
  end
end
