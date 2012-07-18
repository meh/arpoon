#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'hwaddr'
require 'ipaddr'

class Arpoon

class Packet
	Operations = {
		1 => :request,
		2 => :reply
	}

	def self.unpack (data, interface = nil)
		source      = HWAddr.new(data[0, 6].unpack('C6'))
		destination = HWAddr.new(data[6, 6].unpack('C6'))

		unless data[12, 2].unpack('n').first == 0x0806
			raise ArgumentError, 'the passed data is not an ARP packet'
		end

		unless data[16, 2].unpack('n').first == 0x0800
			raise ArgumentError, 'the passed data is not using the IP protocol'
		end

		hw_size = data[18, 1].unpack('C').first
		pr_size = data[19, 1].unpack('C').first

		if hw_size != 6
			raise ArgumentError, "#{hw_size} is an unsupported size"
		end

		opcode = data[20, 2].unpack('n').first

		if pr_size == 4
			sender_hw = HWAddr.new(data[22, 6].unpack('C6'))
			sender_ip = IPAddr.new_ntoh(data[28, 4])

			target_hw = HWAddr.new(data[32, 6].unpack('C6'))
			target_ip = IPAddr.new_ntoh(data[38, 4])
		elsif pr_size == 16
			sender_hw = HWAddr.new(data[22, 6].unpack('C6'))
			sender_ip = IPAddr.new_ntoh(data[28, 16])

			target_hw = HWAddr.new(data[44, 6].unpack('C6'))
			target_ip = IPAddr.new_ntoh(data[50, 16])
		else
			raise ArgumentError, "#{pr_size} is an unsupported protocol size"
		end

		new(interface, source, destination, Operations[opcode], sender_hw, sender_ip, target_hw, target_ip)
	end

	attr_reader :interface, :source, :destination, :sender, :target

	def initialize (interface = nil, source, destination, operation, sender_hw, sender_ip, target_hw, target_ip)
		@interface   = interface
		@source      = source
		@destination = destination

		@operation = operation.downcase

		@sender = Struct.new(:mac, :ip).new(sender_hw, sender_ip)
		@target = Struct.new(:mac, :ip).new(target_hw, target_ip)
	end

	def request?
		@operation == :request
	end

	def reply?
		@operation == :reply
	end

	def to_sym
		@operation
	end
end

end
