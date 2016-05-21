#!/usr/bin/env ruby

Process.setproctitle('ETA Service')

require 'bundler'
Bundler.require
require 'active_support/logger'
require 'active_support/cache'

MULTIPLIER = Float(ENV.fetch('MULTIPLIER', 1.5))
CACHE_EXPIRATION_TIME = Integer(ENV.fetch('CACHE_EXPIRATION_TIME', 15))
# 3 знака после запятой — это около 111 метров по долготе и не более, чем 111 метров по широте (по экватору)
CACHE_COORD_PRECISION = Integer(ENV.fetch('CACHE_COORD_PRECISION', 3))

LISTEN = ENV.fetch('LISTEN', '0.0.0.0')
PORT   = Integer(ENV.fetch('PORT', 4568))

class EtaService
  # Calculates mean Estimated Time of Arrival (in minutes) for vehicles nearest to the given point
  #
  # @param  [Float] Latitude of target point in degrees
  # @param  [Float] Longitude of target point in degrees
  # @return [Float] ETA in minutes
  def eta(latitude, longitude)
    latitude, longitude = Float(latitude), Float(longitude)
    unless (-90.0..+90.0).cover?(latitude) && (-180.0..+180.0).cover?(longitude)
      raise ArgumentError, "Latitude and longitude MUST BE a Float numbers in degrees within range -90..90 and -180..180"
    end

    cache.fetch(cache_key(:calculate_eta, latitude, longitude)) do
      calculate_eta(latitude, longitude)
    end
  end

  private

  def calculate_eta(latitude, longitude)
    ts = Time.now
    point = connection.quote("POINT(#{longitude} #{latitude})")
    result = connection.execute(<<-SQL.squish)
      SELECT
        ST_X(vehicles.position::geometry) AS longitude,
        ST_Y(vehicles.position::geometry) AS latitude
      FROM vehicles
      WHERE available = true
      ORDER BY vehicles.position <-> #{point}::geography ASC
      LIMIT 3;
    SQL

    nearest_distances = result.map.with_index do |result|
      haversine_distance([latitude, longitude], [result['latitude'], result['longitude']])
    end
    eta = nearest_distances.reduce(:+) / nearest_distances.size * MULTIPLIER
    logger.info sprintf("ETA of %.2f minutes was calculated in %.1f ms", eta, (Time.now-ts)*1000)
    eta
  end

  # See https://en.wikipedia.org/wiki/Haversine_formula
  def haversine_distance(start_coords, end_coords, radius: 6371)
    lat1, long1 = deg2rad(*start_coords)
    lat2, long2 = deg2rad(*end_coords)
    2 * radius * Math.asin(
      Math.sqrt(
        Math.sin((lat2 - lat1) / 2) ** 2 +
        Math.cos(lat1) * Math.cos(lat2) *
        Math.sin((long2 - long1) / 2) ** 2
      )
    )
  end

  def deg2rad(lat, long)
    [lat * Math::PI / 180, long * Math::PI / 180]
  end

  def connection
    return @connection if defined? @connection
    ActiveRecord::Base.establish_connection(ENV.fetch('DATABASE_URL'))
    @connection = ActiveRecord::Base.connection
  end

  def cache
    return @cache if @cache
    @cache = ActiveSupport::Cache::MemoryStore.new(expires_in: CACHE_EXPIRATION_TIME)
    @cache.logger = logger
    @cache
  end

  def logger
    return @logger if defined? @logger
    @logger = Logger.new(STDERR)
    @logger.level = ENV['ENV'] == 'production' ? Logger::INFO : Logger::DEBUG
    @logger
  end

  def cache_key(prefix, latitude, longitude)
    [prefix, latitude.round(CACHE_COORD_PRECISION), longitude.round(CACHE_COORD_PRECISION)]
  end
end

service = EtaService.new
server = MessagePack::RPC::Server.new
server.listen(LISTEN, PORT, service)
service.send(:logger).info("ETA Service is listening on #{LISTEN}:#{PORT}")
server.run
