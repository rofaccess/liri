RSpec.describe Hash, '#sample' do
  it 'devuelve un elemento aleatorio del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(1)
  end

  it 'devuelve 2 elementos aleatorios del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample(2)
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(2)
  end
end