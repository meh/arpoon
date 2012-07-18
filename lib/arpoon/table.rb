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
require 'hwaddr'
require 'bitmap'

class Arpoon

class Table
	Types = {
		0  => :netrom,
		1  => :ether,
		2  => :eether,
		3  => :ax25,
		4  => :pronet,
		5  => :chaos,
		6  => :ieee802,
		7  => :arcnet,
		8  => :appletlk,
		15 => :dlci,
		19 => :atm,
		23 => :metricom,
		24 => :ieee1394,
		27 => :eui64,
		32 => :infiniband
	}

	Flags = Bitmap.new(
		completed: 0x02,
		permanent: 0x04,
		publish:   0x08,

		has_requested_trailers: 0x10,
		wants_netmask:          0x20,

		dont_publish: 0x40
	)

	class Entry < Struct.new(:ip, :type, :flags, :mac, :mask, :device)
		def ip
			IPAddr.new(super)
		end

		def mac
			HWAddr.new(super)
		end

		def type
			Types[super.to_i(16)]
		end

		def flags
			Flags[super.to_i(16)]
		end

		Flags.fields.each {|name|
			define_method "#{name}?" do
				flags.has? name
			end
		}
	end

	include Enumerable

	def initialize
		@entries = []

		File.open('/proc/net/arp', 'r').each_line {|line|
			next if line.start_with? 'IP address'

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

	def [] (what)
		find {|entry|
			what == entry.ip || what == entry.mac
		}
	end
end

end
