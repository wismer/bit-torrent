module Torrenter
  # The buffer state should be responsible ONLY for the handling of non-metadata bytes.
  # the messaging behavior should and ought to remain with the peer class, though
  # in truth, it may be better if I didnt do that. 

  # So, if the state of the buffer reaches a certain step in its process involving the piece
  # the buffer state should be fired off. 

  # instead of initialiazing it with the buffer, 
  class Peer
    class BufferState
      def initialize(socket, info_hash)
        @fuckin_a = []
        @socket = socket
        @buffer = ''
        @info_hash = info_hash
      end

      def messager(index=nil, blk)
        if @buffer.empty?
          recv
        else
          case @buffer[4]
          when nil
            @buffer.slice!(0..3) if @buffer[0..3] == KEEP_ALIVE
          when HANDSHAKE
            parse_handshake
          when BITFIELD
            bitfield.each_with_index { |bit, i|
              binding.pry if i > index.size
              blk.call(i, @socket) if bit == '1' }
            send_interested if @buffer.empty?
          when HAVE
            sad = have
            binding.pry if sad.nil? || sad > 54
            blk.call(sad, @socket)
            send_interested if @buffer.empty?
          when INTERESTED
            parse_interested(index)
          when PIECE
            parse_piece(index)
          when CANCEL
            binding.pry
          else
            recv
          end
        end
      end

      def index_complete?(master_index)
        master_index.length == @piece_index.length
      end

      def hash_matches?
        @buffer[28..47] == @info_hash
      end

      def parse_handshake
        if !hash_matches?
          yield
        else
          @buffer.slice!(0..67)
        end
      end

      def have
        unpack('C').last
      end

      def bitfield
        unpack('B').first.split('')
      end

      def pick_piece(index)
        @piece = index.find_least(@socket)
        puts "#{@piece.index} selected."
      end

      def parse_interested(index)
        if interested?
          pick_piece(index)
          request_piece
          # @piece.parse(@buffer)
        else
          @socket.close
        end
      end

      def parse_piece(index)
        if packet_length?
          @piece << @buffer.slice!(13..-1)
          @buffer.clear
          if @piece.complete?
            binding.pry if @index == 9
            @piece.write_to_file
            pick_piece(index) unless index.all?
          end
          request_piece
        else
          recv
        end
      end

      def packet_length?
        @buffer.size >= msg_length + 4
      end

      def request_piece
        send pack(13, "\x06", @piece.index, @piece.chunk, BLOCK)
      end

      def send(msg)
        @socket.sendmsg_nonblock(msg)
      end

      def recv(bytes=BLOCK)
        begin
          @buffer << @socket.recv_nonblock(bytes)
        rescue *EXCEPTIONS
          ''
        end
      end

      private

        def send_interested
          send("\x00\x00\x00\x01\x02")
        end

        def pack(*msg)
          msg.map { |m| m.is_a?(Integer) ? [m].pack("I>") : m }.join
        end

        def unpack(type)
          @buffer.slice!(0...msg_length + 4)[5..-1].unpack("#{type}*")
        end

        def msg_length
          @buffer[0..3].unpack("N*").last
        end

        def interested?
          @buffer.slice!(0..4) == "\x00\x00\x00\x01\x01"
        end

    end
  end
end