module Flowster
  module Workflowable
    def self.included(base)
      base.send(:attr_accessor, :state)
    end

    def with_workflow(name)
      begin
        @workflow = Flowster.workflows[name]
        yield self
      ensure
        @workflow = nil
      end
    end

    # FIXME I'd rather not proxy everything to the workflow object all the time
    def method_missing(name, *args, &block)
      return super unless @workflow.respond_to?(name)

      @workflow.send(name, *([self] + args), &block)
    end
  end
end
