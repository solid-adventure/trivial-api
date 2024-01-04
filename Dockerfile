FROM ruby:3.1.2

RUN apt-get update && apt-get install -y nodejs postgresql-client
WORKDIR /app
COPY Gemfile* .
RUN gem install bundler
RUN bundle install
RUN bundle binstubs --all


COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]