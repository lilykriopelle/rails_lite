require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'
require 'byebug'

class HashWithIndifferentAccess
  def initialize(hash = {})
    @hash = {}
    hash.each do |k,v|
      @hash[k.to_s] = v
    end
  end

  def [](key)
    @hash[key.to_s]
  end

  def []=(key, val)
    @hash[key.to_s] = val
  end

  def to_json
    @hash.to_json
  end
end

class ControllerBase
  @@forgery_protection = {}
  @@before_actions = Hash.new { |h,k| h[k] = [] }
  @@before_actions_excepts = Hash.new { |h,k| h[k] = [] }

  attr_reader :req, :res, :params

  def self.protect_from_forgery(options)
    @@forgery_protection = options
  end

  def self.before_action(method, options)
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

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = HashWithIndifferentAccess.new(route_params.merge(req.params))
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    check_for_double_render
    res["Location"] = url
    res.status = 302
    session.store_session(res)
    flash.store_flash(res)
  end

  def render(template_name)
    template_path = File.join(
      File.dirname(__FILE__),
      "..",
      "views",
      self.class.name.underscore,
      "#{template_name}.html.erb"
    )
    template = ERB.new(File.read(template_path))
    render_content(template.result(binding), "text/html")
  end

  def render_content(content, content_type)
    check_for_double_render
    res["Content-Type"] = content_type
    res.write(content)
    session.store_session(res)
    flash.store_flash(res)
  end

  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  def form_authenticity_token
    token = SecureRandom::urlsafe_base64
    flash[:csrf_tokens] ||= []
    flash[:csrf_tokens] << token
    token
  end

  def invoke_action(name)
    check_csrf(name)
    run_before_actions(name)
    send(name)
    render(name) unless already_built_response?
  end

  private
    def check_for_double_render
      raise "Double render/redirect" if already_built_response?
      @already_built_response = true
    end

    def run_before_actions(name)
      run_before_actions_for(name)
      run_before_actions_for(:_every, name)
    end

    def check_csrf(name)
      if @@forgery_protection[:with] == :exception
        if [:create, :update, :destroy].include?(name) && !valid_csrf_token_present?
          raise "Invalid authenticity token."
        end
      end
    end

    def run_before_actions_for(actions_for, excepts_for = actions_for)
      @@before_actions[actions_for].each do |method|
        unless @@before_actions_excepts[excepts_for].include?(method)
          send(method)
        end
      end
    end

    def valid_csrf_token_present?
      flash["csrf_tokens"] && flash["csrf_tokens"].include?(req.params["authenticity_token"])
    end
end
