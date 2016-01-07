class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  def matches?(req)
    path_matches(req) && method_matches(req)
  end

  def run(req, res)
    match_data = pattern.match(req.path)
    route_params = {}

    match_data.names.each do |name|
      route_params[name] = match_data[name]
    end

    controller = controller_class.new(req, res, route_params)
    controller.invoke_action(action_name)
  end

  def path_matches(req)
    !(pattern =~ req.path).nil?
  end

  def method_matches(req)
    (http_method.to_s == req.request_method.downcase)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  def add_route(pattern, method, controller_class, action_name)
    routes << Route.new(pattern, method, controller_class, action_name)
  end

  def draw(&proc)
    instance_eval(&proc)
  end

  [:get, :post, :put, :patch, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  def resources(resource)
    controller = "#{resource.to_s.capitalize}Controller".constantize
    get Regexp.new("^/#{resource}$"), controller, :index
    get Regexp.new("^/#{resource}/new$"), controller, :new
    post Regexp.new("^/#{resource}$"), controller, :create
    get Regexp.new("^/#{resource}/(?<cat_id>\\d+)$"), controller, :show
    get Regexp.new("^/#{resource}/(?<cat_id>\\d+)/edit$"), controller, :edit
    put Regexp.new("^/#{resource}/(?<cat_id>\\d+)$"), controller, :update
    patch Regexp.new("^/#{resource}/(?<cat_id>\\d+)$"), controller, :update
    delete Regexp.new("^/#{resource}/(?<cat_id>\\d+)$"), controller, :destroy
  end

  def match(req)
    routes.each do |route|
      return route if route.matches?(req)
    end
    nil
  end

  def run(req, res)
    match = match(req)
    if match
      match.run(req,res)
    else
      res.status = 404
    end
  end
end
