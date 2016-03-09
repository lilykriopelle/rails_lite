require 'active_support/concern'

module BeforeActions
  extend ActiveSupport::Concern

  @@before_actions = Hash.new { |h,k| h[k] = [] }
  @@before_actions_excepts = Hash.new { |h,k| h[k] = [] }

  class_methods do
    def before_action(method, options)
      if options == {}
        @@before_actions[:_every] << method
      else
        if options[:only]
          if options[:only].is_a? Array
            options[:only].each do |action|
              @@before_actions[action] << method
            end
          else
            @@before_actions[options[:only]] << method
          end
        end

        if options[:except]
          @@before_actions[:_every] << method
          if options[:except].is_a? Array
            options[:except].each do |action|
              @@before_actions_excepts[action] << method
            end
          else
            @@before_actions_excepts[options[:except]] << method
          end
        end
      end
    end
  end

  private
  def run_before_actions(name)
    run_before_actions_for(name)
    run_before_actions_for(:_every, name)
  end

  def run_before_actions_for(actions_for, excepts_for = actions_for)
    @@before_actions[actions_for].each do |method|
      unless @@before_actions_excepts[excepts_for].include?(method)
        send(method)
      end
    end
  end

end
