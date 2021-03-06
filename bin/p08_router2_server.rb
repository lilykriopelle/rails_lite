require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'

class CatsController < ControllerBase
  def index
    render_content("showing cats index", "application/json")
  end

  def create
    render_content("creating cat", "application/json")
  end

  def show
    render_content("showing cat #{params[:cat_id]}", "application/json")
  end

  def edit
    render_content("editing cat #{params[:cat_id]}", "application/json")
  end

  def new
    render_content("new cat", "application/json")
  end

  def update
    render_content("updating cat #{params[:cat_id]}", "application/json")
  end

  def destroy
    render_content("destroying cat #{params[:cat_id]}", "application/json")
  end
end

router = Router.new
router.draw do
  resources :cats
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
