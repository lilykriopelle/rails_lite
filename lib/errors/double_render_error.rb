class DoubleRenderError < StandardError
  def message
    "Render or redirect were called multiple times in a single action."
  end
end
