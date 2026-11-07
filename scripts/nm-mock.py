#!/usr/bin/env python3
# A mock of NetworkManager for trying the network item without a radio. python-dbusmock has a template for it, written for NetworkManager 0.9, which
# Quickshell (1.x) needs a little more of: this script adds that, and a Wi-Fi device with access points of each kind. Run the mock on a private bus and
# give that bus to the shell as its system bus:
#
#   dbus-daemon --config-file=/run/current-system/sw/share/dbus-1/session.conf --address=unix:path=/tmp/lab-sysbus --fork
#   DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/lab-sysbus python3 -m dbusmock --system -t networkmanager &
#   python3 scripts/nm-mock.py setup && python3 scripts/nm-mock.py patch && python3 scripts/nm-mock.py fixaps
#   DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/lab-sysbus NSHELL_PATH=$PWD nshell
#
# Other commands: wired (a cable that is connected), airplane and airplane-off (the switch of the hardware), failjoin (joins fail). What it cannot do:
# a join that fails the way NetworkManager reports a wrong password, which needs an active connection that goes through its states
import sys, dbus
bus = dbus.bus.BusConnection("unix:path=/tmp/lab-sysbus")
NM = "org.freedesktop.NetworkManager"
obj = bus.get_object(NM, "/org/freedesktop/NetworkManager")
mock = dbus.Interface(obj, "org.freedesktop.DBus.Mock")
cmd = sys.argv[1] if len(sys.argv) > 1 else "setup"
if cmd == "setup":
    dev = mock.AddWiFiDevice("mock_wifi1", "wlan0", 30)       # disconnected
    print("device", dev)
    aps = [("Cafe Guest", "00:11:22:33:44:01", 80, 0),         # open, strong
           ("Home Network", "00:11:22:33:44:02", 62, 0x100),   # WPA2 with a key, medium
           ("Neighbour", "00:11:22:33:44:03", 25, 0x100),      # weak
           ("Office Corp", "00:11:22:33:44:04", 55, 0x200)]    # enterprise (802.1X)
    for i, (ssid, mac, strength, sec) in enumerate(aps):
        ap = mock.AddAccessPoint(dev, "mock_ap%d" % i, ssid, mac, 2, 2412, 54000, strength, sec)
        print("ap", ssid, ap)

if cmd == "patch":
    # what Quickshell asks of NetworkManager 1.x and the template of the mock, written for 0.9, does not have
    mock.AddMethod("org.freedesktop.NetworkManager", "GetAllDevices", "", "ao",
                   "ret = self.Get('org.freedesktop.NetworkManager', 'Devices')")
    print("added GetAllDevices")

if cmd == "patch":
    NMI = "org.freedesktop.NetworkManager"
    def add(path, iface, name, value):
        o = dbus.Interface(bus.get_object(NM, path), "org.freedesktop.DBus.Mock")
        try:
            o.AddProperty(iface, name, value)
        except Exception as e:
            print("skip", path.split("/")[-1], name, str(e)[:60])
    add("/org/freedesktop/NetworkManager", NMI, "ConnectivityCheckAvailable", dbus.Boolean(True))
    add("/org/freedesktop/NetworkManager", NMI, "ConnectivityCheckEnabled", dbus.Boolean(True))
    dev = "/org/freedesktop/NetworkManager/Devices/mock_wifi1"
    add(dev, NMI + ".Device", "HwAddress", "00:11:22:33:44:55")
    add(dev, NMI + ".Device", "Autoconnect", dbus.Boolean(True))
    add(dev, NMI + ".Device", "InterfaceFlags", dbus.UInt32(0))
    add(dev, NMI + ".Device.Wireless", "LastScan", dbus.Int64(0))
    print("added the properties of NetworkManager 1.x")

if cmd == "fixaps":
    # the flags of a real access point: WPA2 with a key is RsnFlags with CCMP and the key management PSK, 802.1X is the management of an organization
    PROPS = "org.freedesktop.DBus.Properties"
    APIF = "org.freedesktop.NetworkManager.AccessPoint"
    def setflags(n, flags, wpa, rsn):
        o = dbus.Interface(bus.get_object(NM, "/org/freedesktop/NetworkManager/AccessPoint/mock_ap%d" % n), PROPS)
        o.Set(APIF, "Flags", dbus.UInt32(flags))
        o.Set(APIF, "WpaFlags", dbus.UInt32(wpa))
        o.Set(APIF, "RsnFlags", dbus.UInt32(rsn))
    setflags(0, 0, 0, 0)            # open
    setflags(1, 1, 0, 0x188)        # WPA2-PSK
    setflags(2, 1, 0, 0x188)        # WPA2-PSK
    setflags(3, 1, 0, 0x288)        # WPA2-Enterprise
    dev = "/org/freedesktop/NetworkManager/Devices/mock_wifi1"
    try:
        dbus.Interface(bus.get_object(NM, dev), "org.freedesktop.DBus.Mock").AddProperty(
            "org.freedesktop.NetworkManager.Device.Wireless", "ActiveAccessPoint", dbus.ObjectPath("/"))
    except Exception as e:
        print("skip ActiveAccessPoint", str(e)[:60])
    print("the flags are set")

if cmd in ("airplane", "airplane-off"):
    p = dbus.Interface(obj, "org.freedesktop.DBus.Properties")
    p.Set(NM, "WirelessHardwareEnabled", dbus.Boolean(cmd == "airplane-off"))
    print("hardware radio", "on" if cmd == "airplane-off" else "off")
if cmd == "wired":
    print("eth", mock.AddEthernetDevice("mock_eth0", "enp9s0", 100))

if cmd == "failjoin":
    # a join that fails the way a wrong password does: the device goes to failed, with the reason that there were no secrets
    mock.AddMethod("org.freedesktop.NetworkManager", "AddAndActivateConnection", "a{sa{sv}}oo", "oo",
        "dev = objects[args[1]]\n"
        "dev.Set('org.freedesktop.NetworkManager.Device', 'State', dbus.UInt32(120))\n"
        "dev.EmitSignal('org.freedesktop.NetworkManager.Device', 'StateChanged', 'uuu', [120, 40, 7])\n"
        "ret = (dbus.ObjectPath('/'), dbus.ObjectPath('/'))\n")
    print("joins fail now")
