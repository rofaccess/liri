class Hash
  def sample(quantity=1)
    sample_keys = self.keys.sample(quantity)
    sample_values = {}
    sample_keys.each do |sample_key|
      sample_values[sample_key] = self[sample_key]
    end
    sample_values
  end
end