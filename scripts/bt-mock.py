#!/usr/bin/env python3
# A mock of BlueZ for trying the Bluetooth item without an adapter, from the bluez5 template of python-dbusmock. Run the mock on a private bus and give
# that bus to the shell as its system bus:
#
#   dbus-daemon --config-file=/run/current-system/sw/share/dbus-1/session.conf --address=unix:path=/tmp/lab-sysbus --fork
#   DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/lab-sysbus python3 -m dbusmock --system -t bluez5 &
#   python3 scripts/bt-mock.py setup
#   DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/lab-sysbus NSHELL_PATH=$PWD nshell
#
# setup adds the adapter hci0 and four devices: a pair of headphones that are paired and connected, with a battery, a keyboard that is paired, a mouse that
# is in range, and a phone in range. Other commands: connect, disconnect and pair take the address of a device, off and on turn the adapter off and on.
# What it cannot do: ask for a code or a confirmation of a pairing, which is the work of an agent that the shell does not have
import sys, dbus
bus = dbus.bus.BusConnection("unix:path=/tmp/lab-sysbus")
BZ = "org.bluez"
mock = dbus.Interface(bus.get_object(BZ, "/org/bluez"), "org.bluez.Mock")
cmd = sys.argv[1] if len(sys.argv) > 1 else "setup"
DEVICES = [("AA:00:00:00:00:01", "Studio Headphones"),
           ("AA:00:00:00:00:02", "Desk Keyboard"),
           ("AA:00:00:00:00:03", "Travel Mouse"),
           ("AA:00:00:00:00:04", "Test Phone")]
if cmd == "setup":
    mock.AddAdapter("hci0", "mock-laptop")
    # the template has no filter of the discovery and fails without one
    dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0"), "org.bluez.Adapter1").SetDiscoveryFilter({})
    for addr, alias in DEVICES:
        mock.AddDevice("hci0", addr, alias)
    for addr in ("AA:00:00:00:00:01", "AA:00:00:00:00:02"):
        mock.PairDevice("hci0", addr)
    # through the device itself: the ConnectDevice of the mock leaves the device in a state that its own Disconnect refuses
    dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0/dev_AA_00_00_00_00_01"), "org.bluez.Device1").Connect()
    # and the stored value, which the Connect of the mock does not set, for a shell that starts after it
    dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0/dev_AA_00_00_00_00_01"), "org.freedesktop.DBus.Properties").Set("org.bluez.Device1", "Connected", dbus.Boolean(True))

    # the battery of the headphones, as BlueZ has it: the interface Battery1 of the device
    o = dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0/dev_AA_00_00_00_00_01"), "org.freedesktop.DBus.Mock")
    o.AddProperties("org.bluez.Battery1", {"Percentage": dbus.Byte(80)})
    print("set up")
elif cmd in ("connect", "disconnect", "pair"):
    {"connect": mock.ConnectDevice, "disconnect": mock.DisconnectDevice, "pair": mock.PairDevice}[cmd]("hci0", sys.argv[2])
elif cmd == "failpair":
    # the pairing of a device that asks for what the shell cannot give: it fails as BlueZ does without an agent
    o = dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0/dev_" + sys.argv[2].replace(":", "_")), "org.freedesktop.DBus.Mock")
    o.AddMethod("org.bluez.Device1", "Pair", "", "",
                "raise dbus.exceptions.DBusException('Authentication Failed', name='org.bluez.Error.AuthenticationFailed')")
elif cmd in ("off", "on"):
    p = dbus.Interface(bus.get_object(BZ, "/org/bluez/hci0"), "org.freedesktop.DBus.Properties")
    p.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(cmd == "on"))
