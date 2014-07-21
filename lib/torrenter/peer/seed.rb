module Torrenter
  class Peer
    class Seed
      def initialize
        @server = TCPServer.new(6881)
      end

      def server_loop
        begin
          Thread.start(@server.accept_nonblock) do |client|
            binding.pry if client
          end
        rescue IO::EAGAINWaitReadable
        end
      end
    end
  end
end