# Uffizzi Command-line Interface

[![CircleCI](https://circleci.com/gh/UffizziCloud/uffizzi_cli/tree/master.svg?style=shield)](https://circleci.com/gh/UffizziCloud/uffizzi_cli/tree/master)

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

## Commands

### login ###

```
$ uffizzi login -u your@email.com -h localhost:8080
```
Logging you into the app which you set in the hostname option.


### login options ###

Option      | Aliase          | Description
-------     | -------         | -----------
`--user`    | `-u`            | Your email for logging in
`--hostname`| `-h`            | Adress of your app

If hostname uses basic authentication you can specify options for it by setting `basic_auth_user` and `basic_auth_password` via `config set` command.

### projects ###

```
$ uffizzi projects
```

Shows all your projects' slugs

### config ###

Use this command to configure your cli app. This command has 4 subcommands `list`, `get`, `set`, and `delete`.

```
$ uffizzi config list
```
Shows all options and their values from the config file.

```
$ uffizzi config get OPTION
```

Shows the value of the specified option.

```
$ uffizzi config set OPTION VALUE
```

Sets specified value for specified option. If a specified option already exists and has value it will be overwritten.

```
$ uffizzi config delete OPTION
```

Deletes specified option.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UffizziCloud/uffizzi_cli.
