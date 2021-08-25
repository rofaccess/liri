RSpec.describe Hash, '#sample' do
  it 'devuelve un elemento aleatorio del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(1)
    expect(hash.size).to eq(3)
  end

  it 'devuelve 2 elementos aleatorios del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample(2)
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(2)
    expect(hash.size).to eq(3)
  end

  it 'devuelve un elemento aleatorio del Hash y lo remueve del Hash' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample!
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(1)
    expect(hash.size).to eq(2)
  end

  it 'devuelve todos los elementos del Hash cuando se pide más elementos de los existentes' do
    hash = {}
    hash[1] = 'one'
    hash[2] = 'two'
    hash[3] = 'three'
    samples = hash.sample!(5)
    expect(samples).to be_a(Hash)
    expect(samples.size).to eq(3)
    expect(hash.size).to eq(0)
  end
end