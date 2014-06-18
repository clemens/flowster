require 'flowster/registerable'

module Flowster
  class Precondition < RegisterableObject
  end

  class Preconditions
    include Registerable

    def pass?(workflowable, *args, &block)
      preconditions.all? do |precondition|
        precondition.passes?(workflowable, *args)
      end
    end
  end
end
