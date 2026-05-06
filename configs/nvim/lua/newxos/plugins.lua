local M = {}
local config = require("newxos.config")

function M.ensure_native_plugins()
    if config.use_nix_managed_plugins() then
        return
    end

    local ok, err = pcall(function ()
        require("newxos.non_nix_compatibility").ensure_plugins()
    end)

    if not ok then
        vim.schedule(function ()
            vim.notify("newxos native plugin bootstrap failed: " .. tostring(err), vim.log.levels.WARN)
        end)
    end
end

return M
