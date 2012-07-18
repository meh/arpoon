#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'ipaddr'
require 'bitmap'

class Arpoon

class Route
	Flags = Bitmap.new(
		up:      0x0001,
		gateway: 0x0002,

		host:         0x0004,
		reinstate:    0x0008,
		dynamic:      0x0010,
		modified:     0x0020,
		mtu:          0x0040,
		window:       0x0080,
		irtt:         0x0100,
		reject:       0x0200,
		static:       0x0400,
		xresolve:     0x0800,
		no_forward:   0x1000,
		throw:        0x2000,
		no_pmt_udisc: 0x4000,

		default:     0x00010000,
		all_on_link: 0x00020000,
		addrconf:    0x00040000,

		linkrt:      0x00100000,
		no_next_hop: 0x00200000,

		cache:  0x01000000,
		flow:   0x02000000,
		policy: 0x0400000
	)

	class Entry < Struct.new(:device, :destination, :gateway, :flags, :ref_count, :use, :metric, :mask, :mtu, :window, :irrt)
		def destination
			IPAddr.new_ntoh([super.to_i(16)].pack('N').reverse)
		end

		def gateway
			IPAddr.new_ntoh([super.to_i(16)].pack('N').reverse)
		end

		def flags
			Flags[super.to_i(16)]
		end

		Flags.fields.each {|name|
			define_method "#{name}?" do
				flags.has? name
			end
		}

		def ref_count
			super.to_i
		end

		def use?
			super != '0'
		end

		def metric?
			super != '0'
		end

		def mtu
			super.to_i
		end

		def window
			super.to_i
		end

		def irrt
			super.to_i
		end

		def default_gateway?
		end
	end

	include Enumerable

	def initialize
		@entries = []

		File.open('/proc/net/route', 'r').each_line {|line|
			next if line.start_with? 'Iface'

			@entries << Entry.new(*line.split(/\s+/))
		}
	end

	def each (device = nil)
		return enum_for :each, device unless block_given?

		@entries.each {|entry|
			yield entry if !device || device.to_s == entry.device
		}

		self
	end

	def gateway_for (device)
		each(device) {|entry|
			return entry.gateway if entry.gateway?
		}

		nil
	end
end

end
