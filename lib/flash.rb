class HashWithIndifferentAccess
  def initialize(hash={})
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

class Flash

  attr_reader :req, :now

  def initialize(req)
    @req = req
    flash = req.cookies['_rails_lite_app_flash']
    if flash.nil?
      @now = HashWithIndifferentAccess.new
    else
      @now = HashWithIndifferentAccess.new(JSON.parse(flash))
    end
    @later = HashWithIndifferentAccess.new
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
