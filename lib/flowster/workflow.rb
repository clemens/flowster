require 'flowster/state'
require 'flowster/transition'
require 'flowster/preconditions'
require 'flowster/hooks'

module Flowster
  class Workflow
    def initialize(name, &workflow_definition)
      @name = name

      @states = {}
      @transitions = {}
      @preconditions = {}
      @hooks = { before: {}, after: {} }

      instance_eval(&workflow_definition)
    end

    def state(name)
      @states[name] = State.new(name)
    end

    def state_query?(name)
      name =~ /\A(?<name>\w+)\?\z/ && @states[$~[:name].to_sym]
    end

    def in_state?(workflowable, state)
      workflowable.state == state.name
    end

    def transition(name, from: nil, to: nil)
      current_state = @states[from]
      target_state = @states[to == :self ? from : to]

      @transitions[name] = Transition.new(name, from_state: current_state, to_state: target_state)
    end

    def possible_transitions_for(workflowable)
      @transitions.values.select do |transition|
        transition.current_state.name == workflowable.state &&
        (
          (preconditions = @preconditions[transition.name]).nil? ||
          preconditions.pass?(workflowable)
        )
      end
    end
    alias_method :possible_transitions, :possible_transitions_for

    def has_transition?(name)
      @transitions.key?(name)
    end

    def can_transition?(workflowable, transition_name)
      possible_transitions_for(workflowable).map(&:name).include?(transition_name)
    end

    def perform_transition(workflowable, transition_name, *args, &block)
      if before_hooks = @hooks[:before][transition_name]
        before_hooks.run(workflowable, *args, &block)
      end

      @transitions[transition_name].perform(workflowable, *args)

      if after_hooks = @hooks[:after][transition_name]
        after_hooks.run(workflowable, *args, &block)
      end
    end

    def preconditions(transition_name, &preconditions)
      @preconditions[transition_name] = Preconditions.new(@transitions[transition_name], &preconditions)
    end

    def add_hooks(type, transition_name, &actions)
      @hooks[type][transition_name] = Hooks.new(@transitions[transition_name], &actions)
    end

    def before(transition_name, &actions)
      add_hooks(:before, transition_name, &actions)
    end

    def after(transition_name, &actions)
      add_hooks(:after, transition_name, &actions)
    end

    def respond_to_missing?(name, include_private = false)
      has_transition?(name) || state_query?(name) || super
    end

    def method_missing(name, *args, &block)
      if has_transition?(name)
        perform_transition(args.shift, name, *args, &block)
      elsif state = state_query?(name)
        in_state?(args.first, state)
      else
        super
      end
    end
  end
end
