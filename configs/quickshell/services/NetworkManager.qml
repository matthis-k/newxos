pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

Singleton {
    id: nm
    property var networks: [] // [{ssid,bssid,security,strength,inUse,icon}]
    property var active: [] // [{name,uuid,device,icon}]
    property string managerState: "" // connected|connecting|disconnected|...
    property bool busy: false
    property string lastError: ""
    property bool monitorEnabled: true

    readonly property var currentNetwork: {
        for (let i = 0; i < networks.length; ++i) {
            if (networks[i].inUse)
                return networks[i];
        }
        return null;
    }

    function refresh() {
        _listWifi();
        _readState();
        _readActive();
    }
    function scan() {
        _run(["nmcli", "device", "wifi", "rescan"], () => refresh());
    }

    function connectOpen(ssid) {
        connect(ssid, "");
    }
    function connectPsk(ssid, password) {
        connect(ssid, password);
    }
    function connect(ssid, password) {
        if (!ssid) {
            lastError = "ssid required";
            return;
        }
        busy = true;
        lastError = "";
        const args = ["nmcli", "device", "wifi", "connect", ssid];
        if (password && password.length)
            args.push("password", password);
        _run(args, (ok, out, err) => {
            busy = false;
            if (!ok)
                lastError = err || out || "connect failed";
            refresh();
        });
    }

    function connectBssid(ssid, password, bssid) {
        if (!ssid || !bssid) {
            lastError = "ssid+bssid required";
            return;
        }
        busy = true;
        lastError = "";
        const args = ["nmcli", "device", "wifi", "connect", ssid, "bssid", bssid];
        if (password && password.length)
            args.push("password", password);
        _run(args, (ok, out, err) => {
            busy = false;
            if (!ok)
                lastError = err || out || "connect failed";
            refresh();
        });
    }

    // WPA‑EAP (802.1x) — creates a saved connection then activates it.
    // opts: { eap: "peap"|"tls"|"ttls", phase2: "mschapv2"|"pap"|..., anonId, caCert, clientCert, privateKey, privateKeyPass, ifname }
    function connectEap(ssid, identity, password, opts) {
        if (!ssid || !identity) {
            lastError = "ssid+identity required";
            return;
        }
        busy = true;
        lastError = "";
        const name = `${ssid} (eap)`;
        const ifn = opts && opts.ifname ? opts.ifname : "*";
        const eap = (opts && opts.eap) ? opts.eap : "peap";
        const phase2 = (opts && opts.phase2) ? opts.phase2 : "mschapv2";
        const args = ["nmcli", "connection", "add", "type", "wifi", "con-name", name, "ifname", ifn, "ssid", ssid, "802-11-wireless-security.key-mgmt", "wpa-eap", "802-1x.eap", eap, "802-1x.identity", identity];

        if (opts && opts.anonId) {
            args.push("802-1x.anonymous-identity", opts.anonId);
        }
        if (eap === "tls") {
            if (opts && opts.caCert) {
                args.push("802-1x.ca-cert", opts.caCert);
            }
            if (opts && opts.clientCert) {
                args.push("802-1x.client-cert", opts.clientCert);
            }
            if (opts && opts.privateKey) {
                args.push("802-1x.private-key", opts.privateKey);
            }
            if (opts && opts.privateKeyPass) {
                args.push("802-1x.private-key-password", opts.privateKeyPass);
            }
        } else {
            if (password && password.length)
                args.push("802-1x.password", password);
            args.push("802-1x.phase2-auth", phase2);
        }

        _run(args, (ok, out, err) => {
            if (!ok) {
                busy = false;
                lastError = err || out || "create eap connection failed";
                return;
            }
            _run(["nmcli", "connection", "up", "id", name], (ok2, out2, err2) => {
                busy = false;
                if (!ok2)
                    lastError = err2 || out2 || "connection up failed";
                refresh();
            });
        });
    }

    function disconnect(idOrUuidOrSsid) {
        if (!idOrUuidOrSsid)
            return;
        busy = true;
        lastError = "";
        _run(["nmcli", "con", "down", "id", idOrUuidOrSsid], ok => {
            if (ok) {
                busy = false;
                refresh();
                return;
            }
            _run(["nmcli", "device", "disconnect", idOrUuidOrSsid], () => {
                busy = false;
                refresh();
            });
        });
    }

    function listSavedConnections(cb) {
        _run(["nmcli", "-t", "--escape", "yes", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"], (ok, out, err) => {
            if (!ok) {
                if (cb)
                    cb([]);
                return;
            }
            const rows = out.trim().split("\n").filter(Boolean);
            const items = rows.map(raw => {
                const p = nmcliSplit(raw);
                const name = nmcliUnescape(p[0] || "");
                const uuid = nmcliUnescape(p[1] || "");
                const type = nmcliUnescape(p[2] || "");
                const device = nmcliUnescape(p[p.length - 1] || "");
                const icon = _iconFor({
                    security: type,
                    strength: 100
                });
                return {
                    name,
                    uuid,
                    type,
                    device,
                    icon
                };
            });
            if (cb)
                cb(items);
        });
    }
    function removeConnection(nameOrUuid, cb) {
        _run(["nmcli", "connection", "delete", "id", nameOrUuid], (ok, out, err) => {
            if (cb)
                cb(ok, out, err);
            refresh();
        });
    }

    function wifiOn(cb) {
        _run(["nmcli", "radio", "wifi", "on"], () => {
            if (cb)
                cb();
        });
    }

    Timer {
        id: monitorDebounce
        interval: 600
        repeat: false
        onTriggered: nm.refresh()
    }
    Process {
        id: monitorProc
        running: nm.monitorEnabled
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: monitorDebounce.restart()
        }
    }

    function nmcliSplit(line) {
        const out = [];
        let cur = "";
        let esc = false;
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (esc) {
                if (ch === 'n')
                    cur += '\n';
                else if (ch === 't')
                    cur += '\t';
                else
                    cur += ch;
                esc = false;
            } else if (ch === '\\') {
                esc = true;
            } else if (ch === ':') {
                out.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        out.push(cur);
        return out;
    }
    function nmcliUnescape(s) {
        return s.replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\:/g, ":").replace(/\\\\/g, "\\");
    }
    function _iconFor(obj) {
        const s = obj.strength || 0;
        const sec = (obj.security || "").toLowerCase();
        const lock = sec.includes("wpa") || sec.includes("wep") || sec.includes("eap");
        const bars = Math.min(4, Math.floor(s / 25));
        const bartext = ["none", "weak", "ok", "good", "excellent"][bars];
        return `network-wireless${lock ? /* "-secure" */ "" : ""}-signal-${bartext}-symbolic`;
    }

    Process {
        id: runner
        property var _cb: null
        onExited: code => {
            const ok = (code === 0);
            const out = stdoutCollector.text;
            const err = stderrCollector.text;
            const fn = _cb;
            _cb = null;
            stdoutCollector.waitForEnd = true;
            stderrCollector.waitForEnd = true;
            if (typeof fn === "function")
                fn(ok, out, err);
        }
        stdout: StdioCollector {
            id: stdoutCollector
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: stderrCollector
            waitForEnd: true
        }
    }
    function _run(argv, cb) {
        runner._cb = cb;
        runner.command = argv;
        runner.running = true;
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
            onStreamFinished: {
                const rows = (text || "").trim().split("\n").filter(Boolean);
                const items = [];
                for (let raw of rows) {
                    const parts = nmcliSplit(raw);
                    if (parts.length < 5)
                        continue;
                    const inUse = parts[0] === "*";
                    const ssid = nmcliUnescape(parts[1]);
                    const bssid = nmcliUnescape(parts[2]);
                    const security = nmcliUnescape(parts[3]) || "open";
                    const strength = Number(parts[4]) || 0;
                    const freqRaw = nmcliUnescape(parts[5] || "");
                    let freqMHz = 0;
                    if (freqRaw) {
                        const m = freqRaw.match(/([\d.]+)/);
                        if (m) {
                            const val = Number(m[1]);
                            freqMHz = /ghz/i.test(freqRaw) ? Math.round(val * 1000) : Math.round(val);
                        }
                    }
                    const band = freqMHz >= 5925 ? "6GHz" : (freqMHz >= 4900 ? "5GHz" : (freqMHz > 0 ? "2.4GHz" : ""));
                    const icon = _iconFor({
                        security,
                        strength
                    });
                    items.push({
                        ssid,
                        bssid,
                        security,
                        strength,
                        inUse,
                        icon,
                        band
                    });
                }
                items.sort((a, b) => a.strength === b.strength ? a.ssid.localeCompare(b.ssid) : b.strength - a.strength);
                nm.networks = items;
            }
        }
    }
    function _listWifi() {
        listProc.command = ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,BSSID,SECURITY,SIGNAL,FREQ", "device", "wifi", "list", "--rescan", "no"];
        listProc.running = true;
    }

    Process {
        id: stateProc
        stdout: StdioCollector {
            id: stateOut
            waitForEnd: true
            onStreamFinished: nm.managerState = (text || "").trim()
        }
    }
    function _readState() {
        stateProc.command = ["nmcli", "-t", "--escape", "yes", "-f", "STATE", "general"];
        stateProc.running = true;
    }

    Process {
        id: activeProc
        stdout: StdioCollector {
            id: activeOut
            waitForEnd: true
            onStreamFinished: {
                const rows = (text || "").trim().split("\n").filter(Boolean);
                const items = rows.map(raw => {
                    const p = nmcliSplit(raw);
                    const name = nmcliUnescape(p[0] || "");
                    const uuid = nmcliUnescape(p[1] || "");
                    const device = nmcliUnescape(p[p.length - 1] || "");
                    const icon = _iconFor({
                        security: "",
                        strength: 100
                    });
                    return {
                        name,
                        uuid,
                        device,
                        icon
                    };
                });
                nm.active = items;
            }
        }
    }
    function _readActive() {
        activeProc.command = ["nmcli", "-t", "--escape", "yes", "-f", "NAME,UUID,DEVICE", "connection", "show", "--active"];
        activeProc.running = true;
    }

    Component.onCompleted: refresh()
}
