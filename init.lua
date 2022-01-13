local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


require('pipeline')

local colorize = require('ansicolors2').ansicolors
local inspect = require("inspect")
local dprint = require('debug_print')
local debug_print = dprint.debug_print
local format = string.format

dprint.set_filter({
   [1] = { "joy" },
   [2] = { 'phys' },
   [3] = { "thread", 'someName' },
   [4] = { "graphics" },
   [5] = { "input" },
   [6] = { "verts" },




})

debug_print('thread', colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require("love")
require("love_inc").require()

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")

local pipeline = Pipeline.new("scenes/debug_print_mt")
local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render = 0

local threads = {}

local threads_num = 1

local function initThreads()
   local fname = "scenes/debug_print_mt/thread1.lua"
   print(colorize("%{red}" .. format("Using %d threads", threads_num)))
   for i = 1, threads_num do
      local thread = love.thread.newThread(fname)

      table.insert(threads, thread)
      thread:start(i)
      print("i = ", thread:getError())
   end
   print('threads: ', inspect(threads))
end

local function initPipeline()
   pipeline:pushCode("print_debug_filters", [[
        local dprint = require "debug_print"
        local col = {1, 1, 1, 1}
        while true do
            love.graphics.setColor(col)

            --love.graphics.polygon('fill', verts)
            --dprint.render(0, 0)

            coroutine.yield()
        end
    ]])


end

local function printProgramDescription()
   print(colorize('%{blue}' .. [[description:
        Программа показывает возможность многопоточной фильтрации логов.
        Тестирование модуля debug_print()
        Для переключения фильтров журналирования нажмите цифровые клавиши 1..9 или 0 ]]))
end

local function init()
   initThreads()
   initPipeline()
   printProgramDescription()
end

local function render()
   if pipeline:ready() then

      pipeline:openAndClose('print_debug_filters')

   end
end

local function mainloop()
   while not is_stop do

      local events = event_channel:pop()
      if events then
         for _, e in ipairs(events) do
            local evtype = (e)[1]
            if evtype == "mousemoved" then


            elseif evtype == "keypressed" then
               local key = (e)[2]
               local scancode = (e)[3]

               local msg = '%{green}keypressed '
               debug_print('input', colorize(msg .. key .. ' ' .. scancode))

               dprint.keypressed(scancode)

               if scancode == "escape" then
                  is_stop = true
                  debug_print('input', colorize('%{blue}escape pressed'))
                  break
               end




            elseif evtype == "mousepressed" then





            end
         end
      end


      local nt = love.timer.getTime()
      local pause = 1. / 300.

      local diff = nt - last_render
      if diff >= pause then
         last_render = nt


         render()
      end

      local timeout = 0.0001
      love.timer.sleep(timeout)
   end
end

init()
mainloop()

if is_stop then
   main_channel:push('quit')
   debug_print('thread', 'Thread resources are freed')
end


debug_print('thread', colorize('%{yellow}<<<<<%{reset} chipmunk_mt finished'))
