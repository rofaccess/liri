# Liri

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/liri`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'liri'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install liri

## Usage

TODO: Write usage instructions here

## Desarrollo

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Build the gem in terminal after code update, with next command:
    
    $ sh compile
 
Show alternative commands to build with:

    $ rake -T  
    
I don't know yet what is the difference between compile script and rake tasks.    
    
Test code itself running next command in terminal:

    $ Liri run

#### Testing
Consultar las siguientes fuentes para la implementación de pruebas unitarias
- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-part-1--cms-26716
- https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-02--cms-26720
- https://code.tutsplus.com/articles/rspec-testing-for-beginners-03--cms-26728
- https://www.betterspecs.org/

###### Dependence Management
All gems added in Gemfile must be set the version in next format:

    $ gem 'rubyzip', '~>2.2'    
    
With the version format specified, the version of rubyzip installed will be equal or greater than 2.2.0 and less 
than 3.0.0, because when change the first digit from 2 to 3 the changes between version are incompatible. More info 
in: https://blog.makeitreal.camp/manejo-de-dependencias-en-ruby-con-bundler/   
        
##### Rubocop
Rubocop is a static code analyser to use best practices for write code.
To use Rubocop, run next command in terminal:
    
    $ rubocop
    
More info about Rubocop in: https://danielcastanera.com/anadir-rubocop-proyecto-rails/    
        
        
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/liri. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/liri/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Liri project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/liri/blob/master/CODE_OF_CONDUCT.md).
