FROM ruby:3.0.2-alpine3.14

RUN apk update && apk upgrade
RUN apk add bash
RUN apk add curl-dev ruby-dev build-base git curl ruby-json openssl groff mandoc man-pages

RUN mkdir -p /gem
WORKDIR /gem

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

RUN gem install uffizzi-cli
RUN gem install bundler -v 2.3.8

COPY lib/uffizzi/version.rb /gem/lib/uffizzi/
COPY uffizzi.gemspec /gem/
COPY Gemfile* /gem/
RUN bundle install --jobs 4

COPY . /gem

CMD ["uffizzi"]
