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
	attr_reader :name, :capture

	def initialize (name, &block)
		@name   = name
		@events = Hash.new { |h, k| h[k] = [] }

		load &block if block
	end

	def start_capturing!
		@thread = Thread.new {
			@capture = FFI::PCap::Live.new(dev: @name.to_s, promisc: true, handler: FFI::PCap::Handler)
			@capture.setfilter('arp')

			@capture.loop {|_, packet|
				next unless packet = Packet.unpack(packet.body, self) rescue nil

				fire :packet, packet
			}
		}

		self
	end

	def stop_capturing!
		return unless @thread

		@capture.breakloop

		self
	end

	def wait
		@thread.join
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path
		else
			instance_exec &block
		end

		self
	end

	def on (name = :anything, &block)
		@events[name] << block
	end

	def fire (name, *args)
		[@events[:anything], @events[name]].each {|set|
			delete = []

			set.each {|block|
				case block.call(*args)
				when :delete then delete << block
				when :stop   then break
				end
			}

			set.reject! { |b| delete.include? b }
		}

		self
	end

	def inspect
		"#<#{self.class.name}: #{name}>"
	end
end

end
