pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

id_card_collected = false
id_card = nil
button = nil
cameras = {}


rooms = {
    --Name of room, x,y is top right corner and w,h is how big it is
    graveyard = {x=0,y=0,w=36,h=36},
    room1 = {x=0,y=39,w=36,h=25},
    room2 = {x=43, y=0, w=16, h=36},
    lab = {x=49, y=39, w=42, h=25}
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
    },
    {
        room = "room1",
        dest = "room2",
        px = 400,
        py = 0,
        condition = function()
            return id_card_collected and player.x >= 248 and player.x <=256 and player.y >=384 and player.y <= 392
        end
    },
    {
        room = "graveyard",
        dest = "room2",
        px = 400,
        py = 0,
        condition = function()
            return player.x == 49 and player.y == 25
        end
    },
    {
        room = "room2",
        dest = "room1",
        px = 247,
        py = 380,
        condition = function()
            return player.x >= 325 and player.x <= 338 and player.y >= 48 and player.y <= 52
        end
    },
    {
        room = "room2",
        dest = "lab",
        px = 521,
        py = 312,
        condition = function ()
            return player.x == 466 and player.y == 183
        end
    }
}

doors = {}
pause_timer = 0
door_transition = false
active_door = nil
blood_drops = {}
flowers = {}
puzzle_active = false
puzzle_solved = false


function load_button_from_map()
    button = nil
    local room = rooms[current_room]
    for ty = room.y, room.y + room.h - 1 do
        for tx = room.x, room.x + room.w - 1 do
            if mget(tx, ty) == 52 then
                button = {
                    tx = tx,
                    ty = ty,
                    pressed = false,
                    animating = false,
                    anim_timer = 0,
                    done = false
                }
                return
            end
        end
    end
end

function spawn_blood_drop(x, y)
    add(blood_drops, {
        x = x,
        y = y,
        base_y = y,
        float_offset = 0,
        float_speed = 0.05,
        collected = false
    })
end

function load_cameras_from_map()
    cameras = {}
    local room = rooms[current_room]
    for ty = room.y, room.y + room.h - 1 do
        for tx = room.x, room.x + room.w - 1 do
            local id = mget(tx, ty)
            if id == 36 or id == 37 then
                add(cameras, {
                    x = tx * 8,
                    y = ty * 8,
                    dir = (id == 36) and 1 or -1, -- 1 = right, -1 = left
                    sweep_timer = rnd()
                })
            end
        end
    end
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

function load_blood_drops_from_map()
    blood_drops = {} 
    local room = rooms[current_room]
    for ty = room.y, room.y + room.h - 1 do
        for tx = room.x, room.x + room.w - 1 do
            if mget(tx, ty) == 60 then 
                add(blood_drops, {
                    x = tx * 8,
                    y = ty * 8,
                    base_y = ty * 8,
                    float_offset = 0,
                    float_speed = 0.05,
                    collected = false
                })
            end
        end
    end
end

function load_id_card_from_map()
    id_card = nil
    local room = rooms[current_room]
    for ty = room.y, room.y + room.h - 1 do
        for tx = room.x, room.x + room.w - 1 do
            if mget(tx, ty) == 45 then
                id_card = {
                    tx = tx,
                    ty = ty,
                    x = tx * 8,
                    y = ty * 8,
                    collected = false
                }
                return
            end
        end
    end
end

nurse = {
    x = 11 * 8,
    y = 49 * 8,
    sp = 20,
    dir = 1,
    speed = 0.5
}


function update_nurse()
    nurse.x += nurse.speed * nurse.dir

    if nurse.x <= 11 * 8 then
        nurse.dir = 1
    elseif nurse.x >= 24 * 8 then
        nurse.dir = -1
    end
end

function draw_triangle(x1, y1, x2, y2, x3, y3, col)
    -- sort points by y
    if y1 > y2 then x1,y1,x2,y2 = x2,y2,x1,y1 end
    if y2 > y3 then x2,y2,x3,y3 = x3,y3,x2,y2 end
    if y1 > y2 then x1,y1,x2,y2 = x2,y2,x1,y1 end

    local function interp(x0, y0, x1, y1)
        local result = {}
        local dy = y1 - y0
        if dy == 0 then return result end
        for i=0, dy do
            add(result, x0 + (x1 - x0) * (i / dy))
        end
        return result
    end

    local x_a = interp(x1, y1, x3, y3)
    local x_b = {}
    for v in all(interp(x1, y1, x2, y2)) do add(x_b, v) end
    for v in all(interp(x2, y2, x3, y3)) do add(x_b, v) end

    local m = min(#x_a, #x_b)
    for y=0, m-1 do
        local xa = x_a[y+1]
        local xb = x_b[y+1]
        if xa and xb then
            if xa > xb then xa, xb = xb, xa end
            line(xa, y1 + y, xb, y1 + y, col)
        end
    end
end

function draw_nurse()
    spr(nurse.sp, nurse.x, nurse.y)

    local ex = nurse.x + (nurse.dir == 1 and 8 or -1)
    local ey = nurse.y + 4

    local length = 30
    local spread = 15
    local end_x = ex + (nurse.dir == 1 and length or -length)
    local top_y = ey - spread
    local bot_y = ey + spread

    local colors = {7,10,15}
				local base_spread = 6
    
   for i = #colors, 1, -1 do
        local fade = i - 1
        
        local spread = base_spread + fade * 3
        local tip_x = end_x + (nurse.dir == 1 and fade * 2 or -fade * 2)
        local flicker_offset = sin(time() * 6 + i) * 1.5
								local top_y = ey - spread - flicker_offset
								local bot_y = ey + spread + flicker_offset
								draw_triangle(ex, ey, tip_x, top_y, tip_x, bot_y, colors[i])
    end
end

function sign(p1, p2, p3)
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
end

function point_in_triangle(pt, v1, v2, v3)
    local d1 = sign(pt, v1, v2)
    local d2 = sign(pt, v2, v3)
    local d3 = sign(pt, v3, v1)

    local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    return not (has_neg and has_pos)
end

function check_vision_cone_hit()
    local ex = nurse.x + (nurse.dir == 1 and 8 or -1)
    local ey = nurse.y + 4
				local px = player.x + 4
				local py = player.y + 4

    local length = 30
    local base_spread = 6
    local tip_x = ex + (nurse.dir == 1 and length or -length)

    local flicker_offset = sin(time() * 6 + 1) * 1.5
    local top_y = ey - (base_spread + flicker_offset)
    local bot_y = ey + (base_spread + flicker_offset)

    local p_center = {
        x = player.x + 4,
        y = player.y + 4
    }

    local v1 = {x = ex, y = ey}
    local v2 = {x = tip_x, y = top_y}
    local v3 = {x = tip_x, y = bot_y}

    if point_in_triangle(p_center, v1, v2, v3) then
        game_over = true
    end
    
    for c in all(cameras) do
	    local cx = c.x + 4
	    local cy = c.y + 4
	    local dir = c.dir
	
	    local base_angle = (dir == 1) and 0 or 0.5
	    local sweep = sin((time() + c.sweep_timer) * 0.2) * 0.4
	    local angle = base_angle + sweep
	
	    local len = 30
	    local spread = 10
	
	    local tip_x = cx + cos(angle) * len
	    local tip_y = cy + sin(angle) * len
	
	    local perp_angle = angle + 0.25
	    local top_x = tip_x + cos(perp_angle) * spread
	    local top_y = tip_y + sin(perp_angle) * spread
	    local bot_x = tip_x - cos(perp_angle) * spread
	    local bot_y = tip_y - sin(perp_angle) * spread
	
	    if top_y > bot_y then
	        top_x, bot_x = bot_x, top_x
	        top_y, bot_y = bot_y, top_y
	    end
	
	    local player_center = {
	        x = player.x + 4,
	        y = player.y + 4
	    }
	
	    local v1 = {x = cx, y = cy}
	    local v2 = {x = top_x, y = top_y}
	    local v3 = {x = bot_x, y = bot_y}
	
	    if point_in_triangle(player_center, v1, v2, v3) then
	        game_over = true
	        return
	    end
		end

end

function _init()
				id_card_collected = false
				game_over = false
    current_room = "graveyard"
				puzzle_solved = false
    player = {
        x = 16,
        y = 16,
        sp = 9,
        speed = 3
    }

    current_room = "graveyard"

    blood = 10
    flower = 0
	
    --Doors
    add_door("room2", 43, 5, "left")   
    add_door("room2", 57, 22, "right")
    
	load_cameras_from_map()    
	load_button_from_map()
				
    spawn_blood_drop(25, 58)
	load_flowers_from_map()
    load_blood_drops_from_map()
    load_id_card_from_map()
    time_elapsed = 0
    max_time = 60 * 60
end

function update_doors()
    for door in all(doors) do 
        if door_transition and pause_timer <= 0  and active_door then
            if active_door.direction == "left" then
                player.x -= 12
            else
                player.x += 12
            end
            player.speed = 3
            active_door.state = "closed"
            active_door = nil
            door_transition = false
            door.state = "closed"
        end
    end

    for door in all(doors) do
        if door.room == current_room then
            local center_x = player.x + 4
            local center_y = player.y + 4
            local door_x = door.x * 8
            local door_y = door.y * 8
            
            if door.state == "closed" and center_x >= door_x and center_x < door_x + 8 and center_y >= door_y and center_y < door_y + 16 then
                door.state = "open"
                player.speed = 0
                door_transition = true
                pause_timer = 60
                active_door = door
                return
            end
        end
    end
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
    if door_transition then
        pause_timer -= 1
    end

    update_doors()

				if puzzle_active then
			        update_puzzle()
				else
				  player_update()
					room_change()
				end
				
				if game_over then
				    if btnp(5) then
				        _init()
				    end
				  		return
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
    if id_card and not id_card.collected and abs(player.x - id_card.x) < 8 and abs(player.y - id_card.y) < 8 then
        id_card.collected = true
        mset(id_card.tx, id_card.ty, 28)
        id_card_collected = true
    -- maybe add a pick up sound here?
    end
    update_nurse() 
    if not game_over then
    	check_vision_cone_hit()
				end
				
			if button and not button.done then
    local bx = button.tx * 8 + 4
    local by = button.ty * 8 + 4
    local px = player.x + 4
    local py = player.y + 4

    if abs(px - bx) < 12 and abs(py - by) < 12 and btnp(5) and not button.animating and not button.pressed then
        button.animating = true
        button.anim_timer = 30
    end

    if button.animating then
        button.anim_timer -= 1
        if button.anim_timer <= 0 then
            button.animating = false
            button.pressed = true
            button.anim_timer = 45 -- stay "pressed" briefly
            mset(button.tx, button.ty, 53)
        end
    elseif button.pressed then
       if not button.cleared then
        cameras = {}
        button.cleared = true -- just to make sure it happens once
			    end
			
			    button.anim_timer -= 1
			    if button.anim_timer <= 0 then
			        button.done = true
			        button.pressed = false
			    end
    end
	end

end

function draw_camera_vision()
    for c in all(cameras) do
        local cx = c.x + 4
        local cy = c.y + 4
        local dir = c.dir

        -- rotation angle changes over time
        local base_angle = (dir == 1) and 0 or 0.5 -- right or left in radians
        local sweep = sin((time() + c.sweep_timer) * 0.2) * 0.4 -- slow るね~23るぬ
        local angle = base_angle + sweep

        local len = 30
        local spread = 10

        local tip_x = cx + cos(angle) * len
        local tip_y = cy + sin(angle) * len

        local perp_angle = angle + 0.25
        local top_x = tip_x + cos(perp_angle) * spread
        local top_y = tip_y + sin(perp_angle) * spread
        local bot_x = tip_x - cos(perp_angle) * spread
        local bot_y = tip_y - sin(perp_angle) * spread
								if top_y > bot_y then
								    top_x, bot_x = bot_x, top_x
								    top_y, bot_y = bot_y, top_y
								end
        draw_triangle(cx, cy, top_x, top_y, bot_x, bot_y, 2)
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
    local room_width = room.w * 8
    local room_top = room.y * 8
    local room_height = room.h * 8
    local cam_x, cam_y
    
    if room_width > 128 then
        cam_x = mid(room_left, player.x - 64, room_left + room_width - 128)
    else
        cam_x = room_left
    end

    if room_height > 128 then
        cam_y = mid(room_top, player.y - 64, room_top + room_height - 128)
    else
        cam_y = room_top
    end

    camera(cam_x, cam_y)
 
    draw_doors()
    map(0,0,0,0,128,64)
    palt(0, false)
    palt(6, true)
    spr(player.sp, player.x, player.y)
    palt(6, false)
    palt(0,true)
    
    for drop in all(blood_drops) do
        if not drop.collected then
            local draw_x = drop.x - cam_x
            local draw_y = drop.base_y + drop.float_offset - cam_y
            spr(60, draw_x, draw_y)
        end
    end

    if id_card and not id_card.collected then
        spr(45, id_card.x - cam_x, id_card.y - cam_y)
    end

    if current_room == "graveyard" then
        draw_mist(cam_x, cam_y)
        draw_darkness(cam_x, cam_y)
        if puzzle_active then
					    	draw_puzzle()
							   draw_riddle()
								end
    end
    if current_room == "room2" then
    	draw_camera_vision()
				end

  	 draw_nurse() 
    

    camera()
    spr(60, 1, 1)
    print(blood, 10, 2, 8)
    spr(58, 1, 10)
    print(flower, 10, 10, 8)
    if id_card_collected then
        spr(45, 1, 19)
    end
    draw_time_bar()
    print("x="..player.x.." y="..player.y, 40, 0, 0)
    local tile_x = flr(player.x / 8)
    local tile_y = flr(player.y / 8)   
    print("map pos: ("..tile_x..","..tile_y..")", 40, 40, 0)
    if door_transition then
        print("PAUSED", 50, 50, 7)
    end
    
    if game_over then
	    rectfill(20, 50, 108, 78, 0)
	    rect(20, 50, 108, 78, 8)
	    print("you were spotted!", 32, 58, 8)
	    print("press ❎ to retry", 30, 66, 7)
				end
				
				if button and not button.done then
	    local bx = button.tx * 8 + 4
	    local by = button.ty * 8 + 4
	    local px = player.x + 4
	    local py = player.y + 4
	
	    local sx = bx - cam_x
	    local sy = by - cam_y
	
	    if button.animating then
	        print("disabling...", max(0, sx - 20), sy - 12, 10)
	    elseif button.pressed then
	        print("cameras disabled!", max(0, sx - 30), sy - 12, 11)
	    elseif abs(px - bx) < 12 and abs(py - by) < 12 then
	        print("press ❎ to disable cameras", max(0, sx - 30), sy - 12, 6)
	    end
		end
end

function draw_doors()
    for door in all(doors) do 
        if door.room == current_room then
            if door.state == "closed" then
                mset(door.x, door.y, door.closed[1])
                mset(door.x, door.y+1, door.closed[2])
            else
                mset(door.x, door.y, door.open[1][1])
                mset(door.x+1, door.y, door.open[1][2])
                mset(door.x, door.y+1, door.open[2][1])
                mset(door.x+1, door.y+1, door.open[2][2])
            end
        end
    end
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
            load_blood_drops_from_map()
            load_id_card_from_map()
            load_cameras_from_map()
            load_button_from_map()
            return
        end 
    end
end

function add_door(room, x, y, direction)
    add(doors, {
        room = room,
        x = x,
        y = y,
        closed = {47, 63},
        open = {
            {22, 15},
            {38, 31}
        },
        state = "closed",
        direction = direction
    })
end

function draw_darkness(cam_x, cam_y)
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
    if tx <0 or tx >= 128 or ty < 0 or ty >= 64 then
        return true
    end
    local sprite_id = mget(tx, ty)
    return fget(sprite_id, 0)
end


function draw_mist(cam_x, cam_y)
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
000000003355553333333333661666161616111666666666661111116666666611111166600000060000000066666666ddddddddeeeeeeee8888888888000088
000000005556655533333333611161116666666661161616611111116161611611111116005005000000000066666666ddddddddeeeeeeee8888888880044008
000000005666666533333333611161111616111661161611666666111161611611666666055555500000000066666666ddddddddeeeeeeee8888888880444408
000000005666666533333333611161111616111166661611611116111161666611611116050550500000000066666666ddddddddeeeeeeee8888888804444440
000000005556655533333333666666661616111661111611666616111161111611616666555555550000000066666666ddddddddeeeeeeee8888888804444440
000000003356653333333333611161116666666666666611611616111166666611616116550000550000000066666666ddddddddeeeeeeee8888888804444440
000000003356653333333333666666661616111661111111611616161111116661616116657557560000000066666666ddddddddeeeeeeee8888888804444440
000000003355553333333333611161111616111166111111666666661111116666666666665555660000000066666666ddddddddeeeeeeee8888888804444040
4444444400000000b33b3b3b3338883344444444000002202200002244000044111666666666666666666111cccccccc77777777222222221111111104444040
44444444000000003b33b3333388988344ffff4400ffff2020022002405555041161111111111111111116117777cccc77777777222222221111111104444440
4444444400000000333333b3338999834ffffff40ffffff02022220205566550161111111111111111111161cccccccc77777777222222221111111104444440
4444444400000000b3b3b3bb338898834f5ff5f40f5ff5f00222222005666650611116666666666666666116cccccccc77777777222222221111111104444440
444444440000000033333333333888334ffffff40ffffff00222222005600650611161616116116116161611cccccccc77777777222222221111111104444440
4444444400000000b3b3b33b3333b3334f5555f40ff555f00222222005600650611611616116116116161161cccc77cc77777777222222221111111104444440
4444444400000000333b33333333bb334ffffff40ffffff00222222006000060611611616116116116161161cccccccc77777777222222221111111104444440
4444444400000000b3b33b3b333bb33344cffc44007ff7000222222006600660611611616116116116161161cccccccc77777777222222221111111100000000
333300000000333377777333dddddddd888888888888888802222220066006600000000000800800000080000006600070000007000990000000000022000022
3300555555550033b33733b3daaaaadd555555888855555502222220056006500077770000700700000888000066760077000077777777770000000020044002
3066666666655503bbb3bbb3daeaead05555555555555555022222200560065007088070800000080088988000677600707777077ccc66670000000020444402
06666666666655503bbbbb33daaaaad05555666006665555022222200560065070088007700770070889998006677760706006077c4c68670000000004444440
0666666666666550773b3377da9abad05555686006865555022222204056650407088070007777000899a98066777760070008807cfc88870000000004444440
06655665655665507773b777daaaaad0000066600666000002222220405665040077770000777700089aaa906777776000777780711168670000000004444440
06656566656565507773b777da8a2add880000000000008802222220440550440000000000777700009aaa900777766000000080711166670000000004444440
06655665655665507773b777daaaaadd000088888888000000000000440000440000000000000000000aaa000077760000000080777777770000000004044440
066565656566655055555555daeacadd88aaa88888888888444a94440000000000000000000000000088800044488844000800000a0990a00006660004044440
066565656566655054449995daaaaadd88aaa88888aaa88844499944000000000000000000000000088988004488988400080000a09aa90a0067776004444440
066666666666655054444445dddddddd8555558885555588449aaa4400000000000000000000000008999800448999840084800009aa9a900677600004444440
066666666666655059444445d0d0d0dd85555588855555884499a4440000000000000000000000000889880044889884008480009aaaa9a96776000004444440
065565665556655065444956dddddddd8555558885555588444554440000000000000000000000000088800044488844087448009aaaaaa96776000004444440
066666666666655065444956d00000dd855555888555558844455444000000000000000000000000000b00004444b4440877480009aaaa900677600004444440
066555666556655065444956d00000dd855555888555558844455444000000000000000000000000000bb0004444bb4400888000a09aa90a0067776004444440
066666666666655065555556dddddddd85555588855555884445544400000000000000000000000000bb0000444bb444000800000a0990a00006660000000000
00000000000000000000000000000000000000000000000077770111011111111111111011106666444444440000000044444444444444440000000000000000
20222222022222222222222222222222222222202222222077770111011111111111111011106666444444440c777c7044444444444444440000000000000000
2022222202222222222222222222222222222220222222207777011100000000000000001110666644777444077cc77044444444444444440000000000000000
202222220222222222222222222222222222222022222220777701110111111111111110111066664000004407c777c044444444333333440000000000000000
20222222022222222222222222222222222222202222222077770ddd0dddddddddddddd0ddd066664000004400000000444444443bb333440000000000000000
20222222022222222222222222222222222222202222222077770ddd0dddddddddddddd0ddd0666640000044444004444444444444ddeedd0000000000000000
202222220000000000000000000000000000000022222220777700dd0000000000000000dd006666444444444440044444444444888888880000000000000000
2022222202222222222222222222222222222220222222207777700001111111111111100006666644444444400000044444444488a8a8880000000000000000
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd1000000000444444444444444444444444000000000000000000000000
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd10000000004aab44444000000444444444000000000000000000000000
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001ddd1dddd1ddd10000000004baa44444000000444444444000000000000000000000000
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd1000000000444444444000000444458d44000000000000000000000000
02eeeeee00000000000000000000000000000000eeeeee2000000000011dddddddddd110000000004444444444444444444ccc44000000000000000000000000
02eeeeee02222222222222220222222222222220eeeeee20000000000011dddddddd1100000000004444444444444444444ccc44000000000000000000000000
0222222202eeeeeeeeeeeee202eeeeeeeeeeee2022222220000000007001111111111006000000004444444444444444444ccc44000000000000000000000000
6000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000700000000770000000000006600000000444444444444444444444444000000000000000000000000
0000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002eeeeee0eeeeee202eeeeee0eeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000022222222222222202222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
402021010121202101010101010101010121202101010121202020202020210101212040000000000000a0d1e0e0e0e0e0e0e0e0e0e0e0e0e0d1a00000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
403121212121102121212121212121212121202101010121202020202010212121212040000000000000a0d1e0e0e0e0e0e0e0e0e0e0e0e0e0d1a00000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
402020202020202020203120202020202020202101010121201020202020202020203140000000000000a0d1e0e0e0e0e0e0e0e0e0e0e0e0e0d1a00000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
70303030303030303030303030303030303030308191a130303030303030303030303050000000000000a0d1d1d1d1d1d1d1c1d1d1d1d1d1d1d1a00000000000
000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d1e0e0e0e0e0e0e0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000
0000000000000000000000000000000000000000000000000000a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000a0a0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000000000000000000022220000000000000000000000a0a0
e1e1e1c1c1c1c1c1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e100000000000000000000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d00000000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
e1b022b0c1b0c1b022b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0223222e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c123c1b0c1b0c123c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1233323e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
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
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1c4c4c4a4b4c4c4d4c4c4c4a4b4c4c4d4b0c1b0c1b0c1b0c1b0e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c4c4c4c5b5a5c4c4c4c4c4c5b5a5c4c4c1b0c1b0c1e0e0b0c1e100000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1d4c4b0c1b0c1b0c1d2c1b0c1b0c1c4c4b0c1b0c1b0e0e0c1b0e1a0000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c4c4c1b0c1b0c1b0c1b0c1b0c1b0c4c4c1b0c1b0c1b0c1b0c1e1a0000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1a5c4b0c1b0c1b0c1b0c1b0c1b0c1c4a5b0c1b0c1b0c1b0c1b0e1a0000000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1d0
e1b0c1b0c1b0c1b0c1b0b4a4c1b0c1b0c1b0c1b0c1b0c1b0a4b4c1b0c1b0c1b0c1b0c1e1a0a00000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b5c5b0c1b0c1b0c1b0c1b0c1b0c1c5b5b0c1b0c1b0c1b0c1b0e1a0a00000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a00000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a00000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a00000000000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a0a0a0a0a000000000000000d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a0a0a0a0a0000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a0a0a0a0a0000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c1b0c1b0c1b0041434344454c1b0c1b0c1b0c1b0c1041434344454b0c1b0c1b0c1e1a0a000000000000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a0a0000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1c1b022b0c1b0c1051525154555b022b06474849422b0051525154555c1b0c1b022b0e1a0a000000000000000000000f3d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1b0c123c1b0c1b0c116261646b0c123c1b07585c123c1b016261646c1b0c1b0c123c1e1000000000000000000000000a0d0d1d1d1d1d1d1d1d1d1d1d1d1d1d1
d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a000000000c0c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c0
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e100000000000000000000000000d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0a0a0000000c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
__gff__
0000000101000001010001000000000000000100010100000000000000000100010101010000000000000000000000000101010100000000000000000000000001010101010101010101010101010000010101010101000101000101010000000001010101000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0803030303030303030303030303030303030303030303030303030303030303030303060000000000000a1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0a00000000000000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e
0412173610122021121212020102020202021302020202021212122021120213020202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04122736101230313b3b1202020213020201020202020201123b3b3031120202020202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010121010101012121212121212121212121212121210101010121212120201040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
041210101010101010101010101010101010101010101010101010101010101012020204000000000a0a0a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
041210101010101010101010101010101010101010101010101010101010101012130204000000000a1d1d1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
041210101012121212121212121212121212121212121212121212121212101012020104000000000a1d1d1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
041210101012021302020202020202020202020202021312101010202112101012020204000000000a0a001d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101202020202020201021212122021120202021210103b303112101012020204000000000a0a0a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121212121212123b3b303112020102121010121212121010120202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e251d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120102121010101010101010101012020213121010121212121010121302040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010101010101010101012020202121010101010101010120202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010121212121212101012130202121010101010101010120202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010120201020212101012020202121212121212121212120202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120201121010120202021312101012020202020202020112122021121202040000000000000a1d240e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101212121210101202020202121010120212121212121212123b30313b1202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012011210101010101010101010101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012021210101010101010101010101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412121212121212121212120202020112101012021210101212121212121210101202040000000000000a1d340e0e0e0e0e0e0e0e0e0e0e251d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402010202020202130201020212121212101012121210101202021302021210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402122021121202020202020212101010101010101010101201020202021210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04021230313b1202020202021312101010101010101010101202020201021210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101212121212121212101012121212121212121202020202021210101201040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d1d1d000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012021302020202020202010202021210101202040000000000000a1d240e0e0e0e0e0e0e0e0e0e0e0e1d1d1d000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012020212202112121202020202131210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
040112101012121210101212121212121201021230313b3b1212121212121210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120112101012010202121212120212101010101010101010101010101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202122021120212101010101010101010101010101213040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e251d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202123031120212101010121212121212121210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020201123b3b120212101010120202020202011210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012121212121010120212101010120102020202021210101202040000000000000a1d0e0e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010121312101010101010101010120112101010120202130202021210101202040000000000000a1d240e0e0e0e0e0e0e0e0e0e0e0e1d0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
