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

    property real _lastCpuTotal: 0
    property real _lastCpuIdle: 0
    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property double _lastSampleMs: 0

    function formatRate(bytesPerSecond) {
        const absValue = Math.abs(bytesPerSecond || 0);
        if (absValue >= 1024 * 1024)
            return `${(bytesPerSecond / (1024 * 1024)).toFixed(1)} MiB/s`;
        if (absValue >= 1024)
            return `${(bytesPerSecond / 1024).toFixed(1)} KiB/s`;
        return `${Math.round(bytesPerSecond || 0)} B/s`;
    }

    function applySample(text) {
        const sample = {};
        for (const line of (text || "").trim().split(/\n+/)) {
            const parts = line.trim().split(/\s+/);
            if (parts.length < 2)
                continue;
            sample[parts[0]] = parts.slice(1);
        }

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
    }

    function refresh() {
        collector.exec({
            command: [
                "sh",
                "-c",
                "read _ u n s i w irq sirq st g gn < /proc/stat; total=$((u+n+s+i+w+irq+sirq+st)); idle=$((i+w)); mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo); mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo); swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo); swap_free=$(awk '/SwapFree/ {print $2}' /proc/meminfo); iface=$(awk -F: '$1 !~ /lo/ {gsub(/ /, \"\", $1); print $1; exit}' /proc/net/dev); if [ -n \"$iface\" ]; then set -- $(awk -F'[: ]+' -v iface=\"$iface\" '$1 == iface {print $3, $11}' /proc/net/dev); rx=$1; tx=$2; else iface=none; rx=0; tx=0; fi; set -- $(df -Pk / | awk 'NR==2 {print $2, $3}'); disk_total=$1; disk_used=$2; printf 'cpu %s %s\\nmem %s %s\\nswap %s %s\\nnet %s %s %s\\ndisk %s %s\\n' \"$total\" \"$idle\" \"$((mem_total-mem_available))\" \"$mem_total\" \"$((swap_total-swap_free))\" \"$swap_total\" \"$iface\" \"$rx\" \"$tx\" \"$disk_used\" \"$disk_total\""
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
