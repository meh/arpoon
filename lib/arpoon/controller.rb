#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'eventmachine'
require 'json'

class Arpoon

class Controller < EventMachine::Protocols::LineAndTextProtocol
	def post_init
		connected self
	end

	def receive_line (line)
		command(self, *JSON.parse(line))
	end

	def method_missing (*args, &block)
		Arpoon.__send__(*args, &block)
	end

	def send_line (line)
		raise ArgumentError, 'the line already has a newline character' if line.include? "\n"

		send_data line.dup.force_encoding('BINARY') << "\r\n"
	end

	def send_response (*arguments)
		send_line (arguments.length == 1 ? arguments.first : arguments).to_json
	end

	def unbind
		disconnected self
	end
end

end
