require 'rubygems' if RUBY_VERSION < '1.9'
require 'open-uri'

module Metar

  class Raw

    class << self

      def proxy
        ENV["ftp_proxy"] || ENV["all_proxy"]
      end

      def fetch(cccc)
        if self.proxy
          open("ftp://tgftp.nws.noaa.gov/data/observations/metar/stations/#{cccc}.TXT", :proxy => self.proxy).read()
        else
          open("ftp://tgftp.nws.noaa.gov/data/observations/metar/stations/#{cccc}.TXT").read()
        end
      end

    end

    attr_reader :cccc

    # Station is a string containing the CCCC code, or
    # an object with a 'cccc' method which returns the code
    def initialize( station, data = nil )
      @cccc = station.respond_to?(:cccc) ? station.cccc : station
      parse data if data
    end

    def data
      fetch
      @data
    end
    # #raw is deprecated, use #data
    alias :raw :data

    def time
      fetch
      @time
    end

    def metar
      fetch
      @metar
    end
    alias :to_s :metar

    private

    def fetch
      return if @data
      parse Raw.fetch( @cccc )
    end

    def parse( data )
      @data        = data
      time, @metar = @data.split( "\n" )
      @time        = Time.parse( time )
    end

  end

end
