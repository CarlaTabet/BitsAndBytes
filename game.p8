pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

rooms = {
    --Name of room, x,y is top right corner and w,h is how big it is
    graveyard = {x=0,y=0,w=36,h=36},
    room1 = {x=0,y=39,w=36,h=25}
}

exits = {
    {
        --Gives current room, destination when leaving room, 
        --px,py is where the player ends up
        --condition function is where the player needs to be in order to exit
        room = "graveyard", 
        dest="room1", 
        px=40, 
        py=312,
        condition = function()
            return player.x >= 160 and player.x <= 178 and player.y==277
        end
    }
}

blood_drops = {}
flowers = {}
puzzle_active = false
puzzle_solved = false

function spawn_blood_drop(x, y)
    add(blood_drops, {
        x = x,
        y = y,
        base_y = y,    -- original position
        float_offset = 0,
        float_speed = 0.05,
        collected = false
    })
end

function load_flowers_from_map()
    flowers = {}
    local room = rooms[current_room]
    for ty = room.y, room.y + room.h - 1 do
        for tx = room.x, room.x + room.w - 1 do
            if mget(tx, ty) == 59 then -- flower sprite
                add(flowers, {
                    tx = tx,
                    ty = ty,
                    x = tx * 8,
                    y = ty * 8,
                    collected = false
                })
            end
        end
    end
end


function _init()
    current_room = "graveyard"

    player = {
        x = 16,
        y = 16,
        sp = 9,
        speed = 3
    }

    blood = 10
    flower = 0
				
				
    spawn_blood_drop(25, 58)
				load_flowers_from_map()
    time_elapsed = 0
    max_time = 60 * 60
end

symbols = {40, 41, 42, 43, 44}

function update_puzzle()
    if btnp(0) then -- left
        selected_dial = max(1, selected_dial - 1)
    elseif btnp(1) then -- right
        selected_dial = min(3, selected_dial + 1)
    elseif btnp(2) then -- up
        current_combo[selected_dial] = (current_combo[selected_dial] - 2) % #symbols + 1
    elseif btnp(3) then -- down
        current_combo[selected_dial] = current_combo[selected_dial] % #symbols + 1
    elseif btnp(4) or btnp(5) then -- z or x to submit
        if current_combo[1] == correct_combo[1] and
           current_combo[2] == correct_combo[2] and
           current_combo[3] == correct_combo[3] then
            puzzle_solved = true
            puzzle_active = false
        else
            -- maybe play a wrong sound
        end
    end
end



function draw_puzzle()
    rectfill(10, 40, 118, 90, 0)
    rect(10, 40, 118, 90, 7)
    print("align the ancient symbols", 18, 45, 6)
    for i=1,3 do
        local sprite_id = symbols[current_combo[i]]
        local x = 30 + (i - 1) * 28
        local y = 64
        local col = (i == selected_dial) and 11 or 6
        rect(x - 6, y - 6, x + 10, y + 10, col)
        spr(sprite_id, x-1, y-1)
    end
    if (time() % 1) < 0.5 then
        print("press z to enter", 34, 84, 5)
    end

end



function _update()
			if puzzle_active then
    update_puzzle()
			else
			    player_update()
			    room_change()
			end
    
    time_elapsed = min(time_elapsed + 1, max_time)
    for drop in all(blood_drops) do
    drop.float_offset = sin(time() + drop.x) * 2
    	if not drop.collected and abs(player.x - drop.x) < 8 and abs(player.y - drop.y) < 8 then
        drop.collected = true
        player_collect_blood()
    	end
				end
				for f in all(flowers) do
	    if not f.collected and abs(player.x - f.x) < 8 and abs(player.y - f.y) < 8 then
			    f.collected = true
			    mset(f.tx, f.ty, 16) -- replace with sprite 16
			    player_collect_flower()
					end
				end

end

function draw_riddle()
    rectfill(8, 96, 120, 124, 0)
    rect(8, 96, 120, 124, 7)
    print("the eye that sees", 14, 100, 6)
    print("the claw that strikes", 14, 108, 6)
    print("the flame that guides", 14, 116, 6)
end


function _draw()
    cls()
    local room = rooms[current_room]
    local room_left = room.x * 8
    local room_right = (room.x + room.w) * 8
    local room_top = room.y * 8
    local room_bottom = (room.y + room.h) * 8
    cam_x = mid(room_left, player.x - 64, room_right - 128)
    cam_y = mid(room_top, player.y - 64, room_bottom - 128)
    camera(cam_x, cam_y)
 

    map(0,0,0,0,128,64)
    spr(player.sp, player.x, player.y)
    
    -- draw blood drops
    for drop in all(blood_drops) do
        if not drop.collected then
            local draw_x = drop.x - cam_x
            local draw_y = drop.base_y + drop.float_offset - cam_y
            spr(60, draw_x, draw_y)
        end
    end

    if current_room == "graveyard" then
        draw_mist()
        draw_darkness()
        if puzzle_active then
					    	draw_puzzle()
							   draw_riddle()
								end
    end

    camera()
    spr(60, 1, 1)
    print(blood, 10, 2, 8)
    spr(58, 1, 10)
    print(flower, 10, 10, 8)

    draw_time_bar()
end


function player_update()
    local dx = 0
    local dy = 0

    if btn(0) then dx = -1 end
    if btn(1) then dx = 1 end
    if btn(2) then dy = -1 end
    if btn(3) then dy = 1 end

    local new_x = player.x + dx * player.speed
    local new_y = player.y + dy * player.speed

    local function is_walkable(x, y)
        return not (
            is_solid(flr(x / 8), flr(y / 8))
        )
    end

    local can_move_x = is_walkable(new_x, player.y) and
                       is_walkable(new_x + 7, player.y) and
                       is_walkable(new_x, player.y + 7) and
                       is_walkable(new_x + 7, player.y + 7)

    local can_move_y = is_walkable(player.x, new_y) and
                       is_walkable(player.x + 7, new_y) and
                       is_walkable(player.x, new_y + 7) and
                       is_walkable(player.x + 7, new_y + 7)

    if can_move_x then player.x = new_x end
    if can_move_y then player.y = new_y end

end

function room_change()
    for exit in all(exits) do 
        if exit.room == current_room and exit.condition() then
            if not puzzle_solved then
										    puzzle_active = true
										    selected_dial = 1
										    symbols = {40,41,42,43,44}
										    correct_combo = {1, 2, 3}
										    current_combo = {1, 1, 1}
										    return
												end
            current_room = exit.dest
            player.x = exit.px
            player.y = exit.py
            load_flowers_from_map()
            return
        end 
    end
end


function draw_darkness()
    camera()
    local px = player.x - cam_x
    local py = player.y - cam_y

    for y=0,127 do
        for x=0,127 do
            if ((x - px)^2 + (y - py)^2) > 30*30 then
                pset(x, y, -16) 
            end
        end
    end
end

function is_solid(tx, ty)
    local tile = mget(tx, ty)
    return tile == 32 or tile == 33 or tile == 48 or tile == 49 or tile == 10 or tile == 18 or tile == 1 or tile == 0 or tile == 3 or tile == 4 or tile == 5 or tile == 6 or tile == 7 or tile == 8
end


function draw_mist()
   for i=1, 30 do
     local mx = flr(rnd(128)) + cam_x
     local my = flr(rnd(128)) + cam_y
     pset(mx, my, 5) 
   end
end


function player_hit_enemy()
    blood = max(0, blood - 1)
end

function player_collect_blood()
    blood = min(20, blood + 1)
end

function player_collect_flower()
    flower = flower+1
end

function draw_time_bar()
    local bar_x = 85
    local bar_y = 2
    local bar_w = 35
    local bar_h = 5

    -- moon and sun icons
    spr(61, bar_x - 8, bar_y - 1)
    spr(62, bar_x + bar_w + 1, bar_y - 1)

    -- bar border
    rect(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, 1)

    -- black background
    rectfill(bar_x + 1, bar_y + 1, bar_x + bar_w - 1, bar_y + bar_h - 1, 0)

    -- calculate time fill (shrinks right-to-left)
    local t = time_elapsed / max_time
    local fill_w = flr((bar_w - 2) * (1 - t))
    
    rectfill(bar_x + 1, bar_y + 1, bar_x + 1 + fill_w, bar_y + bar_h - 1, 8)
end






__gfx__
000000003355553333333333661666161616111666666666661111116666666611111166999999990000000066666666ddddddddeeeeeeee8888888800000000
000000005556655533333333611161116666666661161616611111116161611611111116999999990000000066666666ddddddddeeeeeeee8888888800000000
000000005666666533333333611161111616111661161611666666111161611611666666999999990000000066666666ddddddddeeeeeeee8888888800000000
000000005666666533333333611161111616111166661611611116111161666611611116999999990000000066666666ddddddddeeeeeeee8888888800000000
000000005556655533333333666666661616111661111611666616111161111611616666999999990000000066666666ddddddddeeeeeeee8888888800000000
000000003356653333333333611161116666666666666611611616111166666611616116999999990000000066666666ddddddddeeeeeeee8888888800000000
000000003356653333333333666666661616111661111111611616161111116661616116999999990000000066666666ddddddddeeeeeeee8888888800000000
000000003355553333333333611161111616111166111111666666661111116666666666999999990000000066666666ddddddddeeeeeeee8888888800000000
4444444400000000b33b3b3b3338883300000000000000000000000000000000111666666666666666666111cccccccc77777777222222221111111100000000
44444444000000003b33b33333889883000000000000000000000000000000001161111111111111111116117777cccc77777777222222221111111100000000
4444444400000000333333b33389998300000000000000000000000000000000161111111111111111111161cccccccc77777777222222221111111100000000
4444444400000000b3b3b3bb3388988300000000000000000000000000000000611116666666666666666116cccccccc77777777222222221111111100000000
4444444400000000333333333338883300000000000000000000000000000000611161616116116116161611cccccccc77777777222222221111111100000000
4444444400000000b3b3b33b3333b33300000000000000000000000000000000611611616116116116161161cccc77cc77777777222222221111111100000000
4444444400000000333b33333333bb3300000000000000000000000000000000611611616116116116161161cccccccc77777777222222221111111100000000
4444444400000000b3b33b3b333bb33300000000000000000000000000000000611611616116116116161161cccccccc77777777222222221111111100000000
33330000000033330000000055555555555555555555555500000000000000000000000000800800000080000006600070000007000000000000000000000000
33005555555500330000000055444444444444555444444500000000000000000077770000700700000888000066760077000077000000000000000000000000
30666666666555030000000054444444444444455444444500000000000000000708807080000008008898800067760070777707000000000000000000000000
06666666666655500000000054444444444444455444444500000000000000007008800770077007088999800667776070600607000000000000000000000000
066666666666655000000000544444444444444554444445000000000000000007088070007777000899a9806677776007000880000000000000000000000000
06655665655665500000000054444444444444455444444500000000000000000077770000777700089aaa906777776000777780000000000000000000000000
06656566656565500000000055444444444444555444444500000000000000000000000000777700009aaa900777766000000080000000000000000000000000
06655665655665500000000055555555555555555555555500000000000000000000000000000000000aaa000077760000000080000000000000000000000000
066565656566655000000000555555550000000000000000000000000000000000000000000000000088800044488844000800000a0990a00006660000000000
06656565656665500000000054444445000000000000000000000000000000000000000000000000088988004488988400080000a09aa90a0067776000000000
0666666666666550000000005444444500000000000000000000000000000000000000000000000008999800448999840084800009aa9a900677600000000000
066666666666655000000000544444450000000000000000000000000000000000000000000000000889880044889884008480009aaaa9a96776000000000000
065565665556655000000000544444450000000000000000000000000000000000000000000000000088800044488844087448009aaaaaa96776000000000000
06666666666665500000000054444445000000000000000000000000000000000000000000000000000b00004444b4440877480009aaaa900677600000000000
06655566655665500000000054444445000000000000000000000000000000000000000000000000000bb0004444bb4400888000a09aa90a0067776000000000
0666666666666550000000005555555500000000000000000000000000000000000000000000000000bb0000444bb444000800000a0990a00006660000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
402021010121202101010101010101010121202101010121202020202020210101212040000000000000d1e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d10000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
403121212121102121212121212121212121202101010121202020202010212121212040000000000000d1e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d10000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
402020202020202020203120202020202020202101010121201020202020202020203140000000000000d1e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d10000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
70303030303030303030303030303030303030308191a130303030303030303030303050000000000000d1d1d1d1d1d1d1d1c1d1d1d1d1d1d1d1d10000000000
000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d1e0e0e0e0e0e0e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008181818181818100000000000000000000000000008181818100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008181818181818181818181818100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000818181818181818181818181818181
818181818181818181818181a1a1a1a1a18181818181818181818181000000000000000000000000000000000000000000222200000000000000000000008181
e1e1e1e1e1c1c1c1c1c1c1c1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e100000000000000000000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d00000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1b0c1b0c1b0c1b0c1b0e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1e0e0b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0e0e0c1b0e181000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1b0c1b0c1e181000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0c1b0c1b0e181000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d0
e1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1b0c1b0c1e181810000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1b0c1b0c1b0c1b0c1b0e181810000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e181810000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e181810000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e181810000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e18181e3e3e3e300000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e181e3e3e3e381000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e181818181e381000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08181000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1333252323252323242c1b0c1b0423242323252323233b0c1b0c1b0c1e1818100000000000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0333252323252323233b0c1b0c1333242323252323233c1b0c1b0c1b0e1818100000000000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1333342333333423333c1b0c1b0334233333333423333b0c1b0c1b0c1e100000000000000000000000081d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d08100000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e100000000000000000000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d08181000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
__map__
1e0303030303030303030303030303030303030303030303030303030303030303031e1e0000000000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e
0412101010122021121212020102020202021302020202021212122021120213020202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101230313b3b1202020213020201020202020201123b3b3031120202020202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010121010101012121212121212121212121212121210101010121212120201040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010101010101010101010101010101010101010101010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010101010101010101010101010101010101010101010121302040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010121212121212121212121212121212121212121212121212121010120201040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120213020202020202020202020202020213121010102021121010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101202020202020201020202020213020202021210103b3031121010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121212121212121212121212020102121010121212121010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120102121010101010101010101012020213121010121212121010121302040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010101010101010101012020202121010101010101010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e1e0000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010121212121212101012130202121010101010101010120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e1e0000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010120201020212101012020202121212121212121212120202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e1e0000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120201121010120202021312101012020202020202020102020202020102040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010121212121010120202020212101012021212121212121212121212121202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012011210101010101010101010101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012021210101010101010101010101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412121212121212121212120202020112101012021210101212121212121210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402010202020202130201020212121212101012121210101202021302021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402122021121202020202020212101010101010101010101201020202021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04021230313b1202020202021312101010101010101010101202020201021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101212121212121212101012121212121212121202020202021210101201040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012021302020202020202010202021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012020212121212120202020202131210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0401121010121212101012121212121212010212101010121212121212121210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120112101012010202121212120212101010101010101010101010101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202122021120212101010101010101010101010101213040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202123031120212101010121212121212121210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020201123b3b120212101010120202020202011210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012121212121010120212101010120102020202021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010121312101010101010101010120112101010120202130202021210101202040000000000001d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e1d1e000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
