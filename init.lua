local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local colorize = require('ansicolors2').ansicolors
print(colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require("love")
require("love_inc").require()
require('pipeline')

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")



local event_channel = love.thread.getChannel("event_channel")

































local last_render

local pipeline = Pipeline.new("scenes/chipmunk_mt")
local pw = require("physics_wrapper")








local function init()
















   local rendercode = [[
    while true do
        local w, h = love.graphics.getDimensions()
        local x, y = math.random() * w, math.random() * h
        love.graphics.setColor{0, 0, 0}
        love.graphics.print("TestTest", x, y)
        coroutine.yield()
    end
    ]]
   pipeline:pushCode('text', rendercode)

   rendercode = [[
    while true do
        local y = graphic_command_channel:demand()
        local x = graphic_command_channel:demand()
        local rad = graphic_command_channel:demand()
        love.graphics.setColor{0, 0, 1}
        love.graphics.circle('fill', x, y, rad)
        coroutine.yield()
    end
    ]]
   pipeline:pushCode('circle_under_mouse', rendercode)



   pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    end
    ]])














   last_render = love.timer.getTime()

   pw.init()
end

local function render()
   if pipeline:ready() then

      pipeline:openAndClose('clear')

      pipeline:open('text')
      pipeline:close()

      local x, y = love.mouse.getPosition()
      local rad = 50
      pipeline:open('circle_under_mouse')
      pipeline:push(y)
      pipeline:push(x)
      pipeline:push(rad)
      pipeline:close()

   end
end

local is_stop = false

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
               print(colorize(msg .. key .. ' ' .. scancode))

               if scancode == "escape" then
                  is_stop = true
                  print(colorize('%{blue}escape pressed'))
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

local function free()
   pw.free()
end

init()
mainloop()

if is_stop then
   print('free resources')
   free()
   love.event.quit()
end


print(colorize('%{yellow}<<<<<%{reset} chipmunk_mt finished'))
