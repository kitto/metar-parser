#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9'
require 'yaml'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

filename = File.join(File.expand_path(File.dirname(__FILE__) + '/../data'), "stations.yml")
stations = YAML.load_file(filename)

stations.each_pair do |cccc, raw_text|
  raw = Metar::Raw.new(cccc, raw_text)
  $stderr.puts "#{ cccc }: #{ raw.metar }"
  report = nil
  begin
    report = Metar::Report.new(raw)
    report.analyze
  rescue => e
    puts ': Parser error'
    puts e
    puts raw.metar
    puts report.inspect
    exit
  end
end