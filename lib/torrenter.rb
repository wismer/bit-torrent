require 'socket'
require 'digest/sha1'
require 'bencode'
require 'fileutils'
require 'torrenter/constants'
require 'torrenter/peer'
require 'torrenter/peer/buffer_state'
require 'torrenter/reactor'
require 'torrenter/tracker'
require 'torrenter/tracker/http_tracker'
require 'torrenter/tracker/udp_tracker'
require 'torrenter/torrent_reader'
require 'torrenter/torrent_reader/piece'
require 'torrenter/torrent_reader/piece_index'
require 'torrenter/torrent_reader/piece_constructor'
require 'torrenter/version'

module Torrenter
  class Torrent

    def start(file)
      @torrent = Torrenter::TorrentReader.new(file)
      @torrent.write_paths

      trackers = @torrent.connect_trackers


      reactor = Reactor.new(trackers, @torrent.piece_index)
      reactor.extract_peers
      reactor.message_reactor
    end
  end
end
