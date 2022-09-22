# Liri

Sistema que ejecuta pruebas unitarias de manera distribuida dentro de una red de computadoras a fin de aumentar la 
velocidad de ejecución.

El sistema Liri está compuesto por dos aplicaciones que están empaquetadas dentro de la gema Liri.

Esta gema es compatible con proyectos Ruby o Ruby on Rails que utilicen la gema RSpec.

Este es un repositorio que contiene la documentación y el código fuente de un proyecto desarrollado en el contexto de un Trabajo Final de Grado 
para la carrera Ingeniería Informática de la Universidad Nacional de Itapúa con sede en Encarnación - Itapúa - Paraguay. 

Se recomienda tener las debidas precauciones al momento de utilizar los datos de este proyecto ya que todavía no es una versión final
estable y no es seguro que algún día llegue a ser estable.

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
Esta gema esta compuesta por dos aplicaciones: una Aplicación Coordinadora y una Aplicación Agente. 

La Aplicación Coordinadora, coordina la ejecución de las pruebas conectandose con las Aplicaciones Agente. 

La Aplicación Coordinadora se ejecuta desde la raiz de un proyecto Ruby o Ruby on Rails a través del siguiente comando:

    $ liri m

La Aplicación Agente se encarga de ejecutar las pruebas y enviar los resultados a la Aplicación Coordinadora. Se pueden
tener tantas Aplicaciones Agente como se desee en un red de computadoras.

La Aplicación Coordinadora se puede ejecutar de manera manual cada vez que se desee a través del siguiente comando:

    $ liri a

o bien, se puede instalar como un servicio del sistema, a través del archivo comprimido liriagent.zip que se encuentra
en la carpeta /installers dentro de este repositorio. Este instalador sólo funciona en sistemas operativos Linux.

Una vez descargado el instalador, se debe descomprimir e ingresar desde linea de comandos a la carpeta /bin de la carpeta 
descomprimida y ejecutar el comando:

    $ ./install.sh

Para que funcione el Sistema Liri, las computadoras en donde esten ejecutandose la Aplicación Coordinadora y la Aplicación 
Agente, deben tener configuradas todos los requisitos de la aplicación a probar, por ejemplo, si se va a ejecutar las pruebas
unitarias de una gema X, si esta gema X requiere una versión específica de Ruby o una conexión a base de datos, este tipo 
de cosas deben configurarse de manera manual.

## Desarrollo
La rama master siempre debe ser estable.
Se debe crear un release cada vez que se llega a una versión estable de algún agregado nuevo.
Agregar fixes y mejoras en ramas.

### Pruebas Unitarias

Para ejecutar las pruebas unitarias del proyecto, ejecute el comando:

    $ rake spec

Consultar las siguientes fuentes para la implementación de pruebas unitarias:

- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-part-1--cms-26716
- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-02--cms-26720
- https://code.tutsplus.com/articles/rspec-testing-for-beginners-03--cms-26728
- https://www.betterspecs.org/

### Compilación
Para compilar la gema:

    $ rake build

Para instalar la gema:

    $ rake install

Para publicar la gema en RubyGems.org

    $ rake publish
Antes de publicar la gema se debe actualizar la versión de la misma en el archivo /lib/liri.rb

Para realizar un proceso completo:
    
    $ rake

Este comando compila e instala la gema, además crea una nueva versión del instalador agente dentro de la carpeta /installers

### Detalles de estructura e implementación
La configuración de las tareas para manejar la gema están dentro del archivo Rakefile.

La configuración de los comandos disponibles de la gema están dentro del archivo /exe/liri.

Las clases main o clases principales están en los archivos lib/manager/manager.rb y lib/agent/agent.rb

## Buenas Prácticas
### Rubocop
Rubocop es un analizador de código estáticos para user las mejores prácticas al escribir el código.
Para usar Rubocop, ejecutar el siguiente comando en la terminal:

    $ rubocop

Más información sobre Rubocop en: https://danielcastanera.com/anadir-rubocop-proyecto-rails/

### Documentación
Para la documentación se usa la gema Yard según las pautas indicadas en:

- https://rubydoc.info/gems/yard/file/docs/GettingStarted.md

Para generar la documentación ejecutar el comando:

    $ yard

El comando anterior crea una carpeta /doc del cual se tiene que abrir el archivo index.html
en un navegador

Una alternativa a yard es la gema Rdoc que al parecer también es utilizada por Yard:

- http://blog.firsthand.ca/2010/09/ruby-rdoc-example.html
- https://gist.github.com/hunj/f89cabc10c155f06cc3e

Para generar la documentación ejecutar comando:

    $ rdoc

El comando anterior crea una carpeta /doc del cual se tiene que abrir el archivo index.html
en un navegador

## Manejo de dependencias
Todas las gemas agregadas al Gemfile deben tener el siguiente formato para la versión:

    $ gem 'rubyzip', '~>2.2'    

Con el formato especificado, la versión de rubyzip instalada será igual o mayor a 2.2.0 y menor a 3.0.0, porque
cuando el primer dígito se cambia de 2 a 3, los cambios entre versiones son incompatibles.
Más información en:  https://blog.makeitreal.camp/manejo-de-dependencias-en-ruby-con-bundler/

## Contribución

Esta gema no acepta contribuciones porque corresponde a un Trabajo Final de Grado Universitario.

## Licencia

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

No nos hacemos responsables de los perjuicios que pueda causar el uso de la información de las documentaciones compartidas y del código
fuente compartido en este repositorio.

Cualquier uso que se le dé a a los datos contenidos de este repositorio debe ir con la correspondiente referencia hacia este repositorio.

## Código de conducta

Everyone interacting in the Liri project's codebases, issue trackers, chat rooms and mailing lists is expected to
follow the [code of conduct](https://github.com/[USERNAME]/liri/blob/master/CODE_OF_CONDUCT.md).
