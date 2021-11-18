FROM ruby:3.0.2-alpine3.14

RUN apk update && apk upgrade
RUN apk add bash
RUN apk add curl-dev ruby-dev build-base git curl ruby-json openssl

RUN mkdir -p /gem
WORKDIR /gem

COPY lib/uffizzi/version.rb /gem/lib/uffizzi/
COPY uffizzi.gemspec /gem/
COPY Gemfile* /gem/
RUN bundle install --jobs 4

COPY . /gem
