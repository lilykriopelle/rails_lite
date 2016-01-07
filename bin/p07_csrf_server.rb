require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'

$cats = [
  { id: 1, name: "Curie" },
  { id: 2, name: "Markov" }
]

$statuses = [
  { id: 1, cat_id: 1, text: "Curie loves string!" },
  { id: 2, cat_id: 2, text: "Markov is mighty!" },
  { id: 3, cat_id: 1, text: "Curie is cool!" }
]

class StatusesController < ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:cat_id] == Integer(params['cat_id'])
    end

    render :index
  end
end

class Cat
  attr_accessor :name, :owner
end

class Cats2Controller < ControllerBase
  def index
    flash["random"] = "NOW AND LATER"
    flash.now["stuff"] = "now"
  end

  def new
    @cat = Cat.new()
  end

  def create
    render_content("created cat", "text/html")
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), Cats2Controller, :index
  post Regexp.new("^/cats$"), Cats2Controller, :create
  get Regexp.new("^/cats/new$"), Cats2Controller, :new
  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
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
