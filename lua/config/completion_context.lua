local M = {}

local languages = {
    c = "c", cpp = "cpp", cs = "c_sharp", java = "java", python = "python", lua = "lua",
    javascript = "javascript", javascriptreact = "javascript", typescript = "typescript", typescriptreact = "tsx",
}

local names = {
    variable_declarator = true, function_declaration = true, function_definition = true,
    class_declaration = true, class_definition = true, class_specifier = true,
    struct_specifier = true, union_specifier = true, enum_specifier = true,
    struct_declaration = true, enum_declaration = true, interface_declaration = true,
    record_declaration = true, type_alias_declaration = true, method_declaration = true,
    method_definition = true, constructor_declaration = true, property_declaration = true,
    public_field_definition = true, namespace_definition = true,
    parameter = true, formal_parameter = true, type_parameter = true,
    enumerator = true, enum_member_declaration = true,
}
local declarators = {
    declaration = true, field_declaration = true, init_declarator = true,
    function_declarator = true, function_definition = true, parameter_declaration = true,
    optional_parameter_declaration = true, type_definition = true,
}

local function contains(node, row, col)
    local sr, sc, er, ec = node:range()
    return (row > sr or row == sr and col >= sc) and (row < er or row == er and col < ec)
end

-- Follow only binding branches, never initializers, parameter types, array
-- dimensions, or default values contained inside a larger declaration.
local function binding(node, row, col)
    if not contains(node, row, col) then return false end
    local kind = node:type()
    if kind == "identifier" or kind == "type_identifier" or kind == "field_identifier"
        or kind == "property_identifier" or kind == "shorthand_property_identifier_pattern" then
        return true
    end
    local field = ((kind == "assignment_pattern" or kind == "object_assignment_pattern") and "left")
        or (kind == "pair_pattern" and "value")
        or (kind == "qualified_identifier" and "name")
        or (kind == "default_parameter" and "name")
        or (kind == "typed_default_parameter" and "name")
    if field then
        for _, child in ipairs(node:field(field)) do
            if binding(child, row, col) then return true end
        end
        return false
    end
    for _, key in ipairs({ "declarator", "name", "pattern" }) do
        for _, child in ipairs(node:field(key)) do
            if binding(child, row, col) then return true end
        end
    end
    if kind == "typed_parameter" then
        local first = node:named_child(0)
        return first ~= nil and binding(first, row, col)
    end
    if kind == "object_pattern" or kind == "array_pattern" or kind == "pattern_list"
        or kind == "tuple_pattern" or kind == "list_pattern" or kind == "list_splat_pattern"
        or kind == "dictionary_splat_pattern" or kind == "rest_pattern"
        or kind == "formal_parameters" or kind == "parameters" or kind == "lambda_parameters"
        or kind == "structured_binding_declarator" then
        for child in node:iter_children() do
            if child:named() and binding(child, row, col) then return true end
        end
    end
    return false
end

local function field_binding(node, field, row, col)
    for _, child in ipairs(node:field(field)) do
        if binding(child, row, col) then return true end
    end
    return false
end

function M.is_declaration(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    if bufnr ~= vim.api.nvim_get_current_buf() then return false end
    local ft = vim.bo[bufnr].filetype
    local lang = languages[ft]
    if not lang then return false end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local before = vim.api.nvim_get_current_line():sub(1, col)
    local word = before:match("[%w_$]+$")
    if not word or vim.startswith(word, "snip") then return false end
    local at = col - 1
    local ok, node = pcall(function()
        local parser = vim.treesitter.get_parser(bufnr, lang)
        parser:parse({ row, row + 1 })
        return vim.treesitter.get_node({ bufnr = bufnr, lang = lang, pos = { row, at } })
    end)
    if ok then
        local current = node
        while current do
            local kind = current:type()
            if kind:find("comment") or kind:find("string") then return false end
            if names[kind] and field_binding(current, "name", row, at) then return true end
            if kind == "field_definition" and field_binding(current, "property", row, at) then return true end
            if kind == "arrow_function" and field_binding(current, "parameter", row, at) then return true end
            if declarators[kind] and field_binding(current, "declarator", row, at) then return true end
            if (kind == "required_parameter" or kind == "optional_parameter")
                and field_binding(current, "pattern", row, at) then return true end
            if (kind == "parameters" or kind == "formal_parameters" or kind == "lambda_parameters")
                and binding(current, row, at) then
                return true
            end
            if ft == "python" and (kind == "assignment" or kind == "for_statement" or kind == "for_in_clause")
                and field_binding(current, "left", row, at) then return true end
            if ft == "lua" and kind == "variable_list" then
                local parent = current:parent()
                if parent and parent:type() == "assignment_statement" then parent = parent:parent() end
                if parent and parent:type() == "variable_declaration" and binding(current, row, at) then return true end
            end
            current = current:parent()
        end
    end

    -- Parsers report ERROR nodes while declarations are still incomplete
    -- (e.g. `def na` before the opening parenthesis). Recognize explicit
    -- declaration keywords, but don't guess that a bare identifier is new.
    local prefix = before:sub(1, #before - #word)
    local keyword = prefix:match("([%a_]+)%s+$")
    if ft == "python" or ft == "lua" or ft:find("script") then
        local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, row - 20), row, false)
        lines[#lines + 1] = before
        local header = table.concat(lines, "\n")
        local parameters
        if ft == "python" then
            parameters = header:match("%f[%a]def%s+[%w_]+%s*%(([^()]*)$")
        else
            parameters = header:match("%f[%a]function%s*[%w_$%.:]*%s*%(([^()]*)$")
        end
        if parameters then
            local last = parameters:match("([^,]*)$")
            if last and last:match("^%s*%**[%w_$]+$") then return true end
        end
    end
    local keywords = {
        python = { def = true, class = true },
        lua = { ["local"] = true, ["function"] = true },
        c = { struct = true, union = true, enum = true },
        cpp = { class = true, struct = true, union = true, enum = true, namespace = true },
        java = { class = true, interface = true, enum = true, record = true },
        cs = { class = true, struct = true, interface = true, enum = true, record = true, namespace = true },
        javascript = { ["function"] = true, class = true, const = true, let = true, var = true },
        typescript = { ["function"] = true, class = true, const = true, let = true, var = true, interface = true, type = true, enum = true, namespace = true },
    }
    local family = ft:gsub("react$", "")
    return keyword ~= nil and (keywords[family] or {})[keyword] == true
end

return M
