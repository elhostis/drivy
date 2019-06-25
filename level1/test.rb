#!/usr/bin/env ruby
#coding:utf-8

require 'json'
require 'logger'

$LOG = Logger.new(STDOUT)

class Parser
  OUTPUT_DIR = "parsed"

  def initialize(input)
    @input = input
    @output = "#{OUTPUT_DIR}/#{File.basename(input)}"
  end

  def parse
    o = File.open(@output, "w")
    File.foreach(@input) do |l|
      o.write(
        Hash[
          l.split(' ').map do |a|
            /(?<prefix>[^#]*#)?(?<key>[^\=]+)\=(?<value>.*)/i =~ a
            [key, value]
          end
          ].to_json
      )
    end
  rescue StandardError => e
    raise "Can't parse input file #{@input} - #{e.inspect}"
  ensure
    o.close unless o.nil?
  end
end

begin
  Dir.mkdir(Parser::OUTPUT_DIR) unless File.exists?(Parser::OUTPUT_DIR)
  Dir["logs/*.txt"].each do |f|
    p = Parser.new(f)
    p.parse
    File.delete(f) if File.exist?(f)
  end
rescue StandardError => e
  puts "Unexpected error, #{e.inspect}"
end
