FROM ruby:2.3.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir -p /srv/eta_api
WORKDIR /srv/eta_api
ADD . /srv/eta_api
RUN bundle install
EXPOSE 4567
CMD ruby eta_api.rb
