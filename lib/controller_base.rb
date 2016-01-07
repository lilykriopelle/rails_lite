require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise "Double render/redirect" if already_built_response?
    res["Location"] = url
    res.status = 302
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  def render_content(content, content_type)
    raise "Double render/redirect" if already_built_response?
    res["Content-Type"] = content_type
    res.write(content)
    @already_built_response = true
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

  # method exposing a `Session` object
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
    if [:create, :update, :destroy].include?(name)
      unless flash["csrf_tokens"].include? (req.params["authenticity_token"])
        raise "Invalid authenticity token."
      end
    end
    send(name)
    render(name) unless already_built_response?
  end
end