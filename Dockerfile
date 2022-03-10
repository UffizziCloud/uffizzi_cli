FROM ruby:3.0.3-alpine

RUN apk --update add --no-cache \
  curl-dev \
  ruby-dev \
  build-base \
  git \
  curl \
  ruby-json \
  openssl \
  groff \
  mandoc \
  man-pages \
  bash

RUN mkdir -p /gem
WORKDIR /gem

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

RUN gem install bundler -v 2.3.9

COPY lib/uffizzi/version.rb ./lib/uffizzi/
COPY uffizzi.gemspec .
COPY Gemfile* .
RUN bundle install --jobs 4

COPY . .

RUN bundle exec rake install

ENTRYPOINT ["/usr/local/bundle/bin/uffizzi"]
