FROM ruby:3.1.2

RUN apt-get update && apt-get install -y cron nodejs postgresql-client
WORKDIR /app
COPY Gemfile* .
RUN gem install bundler
RUN bundle install
RUN bundle binstubs --all

COPY . .

RUN chmod +x docker/entrypoint.sh
RUN chmod +x docker/start-web.sh
RUN bundle exec whenever --update-crontab

ENTRYPOINT ["./docker/entrypoint.sh"]

CMD ["./docker/start-web.sh"]

EXPOSE 3000