module Flowster
  class Transition
    attr_reader :name, :current_state, :target_state

    def initialize(name, from_state: nil, to_state: nil)
      @name = name
      @current_state = from_state
      @target_state = to_state
    end

    def perform(workflowable, *args)
      # TODO this could be the first preconditions ... plus not sure if it should raise
      # puts "Performing transition #{name} for #{workflowable.inspect} (args: #{args.inspect}) ..."
      raise("transition #{name} from #{current_state.name} to #{target_state.name} not possible for #{workflowable.inspect}") unless workflowable.send(:"#{current_state.name}?")
    end
  end
end
