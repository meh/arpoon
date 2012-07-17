#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'singleton'

require 'arpoon/table'
require 'arpoon/interface'
require 'arpoon/packet'

class Arpoon
	include Singleton

	def self.method_missing (*args, &block)
		instance.__send__ *args, &block
	end

	attr_reader :interfaces

	def initialize
		@interfaces = {}
		@any        = []

		reload_table!

		any {
			on :packet do |packet|
				if packet.request?
					packet.interface.fire :request, packet
				else
					packet.interface.fire :reply, packet
				end

				if packet.destination.broadcast?
					packet.interface.fire :broadcast, packet
				end
			end
		}
	end

	def start
		@interfaces.each_value {|interface|
			interface.wait
		}
	end

	def stop
		@interfaces.each_value {|interface|
			interface.stop_capturing!
		}
	end

	def table
		@table || reload_table!
	end

	def reload_table!
		@table = Table.new
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path
		else
			instance_exec &block
		end

		self
	end

	def interface (name, &block)
		unless @interfaces.member? name
			@interfaces[name] = Interface.new(name)

			@any.each {|block|
				@interfaces[name].load(&block)
			}
			
			@interfaces[name].start_capturing!
		end

		@interfaces[name].load(&block) if block
	end

	def any (&block)
		@interfaces.each_value {|interface|
			interface.load(&block)
		}

		@any << block
	end
end
