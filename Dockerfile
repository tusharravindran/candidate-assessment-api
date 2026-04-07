FROM ruby:3.2.2-alpine

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    git \
    curl

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/

EXPOSE 3001

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
