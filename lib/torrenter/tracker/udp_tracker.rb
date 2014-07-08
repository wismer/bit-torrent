module Torrenter
  class Tracker
    class UDPTracker < Tracker

      attr_reader :socket, :response, :interval

      def initialize(tracker, params)
        @url           = tracker[/(?<=udp\:\/\/).+(?=\:\d+)/]
        @port          = tracker[/\d+$/].to_i
        @socket        = UDPSocket.new
        @connection_id = [0x41727101980].pack("Q>")
        @params        = params
      end

      def interval?
        interval % Time.now.to_i == 0
      end

      def segment(e, enc="I>")
        [e].pack(enc)
      end

      def connect
        @transaction_id = segment(rand(10000), "I>")
        @socket.connect(ip_addr, @port)
        begin
          send_msg(connect_msg)
          read_response
          bound_peers
        rescue
          false
        end
        return self
      end

      def send_msg(msg)
        begin
          @socket.send(msg, 0)
        rescue
          false
        end
      end

      def connected?
        @response
      end

      def ip_addr
        Socket.getaddrinfo(@url, @port)[0][3]
      end

      def bound_peers
        @connection_id = @response[-8..-1]
        @transaction_id = [rand(10000)].pack("I>")
        send_msg(announce_msg)

        read_response

        parse_announce if @response[0..3] == segment(1)
      end

      def peer_list
        format_peers(@response)
      end

      def parse_announce
        if @response[4..7] == @transaction_id
          @interval = @response[8..11].unpack("I>").first
          res = @response.slice!(0..11)
          @leechers = @response.slice!(0..3).unpack("I>").first
          @seeders  = @response.slice!(0..3).unpack("I>").first
        end
      end

      def send_message
        begin
          @socket.send(@msg, 0)
        rescue *EXCEPTIONS
        end
      end

      def read_response
        begin
          @response = @socket.recv(1028)
        rescue Exception => e
          e
        end
      end

      def connect_match?
        data[0] == (segment(0) + @transaction_id + @connection_id)
      end

      def announce_input
        @connection_id + segment(1) + @transaction_id + @params[:info_hash] + PEER_ID
      end

      def connect_msg
        @connection_id + segment(0) + @transaction_id
      end

      def announce_msg
        announce_input + (segment(0, "Q>") * 3) + (segment(0) * 3) + segment(-1) + segment(@socket.addr[1], ">S")
      end
    end
  end
end
