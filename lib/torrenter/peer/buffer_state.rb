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
        @socket    = socket
        @buffer    = ''
        @info_hash = info_hash
      end

      def messager(index, blk)
        if @buffer.empty?
          recv
        else
          case @buffer[4]
          when nil
            @buffer.slice!(0..3) if @buffer[0..3] == KEEP_ALIVE
          when HANDSHAKE
            parse_handshake
          when BITFIELD
            bitfield.each_with_index do |bit, i|
              blk.call(i, @socket) if bit == '1'
            end

            send_interested if @buffer.empty?
          when HAVE
            if @buffer.bytesize < 9
              recv
            else
              have { |i| blk.call(i, @socket) }
            end
            send_interested if @buffer.empty?
          when INTERESTED
            parse_interested(index)
          when PIECE
            parse_piece(index)
          when CANCEL
            @socket.close
          else
            recv
            send(KEEP_ALIVE)
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
        yield unpack('C').last
      end

      def bitfield
        unpack('B').first.split('')
      end

      def pick_piece(index)
        @piece = index.find_least(@socket)
        if @piece
          puts "#{@piece.index} selected by #{@socket}."
        else
          puts "No piece selected!"
        end
      end

      def parse_interested(index)
        if interested?
          pick_piece(index)
          request_piece if @piece
        else
          @socket.close
        end
      end

      def parse_piece(index)
        if packet_length?
          @piece << @buffer.slice!(13..-1)
          @buffer.clear
          if @piece.complete?
            @piece.write_to_file
            @piece = nil
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
        send pack(13, "\x06", @piece.index, @piece.chunk, @piece.block) if @piece
      end

      def send(msg)
        @socket.sendmsg_nonblock(msg)
      end

      def recv(bytes=BLOCK)
        begin
          @buffer << @socket.recv_nonblock(bytes)
        rescue *EXCEPTIONS
          ''
        rescue Errno::ETIMEDOUT
          if piece_selected?
            @piece.status = :available
          end
          @socket.close
        end
      end

      def piece_selected?
        @piece
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