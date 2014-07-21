module Torrenter
  class Reactor

    def initialize(trackers, piece_index)
      @trackers    = trackers
      @piece_index = piece_index
    end

    def extract_peers
      @peers = @trackers.map { |tracker| tracker.peer_list if tracker.connected? }.flatten.compact
    end

    def message_reactor
      @piece_index.verify_status
      @peers.each { |peer| peer.connect unless active_peers.size > 5 }
      puts "You are now connected to #{active_peers.size} peers."
      loop do
        break if finished?
        @peers.each do |peer|
          if peer.peer_state
            peer.connection_state(@piece_index, have)
          else
            peer.connect if Time.now.to_i % ((active_peers.size * 10) + 1) == 0
          end
        end
        @piece_index.clean_peers
        $status = @piece_index.to_json
      end
    end

    def server_listen
    end

    def have
      ->(index, peer) { @piece_index[index].add_peer(peer) }
    end

    def finished?
      @piece_index.all?
    end

    def data_remaining
      (total_file_size - @byte_counter).fdiv(1024).fdiv(1024).round(2)
    end

    def active_peers
      @peers.select { |peer| peer.peer_state }
    end

    def index_percentages
      active_peers.map do |peer|
        size = peer.buffer.bytesize + peer.piece_size
        [peer.index, (size.fdiv @piece_length) * 100]
      end
    end

    def download_bar
      ("\u2588" * pieces(:downloaded)) + ("\u2593" * pieces(:downloading)) + (" " * pieces(:free)) + " %#{pieces(:downloaded)} downloaded "
    end

    def pieces(type)
      (@piece_index.count(type).fdiv(@piece_index.size) * 100).round
    end
  end
end