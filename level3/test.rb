#!/usr/bin/env ruby
#coding:utf-8

require 'json'
require 'logger'
require 'redis'
require 'sinatra'
require 'timeout'

$LOG = Logger.new(STDOUT)

class Parser
  OUTPUT_DIR = "parsed"
  REDIS_CONF = {
    'host' => '127.0.0.1',
    'port' => 6379 ,
    'db'   => 0
  }

  @@redis = nil

  def initialize(log)
    @@redis = Redis.new(host: REDIS_CONF["host"], port: REDIS_CONF["port"], db: REDIS_CONF["db"]) unless @@redis
    @log = log
  end

  def parse
    h = Hash[
      @log.split(' ').map do |a|
        /(?<prefix>[^#]*#)?(?<key>[^\=]+)\=(?<value>.*)/i =~ a
        [key, value]
      end
    ]
    @@redis.lpush 'logs', h.to_json
  rescue StandardError => e
    raise "Can't parse input file #{@input} - #{e.inspect}"
  end
end


begin
  set :port, 3000

  post '/' do
    begin
      # There is not timeout feature in Sinatra, so do it manually
      Timeout::timeout(0.1) {
        b = JSON.parse(request.body.read)
        Parser.new(b['log']).parse
      }
      [200, {}, ["Success"]]
    rescue Timeout::Error
      $LOG.error("Timeout, process is too long")
      [504, {}, ["Server timeout"]]
    rescue StandardError => e
      $LOG.error("#{e.inspect}")
      [500, {}, ["Error"]]
    end
  end
rescue StandardError => e
  $LOG.error("Unexpected error, #{e.inspect}")
end
