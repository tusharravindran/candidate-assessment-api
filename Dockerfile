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

# Puma needs tmp/pids to write server.pid; create it so the directory exists
# even on a fresh container with no mounted volume.
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log

RUN bundle exec bootsnap precompile --gemfile app/ lib/

EXPOSE 3001

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
