pragma Singleton
import QtQml
import "logger"

QtObject {
    id: root

    readonly property bool devMode: Config.behaviour.devMode

    property bool installed: Config.behaviour.loggerInstalled
        || devMode

    property int installedMaxLevel: Config.behaviour.loggerInstalledMaxLevel !== undefined
        ? Config.behaviour.loggerInstalledMaxLevel
        : (devMode ? 60 : 30)

    property int runtimeMaxLevel: Config.behaviour.loggerRuntimeMaxLevel !== undefined
        ? Config.behaviour.loggerRuntimeMaxLevel
        : (devMode ? 50 : 30)

    readonly property bool fatalOn: 10 <= runtimeMaxLevel
    readonly property bool errorOn: 20 <= runtimeMaxLevel
    readonly property bool warnOn:  30 <= runtimeMaxLevel
    readonly property bool infoOn:  40 <= runtimeMaxLevel
    readonly property bool debugOn: 50 <= runtimeMaxLevel
    readonly property bool traceOn: 60 <= runtimeMaxLevel

    Component.onCompleted: {
        LogStore.configure({
            installedMaxLevel: installedMaxLevel,
            runtimeMaxLevel: runtimeMaxLevel,
            maxEvents: Config.behaviour.loggerMaxEvents || 20000,
            maxPayloads: Config.behaviour.loggerMaxPayloads || 10000
        })

        root.installed = true
    }

    function levelFromName(name) {
        return LogStore.levelFromName(name)
    }

    function levelName(level) {
        return LogStore.levelName(level)
    }

    function setLevel(name) {
        const level = LogStore.levelFromName(name)
        if (level < 0)
            return { ok: false, error: "Invalid level: " + name }

        LogStore.runtimeMaxLevel = level
        runtimeMaxLevel = level
        return { ok: true, level: name }
    }

    function disable() {
        return setLevel("off")
    }

    function status() {
        return {
            installed: installed,
            installedMaxLevel: LogStore.levelName(installedMaxLevel),
            runtimeMaxLevel: LogStore.levelName(LogStore.runtimeMaxLevel),
            eventCount: LogStore.eventCount,
            droppedEventCount: LogStore.droppedEventCount,
            payloadCount: LogStore.payloadCount,
            droppedPayloadCount: LogStore.droppedPayloadCount
        }
    }

    function reset() {
        LogStore.reset()
        return { ok: true }
    }

    function collect(options) {
        return LogStats.collect(options || {})
    }

    function report(options) {
        return LogStats.textReport(options || {})
    }

    function log(level, name, defaults, payloadProvider) {
        if (level > LogStore.runtimeMaxLevel)
            return

        const nameId = LogStore.internName(name)
        const categoryId = LogStore.internCategory(
            (defaults && defaults.category) || inferCategory(name)
        )

        let payload = null
        if (typeof payloadProvider === "function")
            payload = payloadProvider()
        else if (payloadProvider !== undefined)
            payload = payloadProvider

        LogStore.appendLog(level, nameId, categoryId, payload)
    }

    function fatal(name, defaults, payloadProvider) {
        root.log(10, name, defaults, payloadProvider)
    }

    function error(name, defaults, payloadProvider) {
        root.log(20, name, defaults, payloadProvider)
    }

    function warn(name, defaults, payloadProvider) {
        root.log(30, name, defaults, payloadProvider)
    }

    function info(name, defaults, payloadProvider) {
        root.log(40, name, defaults, payloadProvider)
    }

    function debug(name, defaults, payloadProvider) {
        root.log(50, name, defaults, payloadProvider)
    }

    function trace(name, defaults, payloadProvider) {
        root.log(60, name, defaults, payloadProvider)
    }

    function beginTrace(name, defaults, payloadProvider) {
        if (60 > LogStore.runtimeMaxLevel)
            return null

        const nameId = LogStore.internName(name)
        const categoryId = LogStore.internCategory(
            (defaults && defaults.category) || inferCategory(name)
        )

        let payload = null
        if (typeof payloadProvider === "function")
            payload = payloadProvider()
        else if (payloadProvider !== undefined)
            payload = payloadProvider

        return LogStore.beginTrace(60, nameId, categoryId, payload)
    }

    function endTrace(span, payloadProvider) {
        if (span === null || span === undefined)
            return

        let payload = null
        if (typeof payloadProvider === "function")
            payload = payloadProvider()
        else if (payloadProvider !== undefined)
            payload = payloadProvider

        LogStore.endTrace(span, payload)
    }

    function traceFn(name, defaults, fn, payloadProvider) {
        return function traceFnWrapper() {
            const span = root.beginTrace(name, defaults, payloadProvider)

            try {
                return fn.apply(this, arguments)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                root.endTrace(span)
            }
        }
    }

    function traced(name, fn, options) {
        options = options || {}
        const level = options.level !== undefined
            ? LogStore.levelFromName(options.level)
            : 60

        if (level > installedMaxLevel)
            return fn

        const L = root.scope(name, options)
        return function tracedWrapper() {
            const span = L.beginTrace(name, options)

            try {
                return fn.apply(this, arguments)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                L.endTrace(span)
            }
        }
    }

    function traced0(name, fn, options) {
        options = options || {}
        const level = options.level !== undefined
            ? LogStore.levelFromName(options.level)
            : 60

        if (level > installedMaxLevel)
            return fn

        const L = root.scope(name, options)
        return function tracedWrapper0() {
            const span = L.beginTrace(name, options)

            try {
                return fn.call(this)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                L.endTrace(span)
            }
        }
    }

    function traced1(name, fn, options) {
        options = options || {}
        const level = options.level !== undefined
            ? LogStore.levelFromName(options.level)
            : 60

        if (level > installedMaxLevel)
            return fn

        const L = root.scope(name, options)
        return function tracedWrapper1(a) {
            const span = L.beginTrace(name, options)

            try {
                return fn.call(this, a)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                L.endTrace(span)
            }
        }
    }

    function traced2(name, fn, options) {
        options = options || {}
        const level = options.level !== undefined
            ? LogStore.levelFromName(options.level)
            : 60

        if (level > installedMaxLevel)
            return fn

        const L = root.scope(name, options)
        return function tracedWrapper2(a, b) {
            const span = L.beginTrace(name, options)

            try {
                return fn.call(this, a, b)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                L.endTrace(span)
            }
        }
    }

    function traced3(name, fn, options) {
        options = options || {}
        const level = options.level !== undefined
            ? LogStore.levelFromName(options.level)
            : 60

        if (level > installedMaxLevel)
            return fn

        const L = root.scope(name, options)
        return function tracedWrapper3(a, b, c) {
            const span = L.beginTrace(name, options)

            try {
                return fn.call(this, a, b, c)
            } catch (error) {
                if (span !== null)
                    LogStore.markTraceError(span, error)
                throw error
            } finally {
                L.endTrace(span)
            }
        }
    }

    function tap(name, value, defaults, summarizer) {
        if (50 <= LogStore.runtimeMaxLevel && typeof summarizer === "function")
            root.debug(name, defaults, function() { return summarizer(value) })

        return value
    }

    function scope(prefix, defaults) {
        defaults = defaults || {}

        const makeName = function(name) {
            return prefix + "." + name
        }

        return {
            fatal: function(name, payloadProvider) {
                root.fatal(makeName(name), defaults, payloadProvider)
            },

            error: function(name, payloadProvider) {
                root.error(makeName(name), defaults, payloadProvider)
            },

            warn: function(name, payloadProvider) {
                root.warn(makeName(name), defaults, payloadProvider)
            },

            info: function(name, payloadProvider) {
                root.info(makeName(name), defaults, payloadProvider)
            },

            debug: function(name, payloadProvider) {
                root.debug(makeName(name), defaults, payloadProvider)
            },

            trace: function(name, payloadProvider) {
                root.trace(makeName(name), defaults, payloadProvider)
            },

            beginTrace: function(name, payloadProvider) {
                return root.beginTrace(makeName(name), defaults, payloadProvider)
            },

            endTrace: function(span, payloadProvider) {
                root.endTrace(span, payloadProvider)
            },

            traceFn: function(name, fn, payloadProvider) {
                return root.traceFn(makeName(name), defaults, fn, payloadProvider)
            },

            traced: function(name, fn, options) {
                const merged = mergeOptions(defaults, options || {})
                merged.name = makeName(name)
                return root.traced(merged.name, fn, merged)
            },

            traced0: function(name, fn, options) {
                const merged = mergeOptions(defaults, options || {})
                merged.name = makeName(name)
                return root.traced0(merged.name, fn, merged)
            },

            traced1: function(name, fn, options) {
                const merged = mergeOptions(defaults, options || {})
                merged.name = makeName(name)
                return root.traced1(merged.name, fn, merged)
            },

            traced2: function(name, fn, options) {
                const merged = mergeOptions(defaults, options || {})
                merged.name = makeName(name)
                return root.traced2(merged.name, fn, merged)
            },

            tap: function(name, value, summarizer) {
                return root.tap(makeName(name), value, defaults, summarizer)
            }
        }
    }

    function inferCategory(name) {
        const dot = name.indexOf(".")
        return dot > 0 ? name.slice(0, dot) : "general"
    }

    function mergeOptions(a, b) {
        if (!b)
            return a

        const result = {}
        for (const key in a)
            result[key] = a[key]
        for (const key in b)
            result[key] = b[key]
        return result
    }
}
