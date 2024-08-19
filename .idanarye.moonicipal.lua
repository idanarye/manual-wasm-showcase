local moonicipal = require'moonicipal'
local T = moonicipal.tasks_file()

function T:run()
    --require'channelot'.windowed_terminal_job{'./build-missing.nu'}
    require'channelot'.windowed_terminal_job'./format-index.nu > index.html':wait()
    vim.cmd.checktime()
end
