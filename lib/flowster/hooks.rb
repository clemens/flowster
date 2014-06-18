require 'flowster/registerable'

module Flowster
  class Hook < RegisterableObject
  end

  class StateTransitionHook < Hook
    def execute(workflowable, *args)
      workflowable.state = @transition.target_state.name
    end
  end

  class Hooks
    include Registerable

    def run(workflowable, *args, &block)
      hooks.each do |hook|
        hook.execute(workflowable, *args, &block)
      end
    end

    register :transition_to_next_state, StateTransitionHook
  end
end
