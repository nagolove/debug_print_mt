local colorize = require('ansicolors2').ansicolors

local dprint = require('debug_print')

local debug_print = dprint.debug_print


local thread_num = ...
local msg



msg = '%{yellow}>>>>>%{reset} thread ' .. thread_num .. ' started'
debug_print('thread', colorize(msg))

require('pipeline')

local thread_channel = love.thread.getChannel("thread_channel")

while true do
   if thread_channel then
      local cmd = thread_channel:peek()
      if cmd then
         if cmd == "quit" then
            break
         end
      end
   end

end

msg = '%{yellow}>>>>>%{reset} thread ' .. thread_num .. ' finished'
debug_print('thread', colorize(msg))
