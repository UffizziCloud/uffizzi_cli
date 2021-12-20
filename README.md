# Uffizzi CLI  

A command-line interace (CLI) for [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) 


## Uffizzi Overview

**Uffizzi Full-stack Previews Engine**

Preview code before it’s merged—whether frontend, backend or microserivce. Define your full-stack apps with a familiar syntax based on Docker Compose, then Uffizzi will create on-demand test environments when you open pull requests or build new images. Preview URLs are updated when there’s a new commit, so your team can catch issues early, iterate quickly, and accelerate your release cycles.  

&nbsp;    
**Uffizzi Architecture**  

Dependencies:  
 * Kubernetes (k8s) cluster  
 * Postgres database  
 * Redis cache  

Uffizzi consists of the following components:  

* [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) - The primary REST API for creating and managing Previews  
* [Uffizzi Controller](https://github.com/UffizziCloud/uffizzi_controller) - A smart proxy service that handles requests from Uffizzi App to the Kubernetes API  
* Uffizzi CLI (this repository) - A command-line interface for Uffizzi App    
* [Uffizzi Dashboard](https://uffizzi.com) - A graphical user interface for Uffizzi App  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uffizzi'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uffizzi

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Run rubocop:
`bundle exec rubocop -A`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.
