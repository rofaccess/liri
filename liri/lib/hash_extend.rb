class Hash
  def sample
    sample_key = self.keys.sample
    [sample_key, self[sample_key]]
  end
end