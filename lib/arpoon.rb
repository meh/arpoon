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
require 'eventmachine'
require 'stringio'

require 'arpoon/table'
require 'arpoon/route'
require 'arpoon/interface'
require 'arpoon/packet'
require 'arpoon/controller'

class Arpoon
	include Singleton

	def self.method_missing (*args, &block)
		instance.__send__ *args, &block
	end

	attr_reader :interfaces

	def initialize
		@commands    = {}
		@connections = []
		@interfaces  = {}
		@any         = []

		reload_table!

		any {
			on :packet do |packet|
				if packet.request?
					packet.interface.fire :request, packet, packet.interface
				else
					packet.interface.fire :reply, packet, packet.interface
				end

				if packet.destination.broadcast?
					packet.interface.fire :broadcast, packet, packet.interface
				end
			end
		}

		controller_at '/var/run/arpoon.ctl'
		logs_at       '/var/log/arpoon.log'
	end

	def controller_at (path)
		@controller_at = File.expand_path(path)
	end

	def logs_at (path)
		@logs_at = File.expand_path(path)
	end
	def started?; @started; end

	def log (what, group = nil)
		io = StringIO.new

		io.print "[#{Time.now}#{", #{group}" if group}] "

		if what.is_a? Exception
			io.puts "#{what.class.name}: #{what.message}"
			io.puts what.backtrace
		else
			io.puts what
		end

		io.puts ''
		io.seek 0

		io.read.tap {|text|
			$stderr.puts text

			File.open(@logs_at, 'a') { |f| f.print text }
		}
	end

	def start
		return if started?

		@started = true

		@interfaces.each_value {|interface|
			interface.start
		}

		File.umask(0).tap {|old|
			begin
				@signature = EM.start_server(@controller_at, Controller)
			ensure
				File.umask(old)
			end
		}
	end

	def stop
		return unless started?

		@interfaces.each_value {|interface|
			interface.stop
		}

		if @signature
			EM.stop_server @signature
		end

		@started = false
	end

	def table
		@table || reload_table!
	end

	def reload_table!
		@table = Table.new
	end

	def route
		Route.new
	end

	def load (path = nil, &block)
		if path
			instance_eval File.read(File.expand_path(path)), path, 1
		else
			instance_exec &block
		end

		self
	end

	def connected (controller)
		@connections << controller
	end

	def disconnected (controller)
		@connections.delete(controller)
	end

	def broadcast (*args)
		@connections.each {|conn|
			conn.send_response(*args)
		}
	end

	def command (*args, &block)
		if block
			command = args.first.to_sym

			@commands[command] = block
		else
			controller = args.shift
			command    = args.shift

			controller.instance_exec *args, &@commands[command.to_sym]
		end
	rescue Exception => e
		log e, "command: #{command}"
	end

	def interface (name, &block)
		unless @interfaces.member? name
			@interfaces[name] = Interface.new(name)

			@any.each {|block|
				@interfaces[name].load(&block)
			}

			EM.schedule {
				@interfaces[name].start if started?
			}
		end

		@interfaces[name].load(&block) if block
		@interfaces[name]
	end

	def any (&block)
		@interfaces.each_value {|interface|
			interface.load(&block)
		}

		@any << block
	end
end
