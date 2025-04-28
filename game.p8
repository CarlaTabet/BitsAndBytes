pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

id_card_collected = false
id_card = nil
button = nil
cameras = {}
intro = true
page = 1
max_page = 5

rooms = {
    --Name of room, x,y is top right corner and w,h is how big it is
    start = {x=91, y=43, w=16, h=12},
    graveyard = {x=0,y=0,w=36,h=36},
    room1 = {x=0,y=39,w=36,h=25},
    room2 = {x=43, y=0, w=13, h=36},
    lab = {x=49, y=39, w=42, h=25},
	storage_closet = {x=107, y= 39, w=21, h = 15}
}

exits = {
    {
        --Gives current room, destination when leaving room, 
        --px,py is where the player ends up
        --condition function is where the player needs to be in order to exit
        room = "graveyard", 
        dest="room1", 
        px=42, 
        py=316,
        condition = function()
            if player.x >= 160 and player.x <= 178 and player.y==274 then
                if not puzzle_solved and not puzzle_active then
                    puzzle_active = true
                    selected_dial = 1
                    symbols = {40,41,42,43,44}
				    correct_combo = {1, 2, 3}
				    current_combo = {1, 1, 1}
                    return false
                end
                return puzzle_solved
            end
            return false 
        end
    },
    {
        room = "room1",
        dest = "graveyard",
        px = 165,
        py = 260,
        condition= function()
            return player.x >= 24 and player.x <= 51 and player.y <= 314
        end
    },
    {
        room = "room1",
        dest = "room2",
        px = 352,
        py = 45,
        condition = function()
            return id_card_collected and player.x >= 274 and player.x <=280 and player.y >=379 and player.y <= 398
        end
    },
    {
        room = "graveyard",
        dest = "room2",
        px = 353,
        py = 45,
        condition = function()
            return player.x == 49 and player.y == 25
        end
    },
    {
        room = "room2",
        dest = "room1",
        px = 273,
        py = 389,
        condition = function()
            return player.x >= 340 and player.x <= 352 and player.y >= 36 and player.y <= 54
        end
    },
    {
        room = "room2",
        dest = "lab",
        px = 400,
        py = 336,
        condition = function ()
            return player.x >= 444 and player.x <= 457 and player.y >= 252 and player.y <= 267
       end
    },
    {
        room = "lab",
        dest = "room2",
        px = 443,
        py = 264,
        condition = function ()
            return player.x >= 392 and player.x <= 399 and player.y >= 323 and player.y <= 342
       end
    },
    {
        room = "room2",
        dest = "storage_closet",
        px = 1009,
        py = 351,
        condition = function ()
            return player.x >= 340 and player.x <= 352 and player.y >= 252 and player.y <= 267
       end
    },
        {
        room = "storage_closet",
        dest = "room2",
        px = 353,
        py = 264,
        condition = function ()
            return player.x >= 1009 and player.x <= 1015 and player.y >= 339 and player.y <= 360
       end
    },
    {
        room = "start",
        dest = "graveyard",
        px = 28,
        py= 10,
        condition = function()
            return player.x >=778 and player.x <= 796 and player.y >=426
        end
    },
    {
        room = "graveyard",
        dest = "start",
        px =  784,
        py= 422,
        condition = function()
            return player.x >=16 and player.x <= 37 and player.y == 1
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
lab_puzzle_active = false
potion_created = false


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
            if mget(tx, ty) == 60 or mget(tx, ty) == 57 then 
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
    message = ""
    message_timer = 0
	puzzle_solved = false
    player = {
        x = 784,
        y = 368,
        frame = 1,
        anim_timer = 0,
        frames = {
            {105, 106, 121, 122},
            {107, 108, 123, 124}
        },
        speed = 3
    }

    current_room = "start"

    blood = 0
    flower = 0
	
    --Doors
    --add_door("room2", 43, 5, "left")   
   -- add_door("room2", 57, 32, "right")
   -- add_door("room2", 43, 32, "left")
   -- add_door("room1", 35, 48, "right")
   -- add_door("lab", 49, 41, ",left")
    --add_door("storage_closet", 127, 43, "right")
    
	load_cameras_from_map()    
	load_button_from_map()					
	spawn_blood_drop(25, 58)
	load_flowers_from_map()
    load_blood_drops_from_map()
    load_id_card_from_map()
    time_elapsed = 0
    max_time = 300 * 60 -- 5 minutes
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
    print(chr(148), 103, 60, 5)
    print(chr(131), 103, 68, 5 )

end

function update_lab_puzzle()
    if btnp(5) then
        if flower >= 3 then
            potion_created = true
        end
        lab_puzzle_active = false
    end
end


function _update()
    if intro then
        if btnp(4) then
            page +=1
        elseif btnp(5) then
            intro = false
        end

        if page > max_page then
            intro = false
        end
    else



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
				
				if current_room == "lab" then
	    local tx = flr(player.x / 8)
	    local ty = flr(player.y / 8)
	    if mget(tx, ty) == 102 or mget(tx + 1, ty) == 102 or mget(tx, ty + 1) == 102 or mget(tx + 1, ty + 1) == 102 then
	        if btnp(5) then
	            lab_puzzle_active = not lab_puzzle_active
	        end
	    end
				end

    
    time_elapsed = min(time_elapsed + 1, max_time)
    for drop in all(blood_drops) do
    drop.float_offset = sin(time() + drop.x) * 2
    	if not drop.collected and abs(player.x - drop.x) < 8 and abs(player.y - drop.y) < 8 then
        drop.collected = true
        player_collect_blood()
        if current_room == "storage_closet" then
	        local tx = flr(drop.x / 8)
					    local ty = flr(drop.y / 8)
					    mset(tx, ty, 11)
				    end
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
			
			if current_room == "lab" and btnp(5) then
    lab_puzzle_active = not lab_puzzle_active
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

function draw_signs()
    if current_room == "room2" then
        local sx = 47 * 8
        local sy = 32 * 8

        rectfill(sx - 4, sy - 12, sx + 70, sy+5, 5) -- brown background
        rect(sx - 4, sy - 12, sx + 70, sy+5, 7) -- white border
        print("<- storage closet", sx, sy - 10, 7)
        print("laboratory ->", sx, sy - 2, 7)
       
    end
end



function draw_riddle()
    rectfill(8, 96, 120, 124, 0)
    rect(8, 96, 120, 124, 7)
    print("the eye that sees", 14, 100, 6)
    print("the claw that strikes", 14, 108, 6)
    print("the flame that guides", 14, 116, 6)
end


function draw_lab_puzzle()
				print("drawing lab puzzle!", 0, 120, 11)
    rectfill(20, 40, 108, 90, 0)
    rect(20, 40, 108, 90, 7)
    print("ancient recipe:", 32, 48, 10)
    print("requires 3 flowers", 26, 60, 6)
    print("press ❎ to close", 30, 78, 5)
end

function center(txt, x, y, col)
    local w = #txt *4
    local x = 64 - w/2
    print(txt, x, y, col)
end

function _draw()
    if intro then
        cls(0)
        if page == 1 then
            center("DRACULA, WELCOME TO...", 45, 40, 8)
            center("blood heist", 45, 60, 8)
            center("blood heist", 45, 60, 8)
            if (time() % 2) < 1.3 then
                center("press z to continue", 45, 110, 5)
                center("or press x to start game", 45, 120, 5)
            end
        elseif page == 2 then
            center("IT IS A DARK AND RAINY EVENING.", 45, 40, 8)
            center("YOU HAVE JUST WOKEN", 45, 50, 8)
            center("UP WITH NO ENERGY...", 45, 60, 8)
            center("and a strong thirst for blood...", 45, 70, 8)
            center("and a strong thirst for blood...", 45, 70, 8)
            if (time() % 2) < 1.3 then
                center("press z to continue", 45, 110, 5)
                center("or press x to start game", 45, 120, 5)
            end
        elseif page == 3 then
            center("to reenergize, you must get to", 45, 50, 8)
            center("the hospital and steal blood", 45, 60, 8)
            center("but beware...", 45, 70, 8)
            if (time() % 2) < 1.3 then
                center("press z to continue", 45, 110, 5)
                center("or press x to start game", 45, 120, 5)
            end
        elseif page == 4 then
            center("you must avoid any people", 45, 50, 8)
            center("and solve puzzles", 45, 60, 8)
            center("to reach the blood.", 45, 70, 8)
            center("you have until sunrise...", 45, 90, 8)
            if (time() % 2) < 1.3 then
                center("press z to continue", 45, 110, 5)
                center("or press x to start game", 45, 120, 5)
            end
        elseif page == 5 then
            center("good luck.", 45, 50, 8)
            center("p.s. its a nice night", 45, 70, 8)
            center("to pick some flowers,", 45, 80, 8)
            center("don't you think?", 45, 90, 8)
            if (time() % 2) < 1.3 then
                center("press z or x to start game", 45, 120, 5)
            end
        end

    else


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
    palt(15, true)
    draw_player()
    palt(15, false)
    palt(0,true)
    
    for drop in all(blood_drops) do
        if not drop.collected then
            local draw_x = drop.x - cam_x
            local draw_y = drop.base_y + drop.float_offset - cam_y
            spr(60, draw_x, draw_y)
        end
    end
   
				if current_room == "lab" then
	    draw_lab_puzzle()
				end
			

    if id_card and not id_card.collected then
        spr(45, id_card.x - cam_x, id_card.y - cam_y)
    end

    if current_room == "graveyard" or current_room == "start" then
        draw_mist(cam_x, cam_y)
        draw_darkness(cam_x, cam_y)
        if puzzle_active then
					    	draw_puzzle()
							   draw_riddle()
								end
    end
    if current_room == "room2" then
    	draw_camera_vision() 
    	draw_signs()
    end
    if current_room == "lab" and not potion_created then
				  local tx = flr(player.x / 8)
				  local ty = flr(player.y / 8)
				    if mget(tx, ty) == 102 or mget(tx + 1, ty) == 102 or mget(tx, ty + 1) == 102 or mget(tx + 1, ty + 1) == 102 then
				        print("press ❎ to view recipe", player.x - 20, player.y - 10, 0)
				    end
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
    print("x="..player.x.." y="..player.y, 40, 0, 8)
    local tile_x = flr(player.x / 8)
    local tile_y = flr(player.y / 8)   
    print("map pos: ("..tile_x..","..tile_y..")", 40, 40, 8)
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

function draw_player()
    local f = player.frames[player.frame]
    spr(f[1], player.x, player.y)
    spr(f[2], player.x+8, player.y)
    spr(f[3], player.x, player.y+8)
    spr(f[4], player.x+8, player.y+8)
end

function player_update()
    player.anim_timer +=1
    if player.anim_timer >3 then
        player.anim_timer = 0
        player.frame = 3-player.frame
    end
    
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
                       is_walkable(new_x + 10, player.y) and
                       is_walkable(new_x, player.y + 10) and
                       is_walkable(new_x + 10, player.y + 11)

    local can_move_y = is_walkable(player.x, new_y) and
                       is_walkable(player.x + 10, new_y) and
                       is_walkable(player.x, new_y + 10) and
                       is_walkable(player.x + 10, new_y + 11)

    if can_move_x then player.x = new_x end
    if can_move_y then player.y = new_y end

end

function room_change()
    for exit in all(exits) do 
        if exit.room == current_room and exit.condition() then
            current_room = exit.dest
            --if exit.dest == "lab" then
			--	puzzle_active = false
			--end
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

    if time_elapsed >= max_time then
        game_over = true
    end
end






__gfx__
000000003355553333333333661666161616111666666666661111116666666611111166600000060000000066666666ddddddddeeeeeeee8888888811000011
000000005556655533333333611161116666666661161616611111116161611611111116005005000000000066666666ddddddddeeeeeeee8888888810044001
000000005666666533333333611161111616111661161611666666111161611611666666055555500000000066666666ddddddddeeeeeeee8888888810444401
000000005666666533333333611161111616111166661611611116111161666611611116050550500000000066666666ddddddddeeeeeeee8888888804444440
000000005556655533333333666666661616111661111611666616111161111611616666555555550000000066666666ddddddddeeeeeeee8888888804444440
000000003356653333333333611161116666666666666611611616111166666611616116550000550000000066666666ddddddddeeeeeeee8888888804444440
000000003356653333333333666666661616111661111111611616161111116661616116657557560000000066666666ddddddddeeeeeeee8888888804444440
000000003355553333333333611161111616111166111111666666661111116666666666665555660000000066666666ddddddddeeeeeeee8888888804444440
4444444400000000b33b3b3b3338883344444444000002202200002244000044111666666666666666666111cccccccc77777777222222221111111104444440
44444444000000003b33b3333388988344ffff4400ffff2020022002405555041161111111111111111116117777cccc77777777222222221111111104444040
4444444400000000333333b3338999834ffffff40ffffff02022220205566550161111111111111111111161cccccccc77777777222222221111111104444040
4444444400000000b3b3b3bb338898834f5ff5f40f5ff5f00222222005666650611116666666666666666116cccccccc77777777222222221111111104444440
444444440000000033333333333888334ffffff40ffffff00222222005600650611161616116116116161611cccccccc77777777222222221111111104444440
4444444400000000b3b3b33b3333b3334f5555f40ff555f00222222005600650611611616116116116161161cccc77cc77777777222222221111111104444440
4444444400000000333b33333333bb334ffffff40ffffff00222222006000060611611616116116116161161cccccccc77777777222222221111111104444440
4444444400000000b3b33b3b333bb33344cffc44007ff7000222222006600660611611616116116116161161cccccccc77777777222222221111111104444440
333300000000333377777333dddddddddddddddddddddddd02222220066006600000000000800800000080000006600070000007000990000000000004444440
3300555555550033b33733b3daaaaadd555555dddd55555502222220056006500077770000700700000888000066760077000077777777770000000004444440
3066666666655503bbb3bbb3daeaead05555555555555555022222200560065007088070800000080088988000677600707777077ccc66670000000004444440
06666666666655503bbbbb33daaaaad05555666006665555022222200560065070088007700770070889998006677760706006077c4c68670000000000000000
0666666666666550773b3377da9abad05555686006865555022222204056650407088070007777000899a98066777760070008807cfc88870000000011111111
06655665655665507773b777daaaaad0000066600666000002222220405665040077770000777700089aaa906777776000777780711168670000000011111111
06656566656565507773b777da8a2adddd000000000000dd02222220440550440000000000777700009aaa900777766000000080711166670000000011111111
06655665655665507773b777daaaaadd0000dddddddd000000000000440000440000000000000000000aaa000077760000000080777777770000000011111111
066565656566655055555555daeacaddddaaaddddddddddd444a94444544455477777777666866660088800044488844000800000a0990a00006660099999999
066565656566655054449995daaaaaddddaaadddddaaaddd44499944444554457777777766686666088988004488988400080000a09aa90a0067776099999999
066666666666655054444445ddddddddd55555ddd55555dd449aaa4455544444777777776684866608999800448999840084800009aa9a900677600099999999
066666666666655059444445d0d0d0ddd55555ddd55555dd4499a4444444555577777777668486660889880044889884008480009aaaa9a96776000099999999
065565665556655065444956ddddddddd55555ddd55555dd444554444554444477777777687448660088800044488844087448009aaaaaa96776000099999999
066666666666655065444956d00000ddd55555ddd55555dd44455444544454457777777768774866000b00004444b4440877480009aaaa900677600099999999
066555666556655065444956d00000ddd55555ddd55555dd44455444444544547777777766888666000bb0004444bb4400888000a09aa90a0067776099999999
066666666666655065555556ddddddddd55555ddd55555dd4445544455544544777777776668666600bb0000444bb444000800000a0990a00006660099999999
00000000000000000000000000000000000000000000000077770111011111111111111011106666444444440000000044444444444444444444000000004444
20222222022222222222222222222222222222202222222077770111011111111111111011106666444444440c777c7044444444444444444440055555500444
2022222202222222222222222222222222222220222222207777011100000000000000001110666644777444077cc77044444444444444444400556666550044
202222220222222222222222222222222222222022222220777701110111111111111110111066664000004407c777c044444444333333444005566666655004
20222222022222222222222222222222222222202222222077770ddd0dddddddddddddd0ddd066664000004400000000444444443bb333444055666666665504
20222222022222222222222222222222222222202222222077770ddd0dddddddddddddd0ddd0666640000044444004444444444444ddeedd0056666666666500
202222220000000000000000000000000000000022222220777700dd0000000000000000dd006666444444444440044444444444888888880556666006666550
2022222202222222222222222222222222222220222222207777700001111111111111100006666644444444400000044444444488a8a8880566666006666650
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd1000000000444444444444444444444444444555550566666006666650
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd10000000004aab44444000000444444444444555550566600000066650
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001ddd1dddd1ddd10000000004baa44444000000444444444444555550566600000066650
02eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee200000000001dddddddddddd1000000000444444444000000444458d44444555550566666006666650
02eeeeee00000000000000000000000000000000eeeeee2000000000011dddddddddd110000000004444444444444444444ccc44444555550566666006666650
02eeeeee02222222222222220222222222222220eeeeee20000000000011dddddddd1100000000004444444444444444444ccc44444555550566666006666650
0222222202eeeeeeeeeeeee202eeeeeeeeeeee2022222220000000007001111111111006000000004444444444444444444ccc44444555550566666006666650
6000000002eeeeeeeeeeeee202eeeeeeeeeeee200000000700000000770000000000006600000000444444444444444444444444444555550566666006666650
0000000002eeeeeeeeeeeee202eeeeeeeeeeee2000000000555555550000000000000000fff000000ffffffffff000000fffffff555554440566666666666650
0000000002eeeeeeeeeeeee202eeeeeeeeeeee2000000000566666650000000000000000ff00600600ffffffff00600600ffffff555554440566666666666650
0000000002eeeeee0eeeeee202eeeeee0eeeee2000000000565565650000000000000000f6066666606ffffff6066666606fffff555554440566666666666650
0000000002eeeeeeeeeeeee202eeeeeeeeeeee2000000000566666650000000000000000f6060660606ffffff6060660606fffff555554440566666666666650
0000000002eeeeeeeeeeeee202eeeeeeeeeeee2000000000565655650000000000000000f6660660666ffffff6660660666fffff555554440566666666666650
0000000002eeeeeeeeeeeee202eeeeeeeeeeee2000000000566666650000000000000000ff66666666ffffffff66666666ffffff555554440566666666666650
000000000222222222222222022222222222222000000000565565650000000000000000ff66000066ffffffff66000066ffffff555554440555555555555550
000000006000000000000000000000000000000600000000555555550000000000000000000676676000fffffff676676fffffff555554440000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000f0006666000fffffff00666600ffffff444444455444444400000000
000000000000000000000000000000000000000000000000000000000000000000000000ff00000000fffffff0000000000fffff444444555544444400000000
000000000000000000000000000000000000000000000000000000000000000000000000fff000000fffffff000000000000ffff444445555554444400000000
000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffff00ffffff00fffff444455555555444400000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff444555555555544400000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff444555555555544400000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff444555555555544400000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff444555555555544400000000
402021010121202101010101010101010121202101010121202020202020210101212040a000000000a0a0f0c0c0c0c0c0c0c0c0c0c0c0c0c0f0a0a000000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
403121212121102121212121212121212121202101010121202020202010212121212040a0000000a0a0a0f1c0c0c0c0c0c0c0c0c0c0c0c0c0f1a0a0e2000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
402020202020202020203120202020202020202101010121201020202020202020203140a0000000a0a0a0f2c0c0c0c0c0c0c0c0c0c0c0c0c0f2a000e2000000
000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0
70303030303030303030303030303030303030308191a130303030303030303030303050a00000000000a0e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1a0a000000000
000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0d1e0e0e0e0e0e0e0
a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000
0000000000000000000000000000000000000000000000000000a0a0a0a000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
e1e1e1c1c1c1c1c1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1a00000000000000000000000a0e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1a00000000000000000000000000000a0e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
e1b022b0c1b0c1b022b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0223222e1a00000000000000000000000a0e1c1c1c4c4a5b4a4c4c4c4b4a4c4c4
d4c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a00000000000000000000000000000a0e12232b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1c123c1b0c1b0c123c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1233323e1a00000000000000000000000a0f0c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a00000000000000000000000000000a0e12333b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a00000000000000000000000a0f1c1c1c1c1c1c1c166c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0e1b0b0b0b0b0b0b093b0b0b0b0b0b0b093b0b0b0e1
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a00000000000000000000000a0f2c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e180303030303030303030303030303060e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0f0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140212121212121212121212121212140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0f1
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1402163010101d7e4f4e7010101632140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0f2
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1402101010101d5e5f5d6010101012140e1b0b0b093b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1c1b0c1b0c1b0c1b0c1c4c4c4a4b4c4c4d4c4c4c4a4b4c4c4d4b0c1b0c1b0c1b0c1b0e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1402101010101d5e6f6d6010101012140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1b0c1b0c1b0c1b0c1b0c4c4c4c5b5a5c4c4c4c4c4c5b5a5c4c4c1b0c1b0c1b0c1b0c1f0a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140210101010101010101010101012140e1b0b0b0b0b0b0b0b0b0b093b0b0b0b0b0b0b0b0e1
e1c1b0c1b0c1b0c1b0c1d4c4b0c1b0c1b0c1d2c1b0c1b0c1c4c4b0c1b0c1b0c1b0c1b0f1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140210101010101010101010101012140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1b0c1b0c1b0c1b0c1b0c4c4c1b0c1b0c1b0c1b0c1b0c1b0c4c4c1b0c1b0c1b0c1b0c1f2a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140210101010101010101010101012140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1c1b0c1b0c1b0c1b0c1a5c4b0c1b0c1b0c1b0c1b0c1b0c1c4a5b0c1b0c1b0c1b0c1b0e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140210101010101010101010101012140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1b0c1b0c1b0c1b0c1b0b4a4c1b0c1b0c1b0c1b0c1b0c1b0a4b4c1b0c1b0c1b0c1b0c1e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140216301010101010101010101632140e1b0b0b0b093b0b0b0b0b0b0b0b0b093b0b0b0b0e1
e1c1b0c1b0c1b0c1b0c1b5c5b0c1b0c1b0c1b0c1b0c1b0c1c5b5b0c1b0c1b0c1b0c1b0e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140212121212101010101212121212140e1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0e1
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e140203120202101010101211020202040e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a0a0a0a0a0000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1e1a0a0a0a0a0a0000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0c1b0e1a0a0a0a0a0a0000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1b0c1b0c1b0c1b0041434344454c1b0c1b0c1b0c1b0c1041434344454b0c1b0c1b0c1e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1c1b022b0c1b0c1051525154555b022b06474849422b0051525154555c1b0c1b022b0e1a0a000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1b0c123c1b0c1b0c116261646b0c123c1b07585c123c1b016261646c1b0c1b0c123c1e1a00000000000000000000000a0e1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1e1a0000000000000000000000000000000000000000000000000000000000000000000000000
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1a00000000000000000000000a0e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1
e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1a0a00000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000101000001010001000000000000000100010100000000000000000000010101010000000000000000000000000101010100000000000000000000000001010101010101010101010101010000010101010101000101000101010000000001010101000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0412101010101202020202020202020202020202020202020202020202020202020202040a00000000000a1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e0a00000000000000000e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e
0412101010101212120202020102020202021302020202021212122021120213020202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
041210101010202112121202020213020201020202020201123b3b3031120202020202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101030313b3b12121212121212121212121212121210101010121212120201040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010101010101010101010101010101010101010101010120202040a0000000a0a0a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010101010101010101010101010101010101010101010121302040a0000000a0a0a0f0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010121212121212121212121212121212121212121212121212121010120201040a0000000a0a0a1f0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120213020202020202020202020202020213121010102021121010120202040a0000000a0a002f0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101202020202020201021212122021120202021210103b3031121010120202040a0000000a0a0a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121212121212123b3b303112020102121010121212121010120202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c251e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120102121010101010101010101012020213121010121212121010121302040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010101010101010101012020202121010101010101010120202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010121212121212101012130202121010101010101010120202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120202121010120201020212101012020202121212121212121212120202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010120201121010120202021312101012020202020202020112121220211202040a00000000000a1e240c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
04121010101212121210101202020202121010120212121212121212123b3b30311202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012011210101010101010101010101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412101010101010101010120202020212101012021210101010101010101010101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0412121212121212121212120202020112101012021210101212121212121210101202040a00000000000a1e340c0c0c0c0c0c0c0c0c0c0c251e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402010202020202130201020212121212101012121210101202021302021210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402122021120202020202020212101010101010101010101201020202021210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402123031120202020202021312101010101010101010101202020201021210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a0a000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402123b3b121212121212121212101012121212121212121202020202021210101201040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a0a000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012021302020202020202010202021210101202040a00000000000a1e240c0c0c0c0c0c0c0c0c0c0c0c1e0a0a000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010101010101010101010101012020212202112121202020202131210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
040112101012121210101212121212121201021230313b3b1212121212121210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120112101012010202121212120212101010101010101010101010101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202122021120212101010101010101010101010101213040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c251e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020202123031120212101010121212121212121210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012020201123b3b120212101010120202020202011210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010120212101012121212121010120212101010120102020202021210101202040a00000000000a1e0c0c0c0c0c0c0c0c0c0c0c0c0c1e0a00000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
0402121010121312101010101010101010120112101010120202130202021210101202040a0000000a0a0a1e240c0c0c0c0c0c0c0c0c0c0c0c1e0a0a000000000000000e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e
