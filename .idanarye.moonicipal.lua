local moonicipal = require'moonicipal'
local T = moonicipal.tasks_file()

function T:run()
    require'channelot'.windowed_terminal_job{'./build-missing.nu'}
end
