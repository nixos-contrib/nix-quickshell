#!/bin/sh
# The state of the wired interface, for the network item of the bar when NetworkManager is not there, as key=value lines. $1 is the interface that
# the user chose, or none: then it is the one of the default route, if that is a card of the machine, and otherwise the first card with a cable. The
# interfaces of Tailscale, Docker, a bridge or a VPN have no device behind them, so they are not the connection of the machine
dev="$1"
if [ -z "$dev" ]; then
	dev="$(ip route show default 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }')"
	[ -n "$dev" ] && [ ! -e "/sys/class/net/$dev/device" ] && dev=""
fi
if [ -z "$dev" ]; then
	for d in /sys/class/net/*; do
		n="${d##*/}"
		# a card, that is not wireless, and an ethernet one
		if [ -e "$d/device" ] && [ ! -e "$d/wireless" ] && [ "$(cat "$d/type" 2>/dev/null)" = 1 ]; then
			dev="$n"
			break
		fi
	done
fi
[ -n "$dev" ] || exit 0
d="/sys/class/net/$dev"
[ -d "$d" ] || exit 0
printf 'iface=%s\n' "$dev"
printf 'state=%s\n' "$(cat "$d/operstate" 2>/dev/null)"
printf 'carrier=%s\n' "$(cat "$d/carrier" 2>/dev/null)"
printf 'speed=%s\n' "$(cat "$d/speed" 2>/dev/null)"
printf 'mac=%s\n' "$(cat "$d/address" 2>/dev/null)"
printf 'address=%s\n' "$(ip -4 -o addr show dev "$dev" 2>/dev/null | awk '{ print $4; exit }')"
printf 'gateway=%s\n' "$(ip route show default dev "$dev" 2>/dev/null | awk '{ print $3; exit }')"
