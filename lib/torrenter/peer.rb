module Torrenter
  class Peer
    attr_reader :buffer, :peer_state, :socket, :ip
    def initialize(ip, port, params={})
      @ip = ip
      @port = port
      @info_hash = params[:info_hash]
      @piece_length = params[:left]
      @peer_state   = false
    end

    def connect
      puts "\nConnecting to IP: #{@ip} PORT: #{@port}"
      begin
        Timeout::timeout(1) { @socket = TCPSocket.new(@ip, @port) }
      rescue Timeout::Error
        puts "Timed out."
      rescue Errno::EADDRNOTAVAIL
        puts "Address not available."
      rescue Errno::ECONNREFUSED
        puts "Connection refused."
      rescue Errno::ECONNRESET
        puts "bastards."
      end

      if @socket
        puts "Connected!"
        @peer_state = true
        @buffer = BufferState.new(@socket, @info_hash)
        @buffer.send(handshake)
      else
        @peer_state = false
      end
    end

    def connection_state(index, blk)
      if @socket.closed?
        @peer_state = false
        @buffer.current_piece = :available
      else
        @buffer.messager(index, blk)
      end
    end

    def handshake
      "#{PROTOCOL}#{@info_hash}#{PEER_ID}"
    end

    def connected?
      @peer_state
    end
  end
end
