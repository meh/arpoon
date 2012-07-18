arpoon - man the harpoons, kill that ARP whale
==============================================
arpoon is a simple daemon that notifies about ARP packets, it can be used to implement
anti ARP spoofing stuff or whatever.


Examples
--------

Anti ARP spoofing:

```ruby
gateways = {}
danger   = []

# command that gets the interface name that got connected,
# it's gonna be used as hook for network managers and the like
# to tell arpoon about new interfaces or reconnected interfaces
command :connected do |name|
	interface(name) # create the interface if it's not present yet

	reload_table! # reload the ARP table

	# get the ARP table entry for the gateway and cleanup danger notifications
	gateways[interface] = table[gateway_for(name)]

  command :disconnected, name
end

command :disconnected do |name|
	danger.reject! { |a| a[0] == name }
end

# this command can be used by scripts to check for danger notifications and show
# them to the user
command :danger? do
	send_response danger.map { |a, b| { interface: a, attacker: b } }
end

# for any interface, already present or newly created
any do
	# when we receive an ARP reply
	on :reply do |packet, interface|
		# return unless we have a gateway for the interface
		next unless gateway = gateways[interface.name]

		# if the packet saying the IP for the gateway has a different MAC
		# address someone is doing something fishy, so notify the danger
		if packet.sender.ip == gateway.ip && packet.sender.mac != gateway.mac
			unless danger.include?(current = [interface.name, packet.sender.mac])
				danger << current
			end
		end
	end
end

# setup the already present devices and gateways
route.each {|entry|
	next unless entry.gateway?

	interface(entry.device)
	gateways[entry.device] = table[entry.gateway]
}
```

Init scripts
------------

Arch Linux:

```sh
#! /bin/bash

. /etc/rc.conf
. /etc/rc.d/functions

case "$1" in
  start)
    stat_busy "Starting arpoon"
    pkill -f "ruby.*arpoon" &> /dev/null
    arpoon &> /dev/null &
    add_daemon arpoon
    stat_done
    ;;

  stop)
    stat_busy "Stopping arpoon"
    pkill -f "ruby.*arpoon" &> /dev/nunll
    rm_daemon arpoon
    stat_done
    ;;

  restart)
    $0 stop
    sleep 1
    $0 start
    ;;

  *)
    echo "usage: $0 {start|stop|restart}"
esac

exit 0
```
