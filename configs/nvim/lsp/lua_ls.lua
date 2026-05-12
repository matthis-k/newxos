---@class LuaLsOptions
---@field completion? table
---@field diagnostics? table
---@field format? table
---@field hint? table
---@field runtime? table
---@field workspace? table

local function workspace_library()
    return {
        vim.env.VIMRUNTIME,
        "${3rd}/luv/library",
        "${3rd}/busted/library",
    }
end

return {
    settings = {
        ---@type LuaLsOptions
        Lua = {
            format = {
                enable = true,
                defaultConfig = {
                    indent_style = "space",
                    indent_size = "4",
                    tab_width = "4",
                    continuation_indent = "4",
                    max_line_length = "120",
                    quote_style = "double",
                    call_arg_parentheses = "keep",
                    space_after_comma = "true",
                    space_after_comma_in_for_statement = "true",
                    space_around_assign_operator = "true",
                    space_around_concat_operator = "true",
                    space_around_logical_operator = "true",
                    space_around_math_operator = "true",
                    space_around_table_field_list = "true",
                    space_before_attribute = "true",
                    space_before_closure_open_parenthesis = "true",
                    space_before_function_call_open_parenthesis = "false",
                    space_before_function_open_parenthesis = "false",
                    space_before_open_square_bracket = "false",
                    space_inside_function_call_parentheses = "false",
                    space_inside_function_param_list_parentheses = "false",
                    space_inside_square_brackets = "false",
                    insert_final_newline = "true",
                    trailing_table_separator = "always",
                    table_separator_style = "comma",
                    end_statement_with_semicolon = "keep",
                    line_space_around_block = "fixed(1)",
                    line_space_after_function_statement = "fixed(2)",
                    line_space_before_inline_comment = "1",
                    ignore_spaces_inside_function_call = "true",
                    ignore_space_after_colon = "true",
                },
            },
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = {
                    "vim",
                    "Ui",
                    "StatusColumn",
                    "StatusLine",
                    "TabLine",
                },
            },
            workspace = {
                checkThirdParty = "false",
                library = workspace_library(),
            },
            hint = {
                enable = false,
                arrayIndex = "Auto",
                await = true,
                paramName = "All",
                paramType = true,
                semicolon = "All",
                setType = true,
            },
        },
    },
}
