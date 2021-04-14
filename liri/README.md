# Liri

Gema que permite la ejecución de pruebas unitarias de manera distribuida a find de aumentar la velocidad de ejecución.

## Instalación

Agregar la siguiente línea al Gemfile de su aplicación:

```ruby
gem 'liri'
```

y ejecute:

    $ bundle install

o instale la gema:

    $ gem install liri

## Uso

Para ver todos los comandos disponibles, ejecutar en línea de comandos:

    $ liri --help

## Desarrollo

Usar `rake spec` para ejecutar las pruebas unitarias.

Para instalar la gema localmente, usar `bundle exec rake install`. Para lanzar una nueva versión, actualizar el número de versión en `version.rb`, y ejecutar `bundle exec rake release`, que crea un tag de git para la version, realiza los commits, y sube el archivo `.gem` a [rubygems.org](https://rubygems.org).

Después de actualizar el código, usar el siguiente comando para ver las tareas disponibles: 
    
    $ rake -T  
    
Ejecutar para compilar e instalar la gema
    
    $ rake

La configuración de las tareas para manejar la gema están dentro del archivo Rakefile. 
    
También se puede usar el siguiente comando en línea de comandos para compilar en instalar la gema pero se recomienda usar las tareas rake
    
    $ sh compile
  
    
Para probar la gema instalada usar el siguiente comando

    $ liri
    
La configuración de los comandos disponibles de la gema están dentro del archivo /exe/liri. 
Las clases main o clases principales son lib/manager/manager y lib/manager/agent

#### Testing
Consultar las siguientes fuentes para la implementación de pruebas unitarias
- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-part-1--cms-26716
- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-02--cms-26720
- https://code.tutsplus.com/articles/rspec-testing-for-beginners-03--cms-26728
- https://www.betterspecs.org/

###### Dependence Management
Todas las gemas agregadas al Gemfile deben tener el siguiente formato para la versión:

    $ gem 'rubyzip', '~>2.2'    
    
Con el formato especificado, la versión de rubyzip instalada será igual o mayor a 2.2.0 y menor a 3.0.0, porque
cuando el primer dígito se cambia de 2 a 3, los cambios entre versiones son incompatibles. 
Más información en  https://blog.makeitreal.camp/manejo-de-dependencias-en-ruby-con-bundler/   
        
##### Rubocop
Rubocop es un analizador de código estáticos para user las mejores prácticas al escribir el código.
Para usar Rubocop, ejecutar el siguiente comando en la terminal:
    
    $ rubocop
    
Más información sobre Rubocop en: https://danielcastanera.com/anadir-rubocop-proyecto-rails/    
        
        
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/liri. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/liri/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Liri project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/liri/blob/master/CODE_OF_CONDUCT.md).
