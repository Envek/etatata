#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'pry'

set :bind, ENV.fetch('LISTEN', '0.0.0.0')
set :port, Integer(ENV.fetch('PORT', 4567))

ETA_SERVICE_HOST = ENV.fetch('ETA_SERVICE_HOST', '127.0.0.1')
ETA_SERVICE_PORT = Integer(ENV.fetch('ETA_SERVICE_PORT', 4568))

get '/' do
  param :latitude,   Float, required: true, range: -90.0..+90.0
  param :longitude,  Float, required: true, range: -180.0..+180.0

  eta = eta_service.call(:eta, params[:latitude], params[:longitude])

  headers('Content-Type' => 'application/json')
  body Oj.dump({ 'eta' => eta })
end

error MessagePack::RPC::TimeoutError do
  status 504 # Gateway Timeout
  body Oj.dump({ 'error' => env['sinatra.error'].message })
end

error MessagePack::RPC::Error do
  status 502 # Bad Gateway
  body Oj.dump({ 'error' => env['sinatra.error'].message })
end

def eta_service
  Thread.current[:eta_service] ||= MessagePack::RPC::Client.new(ETA_SERVICE_HOST, ETA_SERVICE_PORT)
end
