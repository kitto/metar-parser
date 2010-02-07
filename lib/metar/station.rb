require 'rubygems' if RUBY_VERSION < '1.9'
require 'open-uri'

# A Station can be created without downloading data from the Internet.
# The class downloads and caches the NOAA station list when it is first requested.
# As soon of any of the attributes are read, the data is downloaded (if necessary), and attributes are set.

module Metar

  class Station
    NOAA_STATION_LIST_URL = 'http://weather.noaa.gov/data/nsd_cccc.txt'

    class << self

      @nsd_cccc = nil
      attr_accessor :nsd_cccc # Allow tests to run from local file

      def download_local
        nsd_cccc = Metar::Station.download_stations
        File.open(Metar::Station.local_nsd_path, 'w') do |fil|
          fil.write nsd_cccc
        end
      end

      def load_local
        download_local if not File.exist?(Metar::Station.local_nsd_path)
        @nsd_cccc = File.open(Metar::Station.local_nsd_path) do |fil|
          fil.read
        end
      end

      def all
        all_structures.collect do |h|
          options = h.clone
          cccc = options.delete(:cccc)
          new(cccc, h)
        end
      end

      def find_by_cccc(cccc)
        all.find { |station| station.cccc == cccc }
      end
      
      # Does the given CCCC code exist?
      def exist?(cccc)
        not find_data_by_cccc(cccc).nil?
      end

    end

    attr_reader :cccc, :loaded
    # loaded? indicates whether the data has been collected from the Web
    alias :loaded? :loaded

    # No check is made on the existence of the station
    def initialize(cccc, options = {})
      raise "Station identifier cannot be nil" if cccc.nil?
      raise "Station identifier must be a string" if not cccc.respond_to?('chars')
      @cccc      = cccc
      @name      = options[:name]
      @state     = options[:state]
      @country   = options[:country]
      @longitude = options[:longitude]
      @latitude  = options[:latitude]
      @loaded    = false
    end

    # Lazy loaded attributes
    ## TODO: DRY this up by generating these methods
    def name
      load! if not @loaded
      @name
    end

    def state
      load! if not @loaded
      @state
    end

    def country
      load! if not @loaded
      @country
    end

    def latitude
      load! if not @loaded
      @latitude
    end

    def longitude
      load! if not @loaded
      @longitude
    end

    def exist?
      Station.exist?(@cccc)
    end

    private

    class << self

      @structures = nil

      def download_stations
        open(NOAA_STATION_LIST_URL) { |fil| fil.read }
      end

      # Path for saving a local copy of the nsc_cccc station list
      def local_nsd_path
        File.join(File.expand_path(File.dirname(__FILE__) + '/../../'), 'data', 'nsd_cccc.txt')
      end

      def all_structures
        return @structures if @structures

        @nsd_cccc ||= download_stations
        @structures = []

        @nsd_cccc.each_line do |station|
          fields = station.split(';')
          @structures << {
            :cccc      => fields[0],
            :name      => fields[3],
            :state     => fields[4],
            :country   => fields[5],
            :latitude  => fields[7],
            :longitude => fields[8],
          }
        end

        @structures
      end

      def find_data_by_cccc(cccc)
        all_structures.find { |station| station[:cccc] == cccc }
      end

    end

    # Get data from the NOAA data file (very slow on first call!)
    def load!
      noaa_data  = Station.find_data_by_cccc(@cccc)
      raise "Station identifier '#{ @cccc }' not found" if noaa_data.nil?
      @name      = noaa_data[:name]
      @state     = noaa_data[:state]
      @country   = noaa_data[:country]
      @longitude = noaa_data[:longitude]
      @latitude  = noaa_data[:latitude]
      @loaded    = true
      self
    end

  end

end