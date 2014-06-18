# Flowster

Workflow proof of concept

## Notes

Validations => ActiveModel?
Liquid for templates and stuff? alternative: take liquid drops as an inspiration

AND/OR preconditions? (could also do these in specific precondition subclasses)

some initial state handling

be more explicit about workflow:
  - order.order => order.workflow.order; order.ordered? => order.workflow.ordered?
  - order.order => order.transition(:order); order.ordered? => order.state?(:ordered)
or something like that

transition configuration in one step? => still want to keep objects in the main workflow object, though (not part of the transition object) => potential indirection?

transition :order, from: :initial, to: :ordered do
  preconditions do
    # ...
  end

  after do
    # ...
  end
end
