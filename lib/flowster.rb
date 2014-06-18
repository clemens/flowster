module Flowster
  class << self
    attr_accessor :workflows

    def define_workflow(name, &workflow_definition)
      (self.workflows ||= {})[name] = Workflow.new(name, &workflow_definition)
    end
  end
end

require 'flowster/workflow'
require 'flowster/workflowable'
