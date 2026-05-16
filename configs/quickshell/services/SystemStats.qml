pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuPercent: 0
    property real memoryPercent: 0
    property real swapPercent: 0
    property real rootDiskPercent: 0
    property real rxBytesPerSecond: 0
    property real txBytesPerSecond: 0
    property int memoryUsedMiB: 0
    property int memoryTotalMiB: 0
    property int swapUsedMiB: 0
    property int swapTotalMiB: 0
    property int rootUsedGiB: 0
    property int rootTotalGiB: 0
    property string primaryInterface: ""

    property var diskPartitions: []
    property real _lastDiskUpdateMs: 0

    property real _lastCpuTotal: 0
    property real _lastCpuIdle: 0
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property double _lastSampleMs: 0

    // Per-CPU tracking
    property var cpuCorePercents: []
    property var _lastCpuCoreTotals: []
    property var _lastCpuCoreIdles: []

    // History buffer for graphs (60 samples at 2s interval = 2 minutes)
    property int historyMaxSamples: 60
    property var cpuHistory: []
    property var cpuCoreHistory: []
    property double _lastHistorySampleMs: 0

    function formatRate(bytesPerSecond) {
        const absValue = Math.abs(bytesPerSecond || 0);
        if (absValue >= 1024 * 1024)
            return `${(bytesPerSecond / (1024 * 1024)).toFixed(1)} MiB/s`;
        if (absValue >= 1024)
            return `${(bytesPerSecond / 1024).toFixed(1)} KiB/s`;
        return `${Math.round(bytesPerSecond || 0)} B/s`;
    }

    function pushToHistory(historyArray, value) {
        historyArray.push(value);
        if (historyArray.length > root.historyMaxSamples)
            historyArray.shift();
    }

    function applySample(text) {
        const sample = {};
        const lines = (text || "").trim().split(/\n+/);
        let inDisks = false;
        sample.disks = [];
        
        for (const line of lines) {
            if (line === 'disks') {
                inDisks = true;
                continue;
            }
            
            const parts = line.trim().split(/\s+/);
            if (parts.length < 2)
                continue;
            
            if (inDisks) {
                sample.disks.push(parts);
            } else {
                sample[parts[0]] = parts.slice(1);
            }
        }

        // Parse total CPU
        if (sample.cpu && sample.cpu.length >= 2) {
            const cpuTotal = parseFloat(sample.cpu[0]);
            const cpuIdle = parseFloat(sample.cpu[1]);
            if (!isNaN(cpuTotal) && !isNaN(cpuIdle)) {
                const totalDelta = cpuTotal - _lastCpuTotal;
                const idleDelta = cpuIdle - _lastCpuIdle;
                if (_lastCpuTotal > 0 && totalDelta > 0)
                    cpuPercent = Math.max(0, Math.min(100, ((totalDelta - idleDelta) / totalDelta) * 100));
                _lastCpuTotal = cpuTotal;
                _lastCpuIdle = cpuIdle;
            }
        }

        // Parse per-CPU cores
        if (sample.cpu0) {
            const coreCount = Object.keys(sample).filter(k => k.startsWith('cpu') && k !== 'cpu' && !isNaN(k.charAt(3))).length;
            const newCorePercents = [];
            const newLastTotals = [];
            const newLastIdles = [];

            for (let i = 0; i < coreCount; i++) {
                const key = `cpu${i}`;
                if (sample[key] && sample[key].length >= 2) {
                    const coreTotal = parseFloat(sample[key][0]);
                    const coreIdle = parseFloat(sample[key][1]);
                    
                    if (_lastCpuCoreTotals[i] !== undefined && _lastCpuCoreTotals[i] > 0) {
                        const totalDelta = coreTotal - _lastCpuCoreTotals[i];
                        const idleDelta = coreIdle - _lastCpuCoreIdles[i];
                        if (totalDelta > 0) {
                            const corePercent = Math.max(0, Math.min(100, ((totalDelta - idleDelta) / totalDelta) * 100));
                            newCorePercents.push(corePercent);
                        } else {
                            newCorePercents.push(0);
                        }
                    } else {
                        newCorePercents.push(0);
                    }
                    
                    newLastTotals.push(coreTotal);
                    newLastIdles.push(coreIdle);
                }
            }

            cpuCorePercents = newCorePercents;
            _lastCpuCoreTotals = newLastTotals;
            _lastCpuCoreIdles = newLastIdles;
        }

        if (sample.mem && sample.mem.length >= 2) {
            const usedKiB = parseFloat(sample.mem[0]);
            const totalKiB = parseFloat(sample.mem[1]);
            if (!isNaN(usedKiB) && !isNaN(totalKiB) && totalKiB > 0) {
                memoryUsedMiB = Math.round(usedKiB / 1024);
                memoryTotalMiB = Math.round(totalKiB / 1024);
                memoryPercent = (usedKiB / totalKiB) * 100;
            }
        }

        if (sample.swap && sample.swap.length >= 2) {
            const usedKiB = parseFloat(sample.swap[0]);
            const totalKiB = parseFloat(sample.swap[1]);
            if (!isNaN(usedKiB) && !isNaN(totalKiB)) {
                swapUsedMiB = Math.round(usedKiB / 1024);
                swapTotalMiB = Math.round(totalKiB / 1024);
                swapPercent = totalKiB > 0 ? (usedKiB / totalKiB) * 100 : 0;
            }
        }

        if (sample.disk && sample.disk.length >= 2) {
            const usedKiB = parseFloat(sample.disk[0]);
            const totalKiB = parseFloat(sample.disk[1]);
            if (!isNaN(usedKiB) && !isNaN(totalKiB) && totalKiB > 0) {
                rootUsedGiB = Math.round(usedKiB / (1024 * 1024));
                rootTotalGiB = Math.round(totalKiB / (1024 * 1024));
                rootDiskPercent = (usedKiB / totalKiB) * 100;
            }
        }

        if (sample.disks) {
            const newPartitions = [];
            for (let i = 0; i < sample.disks.length; i++) {
                const parts = sample.disks[i];
                if (parts && parts.length >= 3) {
                    const mountPoint = parts[0];
                    const usedKiB = parseFloat(parts[1]);
                    const totalKiB = parseFloat(parts[2]);
                    if (!isNaN(usedKiB) && !isNaN(totalKiB) && totalKiB > 0) {
                        const percent = (usedKiB / totalKiB) * 100;
                        newPartitions.push({
                            mount: mountPoint,
                            usedGiB: Math.round(usedKiB / (1024 * 1024)),
                            totalGiB: Math.round(totalKiB / (1024 * 1024)),
                            percent: Math.round(percent)
                        });
                    }
                }
            }
            diskPartitions = newPartitions;
        }

        if (sample.net && sample.net.length >= 3) {
            const iface = sample.net[0];
            const rxBytes = parseFloat(sample.net[1]);
            const txBytes = parseFloat(sample.net[2]);
            const now = Date.now();
            const elapsedSeconds = _lastSampleMs > 0 ? Math.max((now - _lastSampleMs) / 1000, 0.001) : 0;

            primaryInterface = iface === "none" ? "" : iface;

            if (!isNaN(rxBytes) && !isNaN(txBytes)) {
                if (_lastSampleMs > 0) {
                    rxBytesPerSecond = Math.max(0, (rxBytes - _lastRxBytes) / elapsedSeconds);
                    txBytesPerSecond = Math.max(0, (txBytes - _lastTxBytes) / elapsedSeconds);
                }
                _lastRxBytes = rxBytes;
                _lastTxBytes = txBytes;
                _lastSampleMs = now;
            }
        }

        // Push to history every 2 seconds
        const now = Date.now();
        if (_lastHistorySampleMs === 0 || (now - _lastHistorySampleMs) >= 2000) {
            pushToHistory(cpuHistory, cpuPercent);
            
            if (cpuCoreHistory.length === 0 || cpuCoreHistory[0] === undefined) {
                cpuCoreHistory = cpuCorePercents.map(p => [p]);
            } else {
                for (let i = 0; i < cpuCorePercents.length; i++) {
                    if (cpuCoreHistory[i]) {
                        cpuCoreHistory[i].push(cpuCorePercents[i]);
                        if (cpuCoreHistory[i].length > root.historyMaxSamples)
                            cpuCoreHistory[i].shift();
                    } else {
                        cpuCoreHistory[i] = [cpuCorePercents[i]];
                    }
                }
            }
            
            _lastHistorySampleMs = now;
        }
    }

    function refresh() {
        collector.exec({
            command: [
                "sh",
                "-c",
                "read _ u n s i w irq sirq st g gn < /proc/stat; total=$((u+n+s+i+w+irq+sirq+st)); idle=$((i+w)); echo \"cpu $total $idle\"; idx=0; while read -r line; do case \"$line\" in cpu[0-9]*) set -- $line; u2=$2; n2=$3; s2=$4; i2=$5; w2=$6; irq2=$7; sirq2=$8; st2=$9; t2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2)); id2=$((i2+w2)); echo \"cpu${idx} $t2 $id2\"; idx=$((idx+1));; esac; done < /proc/stat; mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo); mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo); swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo); swap_free=$(awk '/SwapFree/ {print $2}' /proc/meminfo); iface=$(awk -F: '$1 !~ /lo/ {gsub(/ /, \"\", $1); print $1; exit}' /proc/net/dev); if [ -n \"$iface\" ]; then set -- $(awk -F'[: ]+' -v iface=\"$iface\" '$1 == iface {print $3, $11}' /proc/net/dev); rx=$1; tx=$2; else iface=none; rx=0; tx=0; fi; set -- $(df -Pk / | awk 'NR==2 {print $2, $3}'); disk_total=$1; disk_used=$2; printf 'mem %s %s\\nswap %s %s\\nnet %s %s %s\\ndisk %s %s\\n' \"$((mem_total-mem_available))\" \"$mem_total\" \"$((swap_total-swap_free))\" \"$swap_total\" \"$iface\" \"$rx\" \"$tx\" \"$disk_used\" \"$disk_total\"; echo 'disks'; df -Pk | awk 'NR>1 && $1 ~ /^\\/dev/ {printf \"%s %s %s\\n\", $6, $3, $2}'"
            ]
        });
    }

    Process {
        id: collector
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applySample(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
