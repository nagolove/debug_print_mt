-- vim: set colorcolumn=85
-- vim: fdm=marker

require 'pipeline'

local colorize = require 'ansicolors2'.ansicolors
local inspect = require "inspect"
local dprint = require 'debug_print'
local debug_print = dprint.debug_print
local format = string.format
local subproject_name = "debug_print_mt"

dprint.set_filter { 
    [1] = { "joy" },
    [2] = { 'phys' },
    [3] = { "thread", 'someName' },
    [4] = { "graphics" },
    [5] = { "input" },
    [6] = { "verts" },
    --[7] = { "phys" },
    --[8] = { "phys" },
    --[9] = { "phys" },
    --[0] = { "phys" },
}

local start_msg = '%{yellow}>>>>>%{reset}' .. subproject_name .. 'started'
debug_print('thread', colorize(start_msg))

require "love"
require "love_inc".require_pls()

local require_path = "?.lua;?/init.lua;scenes/" .. subproject_name .. "/?.lua"
love.filesystem.setRequirePath(require_path)

local pipeline = Pipeline.new("scenes/" .. subproject_name)
local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render: number = 0

local threads = {}
--local thread_num = 4
local threads_num = 2

local function initThreads()
    local fname = "scenes/" .. subproject_name .. "/thread1.lua"
    print(colorize("%{red}" .. format("Using %d threads", threads_num)))
    for i = 1, threads_num do
        local thread = love.thread.newThread(fname)
        --print('thread', thread)
        table.insert(threads, thread)
        thread:start(i)
        print("i = ", thread:getError())
    end
    print('threads: ', inspect(threads))
end

local function initPipeline()
    pipeline:pushCode("clear_screen", [[
    while true do
        love.graphics.clear()
        coroutine.yield()
    end
    ]])

    pipeline:pushCode("print_debug_filters", [[
        local dprint = require "debug_print"
        local col = {1, 0, 1, 1}
        while true do
            love.graphics.setColor(col)
            dprint.render(0, 0)

            coroutine.yield()
        end
    ]])

    --pipeline:pushCode("debug_print", [[ ]])
end

local function printProgramDescription()
    print(colorize('%{blue}' .. [[description:
    Программа показывает возможность многопоточной фильтрации логов.
    Тестирование модуля debug_print()
    Для переключения фильтров журналирования нажмите цифровые клавиши 1..9 или 0 

    Группы: графика, потоки выполнения

    ]]))
end

local function init()
    initThreads()
    initPipeline()
    printProgramDescription()
end

local function render()
    if pipeline:ready() then
        pipeline:openAndClose('clear_screen')
        pipeline:openAndClose('print_debug_filters')
        --pipeline:openAndClose('text')
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
                    debug_print('input', colorize(msg .. key .. ' ' .. scancode))

                    dprint.keypressed(scancode)

                    if scancode == "escape" then
                        is_stop = true
                        debug_print('input', colorize('%{blue}escape pressed'))
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
        local pause = 1. / 300.
        --local pause = 1. / 4000.
        local diff = nt - last_render
        if diff >= pause then
            last_render = nt
            --local msg = 'love.timer.getTime() = %f'
            --print(colorize('%{blue}' .. format(msg, love.timer.getTime())))
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


local finish_msg = '%{yellow}<<<<<%{reset} ' .. subproject_name .. 'finished'
debug_print('thread', colorize(finish_msg))
