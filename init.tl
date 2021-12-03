local colorize = require 'ansicolors2'.ansicolors
local inspect = require "inspect"
print(colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require "love"
require "love_inc".require()
require 'pipeline'
local Cm = require 'chipmunk'

--Cm.C.cpInitChipmunk()
--local v = Cm.cpvzero()
--print(v)

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")
--local i18n = require "i18n"
--local format = string.format

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")
--local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
--local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
--local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

--[[

-- chipmunk.d.tl

local record Chipmunk
    record Space
        record Gravity
            x: number
            y: number
        end

        iterations: integer
        gravity: Gravity    
    end

    cpSpaceNew: function(): Space
end

return Chipmunk
-- main.tl

local C = require("chipmunk")
local space = C.cpSpaceNew()
space.iterations = 20
space.gravity.x = 0
space.gravity.y = -100

--]]

local last_render: number

local pipeline = Pipeline.new("scenes/chipmunk_mt")
local pw = require "physics_wrapper"

-- Как часто перекомпилировать код рисовки?
-- Варианты - 
--  * по таймеру
--  * используя метод :peek() на каждой итерации цикла
-- Сейчас функция компилируется один раз при загрузке файла исходного текста
-- потока.

local joystick = love.joystick
local joy: love.joystick.Joystick

local function init()
    for _, joy in ipairs(joystick.getJoysticks()) do
        print(colorize('%{green}' .. inspect(joy)))
    end
    joy = joystick.getJoysticks()[1]
    print(colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
    print(colorize('%{green}hats num: ' .. joy:getHatCount()))
    --[[
    i18n.set('en.welcome', 'welcome to this program')
    i18n.load({
        en = {
            good_bye = "good-bye!",
            age_msg = "your age is %{age}.",
            phone_msg = {
                one = "you have one new message.",
                other = "you have %{count} new messages."
            }
        }
    })
    print("translated", i18n.translate('welcome'))
    print("translated", i18n('welcome'))
    --]]

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

    -- Допустимо-ли переопределение функций? Или добавить специальный флаг?
    -- Нормально-ли использовать константы?
    pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    end
    ]])

    --[[
    -- Добавлять-ли такую функцию? Будет использоваться?
    -- Стоимость реализации и возможности применения.
    pipeline:pushCodes({
        { 
            'text',
            'code',
        },
        {},
        {},
    })
    --]]

    last_render = love.timer.getTime()

    pw.init(pipeline)

    pw.newBoxBody(200, 500)
    print('pw.getBodies()', inspect(pw.getBodies()))
    --print('os.exit')
    --os.exit(1)
end

--[[
Откуда берутся мелькания при рисовке?
Значит, что данные не сихронизируются? То есть основной поток получает
не все данные и ждет их. В это время он рисует часть картинки, ждет,
рисует вторую часть. В момент ожидания видно мелькание? Но картинка
слишком простая.
--]]
local function render()
    if pipeline:ready() then

        pipeline:openAndClose('clear')

        --pipeline:open('text')
        --pipeline:close()

        --local x, y = love.mouse.getPosition()
        --local rad = 50
        --pipeline:open('circle_under_mouse')
        --pipeline:push(y)
        --pipeline:push(x)
        --pipeline:push(rad)
        --pipeline:close()

        --pw.render()
    end
end

local is_stop = false

local function moveBody(scancode: string)
    if scancode == 'left' then
        -- Как передать импульс или силу телу?
        -- Организация обертки над Бурундучком.
        -- Минимальное количество функций.
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

local bodyIter: pw.EachSpaceBodyIter
local shapeIter: pw.EachBodyShapeIter

local function eachShape(b: Cm.cpBody, _: Cm.cpShape)
    --print('eachShape')
    --local body = pw.cpBody2Body(b)
    --print(colorize('%{magenta}body: ' .. body:getInfoStr()))
end

local function eachBody(b: Cm.cpBody)
    local body = pw.cpBody2Body(b)
    if body then
        --print(colorize('%{green}' .. inspect(body)))
        --print(colorize('%{yellow}' .. body:getInfoStr()))
        pw.eachBodyShape(b, shapeIter)
    else
        --print(colorize('%{red}body is nil ' .. debug.traceback()))
    end
end

bodyIter = pw.newEachSpaceBodyIter(eachBody)
shapeIter = pw.newEachBodyShapeIter(eachShape)

local joy_msg_prev: string = ""
local joy_msg: string = ""

local joy_pressed_prev: string = ''
local joy_pressed: string = ''

local joy_hat_prev: string = ''
local joy_hat: string = ''

local function joystickUpdate()
    local axes = {joy:getAxes()}
    joy_msg_prev = joy_msg
    joy_msg = inspect(axes)
    if joy_msg_prev ~= joy_msg then
        print(inspect(axes))
    end

    local buttons_num = joy:getButtonCount()
    local pressed = {}
    for i = 1, buttons_num do
        --local pressed = {joy:isDown(
        pressed[i] = joy:isDown(i)
    end
    joy_pressed_prev = joy_pressed
    joy_pressed = inspect(pressed)
    if joy_pressed_prev ~= joy_pressed then
        print('pressed:', joy_pressed_prev)
    end

    joy_hat_prev = joy_hat
    local hat_num = 1
    joy_hat = joy:getHat(hat_num)
    if joy_hat_prev ~= joy_hat then
        print('hat direction:', joy_hat)
    end
end

local function mainloop()
    while not is_stop do
        --print('mainloop iter')
        local events = event_channel:pop() as {any}
        if events then
            for _, e in ipairs(events) do
                local evtype: string = (e as {string})[1]
                if evtype == "mousemoved" then
                    --mx = math.floor((e as {number})[2])
                    --my = math.floor((e as {number})[3])
                elseif evtype == "keypressed" then
                    local key = (e as {string})[2]
                    local scancode = (e as {string})[3]

                    local msg = '%{green}keypressed '
                    print(colorize(msg .. key .. ' ' .. scancode))

                    if scancode == "escape" then
                        is_stop = true
                        print(colorize('%{blue}escape pressed'))
                        break
                    end

                    moveBody(scancode)

                    --msg = '%{yellow}keypressed '
                    --print(colorize(msg .. key .. ' ' .. scancode))

                elseif evtype == "mousepressed" then
                    --local x: number = (e as {number})[2]
                    --local y: number = (e as {number})[3]
                    --local button: number = (e as {number})[4]
                    --local istouch: boolean = (e as {boolean})[5]
                    --local presses: number = (e as {number})[6]
                end
            end
        end
        
        -- Ограничение кадров в секунду до 60
        local nt = love.timer.getTime()
        local pause = 1. / 300.
        --local pause = 1. / 4000.
        local diff = nt - last_render
        if diff >= pause then
            last_render = nt
            --local msg = 'love.timer.getTime() = %f'
            --print(colorize('%{blue}' .. format(msg, love.timer.getTime())))
            render()
        end

        pw.update(diff)
        --render()

        -- UPDATE HERE PLEASE
        --print('------------------------------------------------')
        pw.eachSpaceBody(bodyIter)
        joystickUpdate()
        --print('------------------------------------------------')

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
    --love.event.quit()
end


print(colorize('%{yellow}<<<<<%{reset} chipmunk_mt finished'))
