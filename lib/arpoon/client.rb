#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'socket'
require 'json'

class Arpoon

class Client
	def initialize (path = '/var/run/arpoon.ctl')
		@socket = UNIXSocket.new(File.expand_path(path))
	end

	def respond_to_missing? (*args)
		@socket.respond_to? *args
	end

	def method_missing (*args, &block)
		@socket.__send__ *args, &block
	end

	def send_request (name, *args)
		self.puts [name, args].to_json
	end

	def read_response
		JSON.parse(?[ + self.readline + ?]).first
	end
end

end
