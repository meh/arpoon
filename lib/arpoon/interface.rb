#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'ffi/pcap'

require 'arpoon/packet'

class Arpoon

class Interface
	class Handler < EM::Connection
		def initialize (interface)
			@interface = interface
		end

		def notify_readable (*)
			@interface.capture.dispatch {|_, packet|
				next unless packet = Packet.unpack(packet.body, @interface) rescue nil

				@interface.fire :packet, packet
			}
		end
	end

	attr_reader :name, :capture

	def initialize (name, &block)
		@name   = name.to_s
		@events = Hash.new { |h, k| h[k] = [] }

		load &block if block
	end

	def method_missing (*args, &block)
		Arpoon.__send__ *args, &block
	end

	def start
		@capture = FFI::PCap::Live.new(device: @name.to_s, promisc: true, handler: FFI::PCap::Handler)
		@capture.nonblocking = true
		@capture.setfilter('arp')

		@handler = EM.watch @capture.selectable_fd, Handler, self
		@handler.notify_readable = true

		self
	end

	def stop
		@handler.detach

		self
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path, 1
		else
			instance_exec &block
		end

		self
	end

	def on (name = :anything, &block)
		@events[name] << block
	end

	def fire (name, *args)
		delete = []

		@events[name].each {|block|
			case block.call(*args)
			when :delete then delete << block
			when :stop   then break
			end
		}

		@events[name] -= delete

		self
	end

	def to_s
		name
	end

	def to_sym
		name.to_sym
	end

	def inspect
		"#<#{self.class.name}: #{name}>"
	end
end

end
