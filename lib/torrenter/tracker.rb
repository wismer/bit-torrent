  module Torrenter
  class Tracker
    def format_peers(peers)
      pool = []
      peers.chars.each_slice(6) do |peer_data|
        ip = peer_data[0..3].join('').bytes.join('.')
        port = peer_data[4..5].join('').unpack("S>").first

        if !pool.find { |peer| peer.ip == ip }
          pool << Peer.new(ip, port, @params)
        end
      end

      return pool
    end
  end
end