require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'
require_relative './hash_with_indifferent_access'
require_relative './concerns/forgery_protection'
require_relative './concerns/before_actions'
require_relative './errors/double_render_error'

require 'byebug'

class ControllerBase
  include BeforeActions
  include ForgeryProtection

  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = HashWithIndifferentAccess.new(route_params.merge(req.params).merge(default_url_options))
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

  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  def already_built_response?
    @already_built_response
  end

  def render_content(content, content_type)
    check_for_double_render
    res["Content-Type"] = content_type
    res.write(content)
    session.store_session(res)
    flash.store_flash(res)
  end

  def invoke_action(name)
    check_csrf(name)
    run_before_actions(name)
    send(name)
    render(name) unless already_built_response?
  end

  private
    def check_for_double_render
      raise DoubleRenderError if already_built_response?
      @already_built_response = true
    end

    def default_url_options
      {}
    end
end
