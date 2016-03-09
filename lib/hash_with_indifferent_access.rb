class HashWithIndifferentAccess
  def initialize(hash = {})
    @hash = hash
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

  def inspect
    @hash.inspect
  end
end
