require 'bencode'
require 'pry'
require 'digest/sha1'
require 'net/http'
require 'minitest/autorun'
require '../lib/torrenter/constants.rb'
require '../lib/torrenter/torrent_reader.rb'
require '../lib/torrenter/torrent_reader/piece_constructor.rb'
require '../lib/torrenter/torrent_reader/piece.rb'
require '../lib/torrenter/torrent_reader/piece_index.rb'

class TestPieceConstructor < Minitest::Test
  def setup
    files = [{'length' => 1235, 'path' => ["somefile.mp3"]}, {'length' => 21, 'path' => ["poo.jpg"] }]
    piece_length = 1024
    hashes = Digest::SHA1.digest('randomset') + Digest::SHA1.digest('lucbesson')
    folder = "myfavoritemusicalbumofalltime"
    @constructor = Torrenter::TorrentReader::PieceConstructor.new(files, folder, hashes, piece_length)
    @index = @constructor.make_index
  end

  def test_index_length
    assert @constructor.index_length == 2
  end

  def test_piece_index_size
    assert @index.size == @constructor.index_length
  end

  def test_piece_index_contains_piece_objects
    assert_instance_of Torrenter::TorrentReader::Piece, @index[0]
  end

  def test_sha_hashing_function
    assert @constructor.piece_hash(0) == Digest::SHA1.digest('randomset')
  end
end