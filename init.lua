local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table
local colorize = require('ansicolors2').ansicolors
local inspect = require("inspect")


print(colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require('joystate')
require("love")
require("love_inc").require()
require('pipeline')


local Cm = require('chipmunk')

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")


local joystick = love.joystick

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local bodyIter
local shapeIter

local tank






























local last_render

local pipeline = Pipeline.new("scenes/chipmunk_mt")
local pw = require("physics_wrapper")








local joy
local joyState

local function init()
   for _, joy in ipairs(joystick.getJoysticks()) do
      print(colorize('%{green}' .. inspect(joy)))
   end
   joy = joystick.getJoysticks()[1]
   if joy then
      print(colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
      print(colorize('%{green}hats num: ' .. joy:getHatCount()))
   end

   joyState = JoyState.new(joy)

















   local rendercode = [[
    local col = {1, 1, 1, 1}
    --love.graphics.setColor(col)
    while true do
        --love.graphics.setColor(col)
        coroutine.yield()
    end
    ]]
   pipeline:pushCode("rect", rendercode)

   rendercode = [[
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

   pipeline:pushCode("poly_shape", [[
    local col = {1, 0, 0, 1}
    --love.graphics.setColor(col)
    local inspect = require "inspect"
    while true do
        love.graphics.setColor(col)
        local verts = graphic_command_channel:demand()
        --print('poly_shape: verts', inspect(verts))
        --love.graphics.rectangle('fill', 0, 0, 1000, 1000)
        love.graphics.polygon('fill', verts)
        coroutine.yield()
    end
    ]])














   last_render = love.timer.getTime()

   pw.init(pipeline)


   tank = pw.newBoxBody(200, 500)

   print('pw.getBodies()', inspect(pw.getBodies()))
end








local function render()
   if pipeline:ready() then

      pipeline:openAndClose('clear')













      pw.eachSpaceBody(bodyIter)
   end
end

local is_stop = false

local function eachShape(b, shape)








   local shape_type = pw.polyShapeGetType(shape)



   if shape_type == pw.CP_POLY_SHAPE then



      local num = pw.polyShapeGetCount(shape)
      local verts = {}
      for i = 0, num - 1 do

         local vert = pw.polyShapeGetVert(shape, i)


         table.insert(verts, vert.x)
         table.insert(verts, vert.y)
      end
      pipeline:open('poly_shape')
      pipeline:push(verts)
      pipeline:close()
   end

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

local function applyInput()
   local leftBtn, rightBtn, downBtn, upBtn = 3, 2, 1, 4
   local k = 100.
   if joy then
      if joy:isDown(leftBtn) then
         tank:applyImpulse(1. * k, 0)
         print('left')
      elseif joy:isDown(rightBtn) then
         tank:applyImpulse(-1. * k, 0)
         print('right')
      elseif joy:isDown(upBtn) then
         tank:applyImpulse(0, 1 * k)
         print('up')
      elseif joy:isDown(downBtn) then
         tank:applyImpulse(0, -1 * k)
         print('down')
      end
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
      applyInput()



      joyState:update()
      if joyState.state and joyState.state ~= "" then
         print(joyState.state)
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
   free()
   main_channel:push('quit')
   print('Thread resources are freed')

end


print(colorize('%{yellow}<<<<<%{reset} chipmunk_mt finished'))
