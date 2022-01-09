local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local colorize = require('ansicolors2').ansicolors

local dprint = require('debug_print')

local debug_print = print
local format = string.format

local thread_num = ...
local msg



msg = '%{yellow}>>>>>%{reset} thread ' .. thread_num .. 'started'
debug_print('thread', colorize(msg))

dprint.set_filter({
   [1] = { "joy" },
   [2] = { 'phys' },
   [3] = { "thread", 'someName' },
   [4] = { "graphics" },
   [5] = { "input" },
   [6] = { "verts" },






})

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

msg = '%{yellow}>>>>>%{reset} thread ' .. thread_num .. ' started'
debug_print('thread', colorize(msg))
