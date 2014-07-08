module Torrenter
  class Tracker

    attr_reader :response, :address

    class HTTPTracker < Tracker
      attr_reader :response
      def initialize(url, params)
        @address = URI(url)
        @params  = params
      end

      def connect
        @address.query = URI.encode_www_form(@params)
        begin
          @response = BEncode.load(Net::HTTP.get(@address))
        rescue Exception => e
          false
        end

        return self
      end

      def peer_list
        format_peers(peers)
      end

      def connect_interval
        @response['min interval']
      end

      def peers
        @response['peers']
      end

      def connected?
        @response
      end
    end
  end
end
