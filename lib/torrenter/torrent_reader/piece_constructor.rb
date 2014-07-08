module Torrenter
  class TorrentReader
    class PieceConstructor

      attr_reader :index
      def initialize(files, folder, sha_hashes, piece_length)
        @files        = files
        @folder       = folder
        @sha_hashes   = sha_hashes
        @piece_length = piece_length
        @index        = PieceIndex.new(piece_length)
        @excess_bytes = 0
      end

      def index_length
        @sha_hashes.size / 20
      end

      def correct?
        total_left == @arr.map { |x| x.tally }.inject { |x,y| x + y }
      end

      def total_left
        @files.map { |f| f['length']}.inject { |x,y| x + y }
      end

      def final_piece?
        index_length == @index.size + 1
      end

      def make_index
        @piece = Piece.new(@piece_length)
        @files.each do |file|
          path = "#{@folder}/#{file['path'].join('/')}"
          offset = 0
          if @piece.tally != 0
            if @piece.left > file['length']
              @piece.add(0...file['length'], path)
            else
              offset = @piece.left
              @piece.add(0...@piece.left, path)
            end

            @index << @piece if @piece.full?
          else
            offset = 0
          end

          while offset < ((file['length']) - @piece_length)
            @piece = Piece.new(@piece_length)
            @piece.add(offset...(offset += @piece_length), path)
            @index << @piece if @piece.full?
          end

          if @piece.full? && offset > 0
            @piece = Piece.new(@piece_length)
            @piece.add(offset...file['length'], path)
          end

          if final_piece?
            @index << @piece
          end
        end
        set_hash
      end

      def set_hash
        0.upto(@index.size - 1) do |i|
          @index[i].hash = piece_hash(i)
          @index[i].index = i
        end

        return @index
      end

      def piece_hash(n)
        @sha_hashes[(n * 20)...(n * 20) + 20]
      end
    end
  end
end