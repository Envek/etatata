FROM ruby:2.3.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN mkdir -p /srv/eta_service
WORKDIR /srv/eta_service
ADD . /srv/eta_service
RUN bundle install
EXPOSE 4568
CMD ruby eta_service.rb
