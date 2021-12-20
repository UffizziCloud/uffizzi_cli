# Uffizzi CLI  

A command-line interace (CLI) for [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) 

## Uffizzi Overview

Uffizzi is the Full-stack Previews Engine that makes it easy for your team to preview code changes before merging—whether frontend, backend or microserivce. Define your full-stack apps with a familiar syntax based on Docker Compose, and Uffizzi will create on-demand test environments when you open pull requests or build new images. Preview URLs are updated when there’s a new commit, so your team can catch issues early, iterate quickly, and accelerate your release cycles.  

## Getting started with Uffizzi  

The fastest and easiest way to get started with Uffizzi is via the fully hosted version available at https://uffizzi.com, which includes free plans for small team and qualifying open-source projects.   

Alternatively, you can self-host Uffizzi via the open-source repositories available here on GitHub. The remainder of this README is intended for users interested in self-hosting Uffizzi or for those who are just curious about how Uffizzi works.

## Uffizzi Architecture  

Uffizzi consists of the following components:  

* [Uffizzi App](https://github.com/UffizziCloud/uffizzi_app) - The primary REST API for creating and managing Previews  
* [Uffizzi Controller](https://github.com/UffizziCloud/uffizzi_controller) - A smart proxy service that handles requests from Uffizzi App to the Kubernetes API  
* Uffizzi CLI (this repository) - A command-line interface for Uffizzi App    
* [Uffizzi Dashboard](https://app.uffizzi.com) - A graphical user interface for Uffizzi App, available as a paid service at https://uffizzi.com  

To host Uffizzi yourself, you will also need the following external dependencies:  

 * Kubernetes (k8s) cluster  
 * Postgres database  
 * Redis cache  

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
