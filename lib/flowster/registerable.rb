module Flowster
  class RegisterableObject
    def initialize(transition, options = {})
      @transition = transition
      @options = options
    end
  end

  module Registerable
    def self.included(base)
      base.extend(ClassMethods)

      class << base; attr_reader :registry; end

      define_method(base.name.downcase.split('::').last) { @registered_objects }
    end

    module ClassMethods
      def register(name, object)
        (@registry ||= {})[name] = object
      end
    end

    def initialize(transition, &block)
      @transition = transition
      @registered_objects = []
      instance_eval(&block)
    end

    def respond_to_missing?(name, include_private = false)
      self.class.registry.key?(name) || super
    end

    def method_missing(name, *args, &block)
      registry = self.class.registry

      registry.key?(name) ? @registered_objects << registry[name].new(@transition, *args) : super
    end
  end
end
