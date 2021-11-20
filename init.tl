local colorize = require 'ansicolors2'.ansicolors
print(colorize('%{yellow}>>>>>%{reset} chipmunk_mt started'))

require "love"
require "love_inc".require()
require 'pipeline'

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/chipmunk_mt/?.lua")
--local i18n = require "i18n"
--local format = string.format

local event_channel = love.thread.getChannel("event_channel")
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

local function init()
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
        --local pause = 1. / 10.
        local pause = 1. / 300.
        local diff = nt - last_render
        if diff >= pause then
            last_render = nt
            --local msg = 'love.timer.getTime() = %f'
            --print(colorize('%{blue}' .. format(msg, love.timer.getTime())))
            render()
        end
        --]]

        --pw.update(diff)

        --render()

        local timeout = 0.0001
        --love.timer.sleep(0.0008)
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
