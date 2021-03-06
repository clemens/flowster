module Flowster
  module Workflowable
    def self.included(base)
      base.send(:attr_accessor, :workflow)
    end

    def with_workflow(name)
      begin
        self.workflow = Flowster.workflows[name]
        yield self
      ensure
        self.workflow = nil
      end
    end

    def respond_to_missing?(name, include_private = false)
      workflow.respond_to?(name) || super
    end

    # FIXME I'd rather not proxy everything to the workflow object all the time
    def method_missing(name, *args, &block)
      return super unless workflow.respond_to?(name)

      workflow.send(name, *([self] + args), &block)
    end
  end
end
