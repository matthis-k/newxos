local M = {}

local config = require("newxos.config")

local function lockfile_path()
    return config.config_dir() .. "/nvim-pack-lock.json"
end

local function read_lockfile()
    local lines = vim.fn.readfile(lockfile_path())
    return vim.json.decode(table.concat(lines, "\n")) or {}
end

local function plugin_specs()
    local plugins = (read_lockfile().plugins or {})
    local names = vim.tbl_keys(plugins)
    table.sort(names)

    return vim.iter(names)
        :map(function(name)
            local plugin = plugins[name]
            return {
                name = name,
                src = plugin.src,
                version = plugin.rev,
            }
        end)
        :totable()
end

function M.ensure_plugins()
    vim.pack.add(plugin_specs(), { confirm = false })
end

return M
