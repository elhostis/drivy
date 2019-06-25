#!/usr/bin/env ruby
#coding:utf-8

require 'json'
require 'logger'
require 'sinatra'
require 'timeout'

$LOG = Logger.new(STDOUT)

class Parser
  OUTPUT_DIR = "parsed"

  def initialize(log)
    @log = log
  end

  def parse
    h = Hash[
      @log.split(' ').map do |a|
        /(?<prefix>[^#]*#)?(?<key>[^\=]+)\=(?<value>.*)/i =~ a
        [key, value]
      end
    ]
    File.open("#{OUTPUT_DIR}/#{h["id"]}", 'w') { |o| o.write(h.to_json) }
  rescue StandardError => e
    raise "Can't parse input file #{@input} - #{e.inspect}"
  end
end


begin
  set :port, 3000

  Dir.mkdir(Parser::OUTPUT_DIR) unless File.exists?(Parser::OUTPUT_DIR)

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
