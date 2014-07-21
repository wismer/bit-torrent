module Torrenter
  class TorrentReader
    class PieceIndex
      attr_reader :piece_index, :piece_length
      def initialize(piece_length)
        @piece_length = piece_length
        @piece_index  = []
      end

      def find_least(socket, i=1)
        return nil if none_remain? || i > peer_count.sort.last
        index = peer_count.find_index(i)
        if index && available_pieces[index].include?(socket)
          piece = available_pieces[index]
          piece.status = :downloading
          return piece
        else
          find_least(socket, i+1)
        end
      end

      def clean_peers
        @piece_index.each { |piece| piece.remove_peer }
      end

      def <<(piece)
        @piece_index << piece
      end

      def none_remain?
        count(:available) == 0
      end

      def peer_count
        available_pieces.map { |piece| piece.peers.length }
      end

      def available_pieces
        @piece_index.select { |piece| piece.status == :available }
      end

      def count(type)
        @piece_index.select { |piece| piece.status == type }.length
      end

      def verify_status
        @piece_index.each { |piece| piece.verify }
      end

      def all?
        @piece_index.all? { |piece| piece.status == :downloaded }
      end

      def add_peer(index, peer)
        @piece_index[index].peers << peer if @piece_index[index]
      end

      def size
        @piece_index.size
      end

      def [](index)
        @piece_index[index]
      end

      def []=(i, val)
        @piece_index[i] = Piece.new(i, piece_length, val)
      end

      def last
        @piece_index.last
      end

      def to_json
        JSON.generate({ :master_index => @piece_index.map { |p| p.percent } })
      end
    end
  end
end