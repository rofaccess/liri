# = hash_extend.rb
#
# @author Rodrigo Fernández
#
# == Clase Hash
# Esta clase extiende las funcionalidades de la clase Hash de Ruby
class Hash
  # Retorna un hash con elementos aleatorios del hash original.
  #
  # @param quantity [Integer] la cantidad de elementos del nuevo hash retornado.
  # @return [Hash] un hash con elementos aleatorios del hash original.
  # @example
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

  # Borra elementos del hash.
  # @note Los elementos son borrados del hash original
  # @param keys [Array] las claves a remover separadas por comas o en un arreglo.
  # @return [Hash] un hash sin los elementos indicados.
  # @example
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