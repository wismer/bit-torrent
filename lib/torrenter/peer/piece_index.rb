require 'pry'

# make elements within the piece index contain peers that HAVE the piece.
module Torrenter
  class Peer
    class PieceIndex
      attr_reader :piece_index
      def initialize
        @piece_index = []
      end

      def find_least(socket, index=nil)
        counter = 1
        loop do
          break if index
          @piece_index.each_with_index do |p,i|
            if p.status == true
              if p.peer_size == counter && p.peer_count(socket) == 1
                @piece_index[i].status = false
                index = p
                break
              end
            end
          end
          counter += 1
        end
        return index
      end

      def verify_status
        @piece_index.each { |piece| piece.verify }
      end

      def all?
        @piece_index.all? { |piece| piece.status == false }
      end

      def <<(piece)
        @piece_index << piece
      end

      def add_peer(index, peer)
        @piece_index[index].peers << peer if @piece_index[index]
      end

      def size
        @piece_index.size
      end

      def each
        @piece_index.each { |piece| yield piece }
      end

      def length
        @piece_index.length
      end

      def [](index)
        binding.pry if index.nil?
        @piece_index[index]
      end

      def last
        @piece_index.last
      end
    end
  end
end