require "workout/version"
require "active_support/concern"
require "active_model/validations"

module Workout
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  class_methods do
    def steps
      @_steps ||= []
    end

    def step(name, &blk)
      define_method name, &blk
      self.steps << name
    end

    def work(&blk)
      define_method :work, &blk
      self.steps.replace([:work])
    end
  end

  included do
    attr_accessor :current_step
    private :current_step=
    attr_reader :fsm
    validate :copy_failures_to_errors
  end

  def initialize(**opts)
    @_fsm = MicroMachine.new(:pending).tap do |fsm|
      fsm.when(:complete, :pending => :completed)
      fsm.when(:fail,     :pending => :failed)
    end
    @_failures = []
  end

  def complete?
    @_fsm.state == :completed
  end

  def complete
    @_fsm.trigger(:complete)
  end

  def complete!
    @_fsm.trigger!(:complete)
  end

  def fail(**args)
    should_throw = args.delete(:throw) != false
    @_failures.push({ step: current_step, args: args })
    @_fsm.trigger(:fail)
    validate
    throw :failure if should_throw
  end

  private def copy_failures_to_errors
    @_failures.each do |info|
      errors.add info[:step], info[:args]
    end
  end

  def success?
    complete? && valid?
  end

  private def rescuing(&blk)
    if defined?(ActiveRecord::ActiveRecordError)
      rescuing_with_active_record(&blk)
    else
      rescuing_without_active_record(&blk)
    end
  end

  private def rescuing_with_active_record(&blk)
    rescuing_without_active_record do
      blk.call
    end
  rescue ActiveRecord::ActiveRecordError => e
    fail({
      message: e.message,
      subject: e.record,
      exception: e,
      throw: false
    })
    self
  end

  private def rescuing_without_active_record(&blk)
    blk.call
    self
  rescue StandardError => e
    fail({
      message: e.message,
      subject: e,
      exception: e,
      throw: false
    })
    self
  end

  def call
    # don't even try if we are already invalid
    return self if invalid?

    rescuing do
      # run each step, possibly feeding the last result to the next
      self.class.steps.reduce(nil) do |last, name|
        self.current_step = name

        # #fail will throw :failure instead of raising
        result = catch :failure do
          if method(name).arity == 1
            send name, last
          else
            send name
          end
        end

        if invalid?
          break
        else
          result
        end
      end

      complete if valid?
    end
  ensure
    self.current_step = nil
  end
end
