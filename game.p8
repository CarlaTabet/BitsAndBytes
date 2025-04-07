pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function _init()
    -- nothing needed here for this simple test
end

function _update()
    -- no updates needed for static drawing
end

function _draw()
    cls()                 -- clear screen
    circ(64, 64, 30, 7)   -- draw white circle at center
    print("hello, carla!", 40, 100, 11)  -- print text in light blue
end
