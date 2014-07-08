module Torrenter
  class TorrentReader
    class Piece
      attr_accessor :range, :path, :hash, :index, :status
      attr_reader :peers, :data
      def initialize(piece_length)
        @range        = []
        @path         = []
        @piece_length = piece_length
        @status       = :available
        @data         = ''
        @peers        = []
      end

      def tally
        if @range.length > 0
          @range.map { |r| r.end - r.begin }.inject { |x,y| x + y }
        else
          0
        end
      end

      def left
        @piece_length - tally
      end

      def full?
        tally == @piece_length
      end

      def add(range, path)
        @range << range
        @path << path
      end

      def include?(socket)
        @peers.include?(socket)
      end

      def verify
        @data = if multiple_files?
                  @path.map.with_index { |p, i| read_file(p, i) }.join
                else
                  File.file?(@path.join) ? (IO.read(@path.join, @piece_length, @range.first.begin) || '') : ''
                end
        @status = hash_match? ? :downloaded : :available
        @data.clear
      end

      def offset(i)
        @range[i].end - @range[i].begin
      end

      def multiple_files?
        @path.length > 1
      end

      def write_to_file
        if multiple_files?
          @path.each_with_index { |p,i| write_file(p, i) }
        else
          IO.write(@path.first, @data, @range.first.begin)
        end
        @status = :downloaded
        @data.clear
      end

      def complete?
        @data.bytesize >= tally && hash_match?
      end

      def block
        (tally - @data.size) < BLOCK ? tally - @data.size : BLOCK
      end

      def chunk
        (@data.bytesize / BLOCK) * BLOCK
      end

      def <<(buffer)
        @data << buffer
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

      def remove_peer
        @peers.each { |p| @peers.delete(p) if p.closed? }
      end

      def hash_match?
        Digest::SHA1.digest(@data) == @hash
      end

      def percent
        if @status == :downloading
          return (@data.size).fdiv(@piece_length)
        elsif @status == :downloaded
          return 1
        else
          return 0
        end
      end

      private
        def read_file(p, i)
          binding.pry if offset(i) < 0
          File.file?(p) ? IO.read(p, offset(i), @range[i].begin) : ''
        end

        def write_file(p, i)
          IO.write(p, @data.slice!(0...offset(i)), @range[i].begin)
        end
    end
  end
end