local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local colorize = require('ansicolors2').ansicolors
local inspect = require("inspect")
print(colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require("love")
require("love_inc").require()
require('pipeline')
local Cm = require('chipmunk')





love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")



local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

































local last_render

local pipeline = Pipeline.new("scenes/chipmunk_mt")
local pw = require("physics_wrapper")








local joystick = love.joystick
local joy

local function init()
   for _, joy in ipairs(joystick.getJoysticks()) do
      print(colorize('%{green}' .. inspect(joy)))
   end
   joy = joystick.getJoysticks()[1]
   if joy then
      print(colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
      print(colorize('%{green}hats num: ' .. joy:getHatCount()))
   end

















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
    -- Загружать текстуры здесь
    -- Загружать текстуры здесь
    -- Загружать текстуры здесь
    -- Загружать текстуры здесь

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

   pw.init(pipeline)

   pw.newBoxBody(200, 500)
   print('pw.getBodies()', inspect(pw.getBodies()))


end








local function render()
   if pipeline:ready() then

      pipeline:openAndClose('clear')













   end
end

local is_stop = false

local function moveBody(scancode)
   if scancode == 'left' then



      print('left')
   end
   if scancode == 'right' then
      print('right')
   end
   if scancode == 'up' then
      print('up')
   end
   if scancode == 'down' then
      print('down')
   end
end

local bodyIter
local shapeIter

local function eachShape(b, _)
   print('eachShape call')


end

local function eachBody(b)
   local body = pw.cpBody2Body(b)
   if body then


      pw.eachBodyShape(b, shapeIter)
   else

   end
end

bodyIter = pw.newEachSpaceBodyIter(eachBody)
shapeIter = pw.newEachBodyShapeIter(eachShape)

local joy_msg_prev = {}
local joy_msg = {}

local joy_pressed_prev = {}
local joy_pressed = {}

local joy_hat_prev
local joy_hat

local function joystickUpdate()
   if not joy then
      return
   end

   local axes = { joy:getAxes() }
   joy_msg_prev = joy_msg
   joy_msg = axes

   local msg = ""
   local colored_once = false
   for k, v in ipairs(joy_msg) do
      if v == joy_msg_prev[k] then
         msg = msg .. colorize('%{white}' .. tostring(v) .. ' ')
      else
         colored_once = true
         msg = msg .. colorize('%{red}' .. tostring(v) .. ' ')
      end
   end
   if colored_once then
      print(msg)
   end

   local buttons_num = joy:getButtonCount()
   local pressed = {}
   for i = 1, buttons_num do
      pressed[i] = joy:isDown(i)
   end

   joy_pressed_prev = joy_pressed
   joy_pressed = pressed

   msg = ""
   colored_once = false
   for k, v in ipairs(joy_pressed) do
      if v == joy_pressed_prev[k] then
         msg = msg .. colorize('%{white}' .. tostring(v) .. ' ')
      else
         colored_once = true
         msg = msg .. colorize('%{red}' .. tostring(v) .. ' ')
      end
   end
   if colored_once then
      print('pressed:', msg)
   end


   local hat_num = 1
   joy_hat_prev = joy_hat
   joy_hat = joy:getHat(hat_num)

   colored_once = false
   msg = ''
   if joy_hat_prev == joy_hat then
      msg = msg .. colorize('%{white}' .. joy_hat)
   else
      colored_once = true
      msg = msg .. colorize('%{red}' .. joy_hat)
   end
   if colored_once then
      print('hat direction:', msg)
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
               print(colorize(msg .. key .. ' ' .. scancode))

               if scancode == "escape" then
                  is_stop = true
                  print(colorize('%{blue}escape pressed'))
                  break
               end

               moveBody(scancode)




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

      pw.update(diff)



      print('------------------------------------------------')
      pw.eachSpaceBody(bodyIter)
      print('------------------------------------------------')
      joystickUpdate()

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
   free()
   main_channel:push('quit')
   print('Thread resources are freed')

end


print(colorize('%{yellow}<<<<<%{reset} chipmunk_mt finished'))
