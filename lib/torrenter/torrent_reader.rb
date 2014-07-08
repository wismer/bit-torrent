module Torrenter
  # torrent reader should only read the torrent file and return either
  # a UDP tracker object or an HTTP tracker object

  # what is being used or accessed by the torrent reader, and what is being used by the trackers?

  class TorrentReader
    attr_reader :stream, :pieces

    def initialize(file)
      @stream = BEncode.load_file(file)
      # @pieces = Peer::PieceIndex.new(piece_length)
    end

    def folder
      if multiple_files?
        @stream['info']['name']
      else
        @stream['info']['name'].gsub(/\.\w+$/, '')
      end
    end

    def info_hash
      Digest::SHA1.digest(@stream['info'].bencode)
    end

    def sha_hashes
      @stream['info']['pieces']
    end

    def total_file_size
      file_list.is_a?(Array) ? multiple_file_size : file_list['length']
    end

    def multiple_file_size
      file_list.map { |file| file['length'] }.inject { |x,y| x + y }
    end

    def piece_length
      @stream['info']['piece length']
    end

    def file_list
      if @stream['info']['files'].nil?
        [{ 'path' => [@stream['info']['name']], 'length' => @stream['info']['length'] }]
      else
        @stream['info']['files']
      end
    end

    def announce_url
      @stream['announce']
    end

    def announce_list
      @stream['announce-list']
    end

    def url_list
      announce_list ? announce_list.flatten << announce_url : [announce_url]
    end

    def multiple_files?
      file_list.size > 1
    end

    def write_paths
      file_list.each { |file| write_path(file) }
    end

    def write_path(file)
      file = "#{folder}/#{file['path'].join('/')}"
      if !Dir.exist?(File.dirname(file))
        FileUtils.mkdir_p(File.dirname(file))
      end
      IO.write(file, '', 0)
    end

    def piece_index
      constructor = PieceConstructor.new(file_list, folder, sha_hashes, piece_length)
      constructor.make_index
    end

    def tracker_params
      {
        :info_hash => info_hash,
        :peer_id   => PEER_ID,
        :left      => piece_length,
        :pieces    => file_list
      }
    end

    def connect_trackers
      url_list.compact.map do |url|
        tracker = if url.include?('http://')
          Tracker::HTTPTracker.new(url, tracker_params)
        else
          Tracker::UDPTracker.new(url, tracker_params)
        end

        tracker.connect
      end
    end
  end
end
