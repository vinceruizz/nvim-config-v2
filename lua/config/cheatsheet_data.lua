local M = {}

function M.cards()
    local debugging = {}
    for _, action in ipairs(require("config.debug").actions or {}) do
        local alternate = action[4] and (" / " .. action[4]:gsub("[<>]", "")) or ""
        debugging[#debugging + 1] = { "Space d " .. action[1] .. alternate, action[2] }
    end
    vim.list_extend(debugging, {
        { "Space d ?", "Debugger action menu" },
        { "Space d e (visual)", "Evaluate selected expression" },
        { "Scopes: Enter / e", "Expand variable / edit value" },
        { "Watches: i / d", "Add expression / remove watch" },
        { "Stacks: o", "Jump to stack frame" },
        { "Breakpoints: o / t", "Jump to source / enable or disable" },
        { "● / ◆ / ▶", "Breakpoint / condition / paused line" },
        { ":DebugGuide", "Full language setup and debugging guide" },
    })

    return {
        { title = "movement", context = "Normal mode unless noted", rows = {
            { "h / j / k / l", "Left / down / up / right" },
            { "w / b / e", "Next word / previous word / word end" },
            { "0 / ^ / $", "Line start / first nonblank / line end" },
            { "gg / G", "First / last line" },
            { "5j / 5k", "Move using relative line numbers" },
            { "Ctrl d / u", "Half page down / up" },
            { "Ctrl f / b", "Full page down / up" },
            { "%", "Jump to matching bracket" },
            { "/text + Enter", "Find text in current buffer" },
            { "n / N", "Next / previous search match" },
            { "Ctrl o / i", "Older / newer jump location" },
            { "Ctrl h / j / k / l", "Focus left / lower / upper / right window" },
            { "[d / ]d", "Previous / next diagnostic" },
            { "Esc", "Clear search highlight; exit insert mode" },
        } },
        { title = "debugging", context = "Save your file; start from the project root", rows = debugging },
        { title = "project navigation", context = "Explorer and project search", rows = {
            { "Space e", "Open or focus file explorer" },
            { "Space ff", "Find files, including hidden files" },
            { "Space fg", "Search project contents" },
            { "Space fw", "Find word under cursor across files" },
            { "Space tt", "Toggle terminal; expires after 5 min hidden" },
            { "Terminal: Esc", "Leave terminal input mode" },
            { "Terminal: Ctrl g", "Hide terminal; keep session running" },
            { "Terminal: q (Normal)", "Hide terminal; keep session running" },
            { ":bnext / :bprev", "Next / previous buffer" },
            { ":buffers", "List open buffers" },
            { "Explorer: l / h", "Open or expand / collapse or parent" },
            { "Explorer: Enter", "Open selected file or folder" },
            { "Explorer: -", "Change root to parent directory" },
            { "Explorer: a / r", "Create / rename file or folder" },
            { "Explorer: c / x / p", "Copy / cut / paste" },
            { "Explorer: H / I", "Toggle hidden / Git-ignored files" },
            { "Explorer: R / g?", "Refresh / show all explorer shortcuts" },
            { "Picker: Ctrl n / p", "Next / previous search result" },
            { "Picker: Enter", "Open selected result" },
            { "Picker: Ctrl v / x", "Open in vertical / horizontal split" },
            { "Picker: Ctrl u / d", "Scroll preview up / down" },
            { "Picker: Ctrl /", "Show all picker shortcuts" },
            { "Picker: Esc", "Normal mode; Esc again closes" },
            { "Search scope", "Explorer root, else file directory" },
        } },
        { title = "language tools", context = "Quiet diagnostics; details on demand", rows = {
            { "gd / gD / gi", "Definition / declaration / implementation" },
            { "gr", "Find references" },
            { "K", "Show documentation under cursor" },
            { "Space rn", "Rename symbol" },
            { "Space la", "Show code actions" },
            { "Space ld", "Show diagnostics under cursor" },
            { "Space lq", "List this file's diagnostics" },
            { "[d / ]d", "Previous / next diagnostic (no popup)" },
            { "Insert: Ctrl x, Ctrl o", "Request LSP completion" },
            { ":Mason", "Manage language servers" },
        } },
        { title = "Codex", context = "Persistent right panel; project-root context", rows = {
            { "Space cc", "Toggle Codex panel from Normal mode" },
            { "Codex: Ctrl g", "Hide panel; keep session running" },
            { "Codex: q (Normal)", "Hide panel; keep session running" },
            { "Space ca", "Ask about file / selected code" },
            { "Space ce (visual)", "Compose edit request for selected code" },
            { "Space cb", "Attach current file without submitting" },
            { "Space cf", "Compose a follow-up request" },
            { "Request: Ctrl s", "Submit request to Codex" },
            { "Space cd", "View session Git diff (tracked changes)" },
            { "Space cr", "Resume a previous Codex session" },
            { "Space cq", "Stop Codex session" },
            { "Codex: Esc / Alt n", "Leave terminal input mode" },
            { "Codex: Ctrl h/j/k/l", "Focus neighboring window" },
            { ":CodexHealth", "Check Codex integration" },
        } },
        { title = "GIT", context = "Feature to be added", rows = {
            { "Coming soon", "Dedicated Git workflow and shortcuts" },
        } },
    }
end

return M
