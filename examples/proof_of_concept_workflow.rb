require 'flowster'

class SetAttributesHook < Flowster::Hook
  def execute(workflowable, attributes = {})
    attributes.each do |key, value|
      workflowable.send("#{key}=", value)
    end
  end
end

# FIXME only one validation hook per transition? maybe separate subclass? maybe use throw/catch?
class ValidationHook < Flowster::Hook
  def execute(workflowable, *args)
    @options.each do |validation, configuration|
      send(:"validate_#{validation}", workflowable, configuration) or raise("validation error with #{validation} (#{configuration.inspect}) on #{workflowable.inspect}")
    end
  end

  def validate_required_fields(workflowable, fields)
    fields.all? do |field|
      value = workflowable.send(field)
      !(value.nil? || value.to_s.strip == '')
    end
  end

  def validate_field_values(workflowable, fields)
    true # FIXME
  end
end

class EmailHook < Flowster::Hook
  def execute(workflowable, *args)
    puts "Sending email with template #{@options[:template]} to #{@options[:to]} ..."
  end
end

class CreateAndAssignOrderNumberHook < Flowster::Hook
  def execute(workflowable, *args)
    workflowable.number = rand(1_000..9_999)
    puts "Assigning order number #{workflowable.number} to #{workflowable.inspect} ..."
  end
end

class SetCurrentTimeHook < Flowster::Hook
  def execute(workflowable, *args)
    # field = @options # FIXME
    field = :accepted_at
    workflowable.send(:"#{field}=", Time.now)
    puts "Setting #{field} of #{workflowable.inspect} to current time ..."
  end
end

Flowster::Hooks.register :set_attributes, SetAttributesHook
Flowster::Hooks.register :validation, ValidationHook
Flowster::Hooks.register :email, EmailHook
Flowster::Hooks.register :create_and_assign_order_number, CreateAndAssignOrderNumberHook
Flowster::Hooks.register :set_current_time, SetCurrentTimeHook

class FieldValuePrecondition < Flowster::Precondition
  def initialize(transition, field, options = {})
    super(transition, options)
    @field = 'user_name' # @field = field # FIXME
  end

  def passes?(workflowable, *args)
    if @options[:equals]
      workflowable.send(@field) == @options[:equals]
    elsif @options[:in]
      @options[:in].include?(workflowable.send(@field))
    end
  end
end

Flowster::Preconditions.register :field_value, FieldValuePrecondition

Flowster.define_workflow :proof_of_concept_1 do
  state :initial
  state :placed
  state :in_progress
  state :in_review
  state :done

  transition :place,    from: :initial,     to: :placed
  transition :pick,     from: :placed,      to: :in_progress
  transition :finish,   from: :in_progress, to: :in_review
  transition :accept,   from: :in_review,   to: :done
  transition :complete, from: :in_progress, to: :done

  # place
  preconditions :place do
    field_value '{{ current_user.role_identifier }}', in: %w[dealer superdealer]
  end

  after :place do
    transition_to_next_state
    create_and_assign_order_number
  end

  # pick
  preconditions :pick do
    field_value '{{ current_user.role_identifier }}', in: %w[dealer superdealer]
  end

  before :pick do
    set_attributes
    validation required_fields: [:car_model_id]
  end

  after :pick do
    transition_to_next_state
    email to: 'office@example.com', template: :order_processing_started
  end

  # finish
  preconditions :finish do
    field_value '{{ order.dealer_id }}', equals: '{{ current_user.dealer_id }}'
  end

  before :finish do
    set_attributes
    validation required_fields: [:finish_comment]
  end

  after :finish do
    transition_to_next_state
    email to: 'office@example.com', template: :order_finished
  end

  # accept
  preconditions :accept do
    field_value '{{ current_user.role_identifier }}', equals: 'backoffice'
  end

  before :accept do
    set_attributes
    validation required_fields: [:accepted], field_values: { accepted: { equals: true } }
  end

  after :accept do
    transition_to_next_state
    set_current_time '{{ order.accepted_at }}'
    email to: '{{ order.dealer_email }}', template: :order_accepted
  end

  # complete
  preconditions :complete do
    field_value '{{ current_user.role_identifier }}', equals: 'superdealer'
  end

  before :complete do
    set_attributes
  end

  after :complete do
    transition_to_next_state
    set_current_time '{{ order.completed_at }}'
    email to: 'office@example.com', template: :order_completed
  end
end

Flowster.define_workflow :proof_of_concept_2 do
  state :initial
  state :placed
  state :in_progress
  state :in_review
  state :done

  transition :place, from: :initial, to: :placed
  transition :pick, from: :placed, to: :in_progress
  transition :finish, from: :in_progress, to: :in_review
  transition :accept, from: :in_review, to: :done

  # place
  preconditions :place do
    field_value '{{ current_user.role_identifier }}', in: %w[dealer superdealer]
  end

  after :place do
    transition_to_next_state
    create_and_assign_order_number
  end

  # pick
  preconditions :pick do
    field_value '{{ current_user.role_identifier }}', in: %w[dealer superdealer]
  end

  before :pick do
    set_attributes
    validation required_fields: [:car_model_id]
  end

  after :pick do
    transition_to_next_state
    email to: 'office@example.com', template: :order_processing_started
  end

  # finish
  preconditions :finish do
    field_value '{{ order.dealer_id }}', equals: '{{ current_user.dealer_id }}'
  end

  before :finish do
    set_attributes
    validation required_fields: [:finish_comment]
  end

  after :finish do
    transition_to_next_state
    email to: 'office@example.com', template: :order_finished
  end

  # accept
  preconditions :accept do
    field_value '{{ current_user.role_identifier }}', equals: 'backoffice'
  end

  before :accept do
    set_attributes
    validation required_fields: [:accepted], field_values: { accepted: { equals: true } }
  end

  after :accept do
    transition_to_next_state
    set_current_time '{{ order.accepted_at }}'
    email to: '{{ order.dealer_email }}', template: :order_accepted
  end
end

class Company
  attr_reader :workflow_name

  def initialize(workflow_name)
    @workflow_name = workflow_name
  end
end

class Order
  include Flowster::Workflowable

  def initialize(id)
    @id = id
    @state = :initial
  end

  def inspect
    "Order(id: #{@id})"
  end

  attr_accessor :number, :car_model_id, :accepted, :accepted_at
  attr_accessor :finish_comment, :accept_comment, :complete_comment
end

company_1 = Company.new(:proof_of_concept_1)
company_2 = Company.new(:proof_of_concept_2)

order_company_1 = Order.new(1)
order_company_1.with_workflow(company_1.workflow_name) do |order|
  puts "Order #1 ..."
  puts "State: #{order.state}"
  order.place
  puts "State: #{order.state}"
  order.pick(car_model_id: 1)
  order.finish(finish_comment: "Is done, mate!")
  order.accept(accepted: false, accept_comment: "Well done, Mr.!")
  # order.complete(complete_comment: "Is done, no need to accept!")
end

puts '------------------------------------------------------'

order_company_2 = Order.new(2)
order_company_2.with_workflow(company_2.workflow_name) do |order|
  puts "Order #2 ..."
  puts "State: #{order.state}"
  order.place
  puts "State: #{order.state}"
  order.pick(car_model_id: 1)
  order.finish(finish_comment: "Is done, mate!")
  order.accept(accepted: true, accept_comment: "Well done, Mr.!")
  # order.complete(complete_comment: "Is done, no need to accept!")
end
