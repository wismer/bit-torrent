module Torrenter
  PEER_ID  = '-MATT16548651231825-'
  BLOCK = 2**14
  KEEP_ALIVE = "\x00\x00\x00\x00"
  INTERESTED = "\x01"
  HANDSHAKE  = "T"
  HAVE       = "\x04"
  BITFIELD   = "\x05"
  PIECE      = "\a"
  CHOKE      = "\x00"
  PROTOCOL = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00"
end