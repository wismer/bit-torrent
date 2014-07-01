module Torrenter
  class Peer
    class Piece

      attr_reader :index, :file_link
      attr_accessor :status, :peers
      def initialize(index, folder, piece_length, hash, detail={})
        @index  = index
        @hash   = hash
        @folder = folder
        @detail = detail
        @piece_length = piece_length
        @peers  = []
        @blocks = []
        @status = true
      end

      def verify
        data = @detail.map { |chunk| chunk.read }.join
        @status = false if hash_match?(data)
      end

      def multiple_files?
        @detail.size > 1
      end

      def write_to_file
        puts "Writing #{@index} to file..."
        # binding.pry if @index == 9
        Dir.mkdir(@folder) if !Dir.exist?(@folder)
        @detail.each { |file| file.write(@blocks.join) }
        @blocks.clear
        @status = false
      end

      # def write(file)
      #   IO.write(file.path, @blocks.join('')[file.range], file.offset)
      # end

      def size
        @blocks.join.bytesize
      end

      def add(chunk)
        @detail << TorrentFile.new(chunk[0], chunk[1], chunk[2], chunk[3])
      end

      def complete?
        size >= @piece_length && hash_match?(@blocks.join)
      end

      def chunk
        @blocks.size * BLOCK
      end

      def <<(buffer)
        @blocks << buffer
      end

      def peer_count(socket)
        @peers.count(socket)
      end

      def peer_size
        @peers.length
      end

      def add_peer(peer)
        @peers << peer
      end

      def hash_match?(data)
        Digest::SHA1.digest(data) == @hash
      end
    end
  end
end