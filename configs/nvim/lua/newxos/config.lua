local M = {}

local fallback_info = setmetatable({
    settings = {},
    info = {},
    isNix = false,
}, {
    __call = function (_, default)
        return default
    end,
})

local function load_nix_info()
    local plugin_name = vim.g.nix_info_plugin_name
    if type(plugin_name) ~= "string" or plugin_name == "" then
        return fallback_info
    end

    local ok, nix_info = pcall(require, plugin_name)
    if not ok or type(nix_info) ~= "table" then
        return fallback_info
    end

    nix_info.isNix = true
    return nix_info
end

M.nix_info = load_nix_info()
M.is_nix = M.nix_info.isNix == true

function M.get(default, ...)
    return M.nix_info(default, ...)
end

function M.setting(default, key, ...)
    return M.nix_info(default, "settings", key, ...)
end

function M.info(default, key, ...)
    return M.nix_info(default, "info", key, ...)
end

function M.config_dir()
    return M.setting(vim.fn.stdpath("config"), "config_directory")
end

function M.use_nix_managed_plugins()
    return M.setting(false, "use_nix_managed_plugins")
end

return M
