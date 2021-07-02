# = hash_extend.rb
#
# Autor::   Rodrigo Fernández
# Web::     http://www.something.com
#
# == Clase Hash
# Esta clase extiende las funcionalidades de la clase Hash de Ruby
class Hash
  # Retorna un hash con elementos aleatorios del hash original
  # === Parámetros
  # * +quantity+ - la cantidad de elementos del nuevo hash retornado, por defecto es 1
  # ==== Ejemplos
  #   hash = {uno: 'uno', dos: 'dos', tres: 'tres'}
  #   hash.sample
  #     => {dos: 'dos'}
  #   hash.sample(2)
  #     => {uno: 'uno', tres: 'tres'}
  def sample(quantity=1)
    sample_keys = self.keys.sample(quantity)
    sample_values = {}
    sample_keys.each do |sample_key|
      sample_values[sample_key] = self[sample_key]
    end
    sample_values
  end

  # Borra los elementos indicados del hash y retorna el hash sin los elementos indicados
  # === Parámetros
  # * +keys+ - las claves a remover separadas por comas
  # ==== Ejemplos
  #   hash = {uno: 'uno', dos: 'dos', tres: 'tres'}
  #   hash.remove!(:uno)
  #     => {:dos=>"dos", :tres=>"tres"}
  #   hash.remove!(:uno, :dos, :tres)
  #     => {}
  #   hash
  #     => {}
  def remove!(*keys)
    keys.each{|key| self.delete(key) }
    self
  end
end