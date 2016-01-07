class Flash

  attr_reader :req, :now

  def initialize(req)
    @req = req
    flash = req.cookies['_rails_lite_app_flash']
    @now = flash.nil? ? {} : JSON.parse(flash)
    @later = {}
  end

  def [](key)
    return now[key] if now[key]
    return @later[key] if @later[key]
    return nil
  end

  def []=(key, val)
    @later[key] = val
  end

  def store_flash(res)
    cookie = { path: '/', value: @later.to_json }
    res.set_cookie('_rails_lite_app_flash', cookie)
  end

end
