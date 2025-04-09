pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

player = {
    x = 16,
    y = 16,
    spd = 9
}

function is_solid(tx, ty)
    local tile = mget(tx, ty)
    return tile == 10 or tile == 18 or tile == 11 or tile == 1 or tile == 0 or tile == 3 or tile == 4 or tile == 5 or tile == 6 or tile == 7 or tile == 8
end


function draw_mist()
   for i=1, 30 do
     local mx = flr(rnd(128)) + cam_x
     local my = flr(rnd(128)) + cam_y
     pset(mx, my, 5) 
   end
end


function _init()
    -- nothing needed here for this simple test
end

function _update()
    local dx = 0
    local dy = 0

    if btn(0) then dx = -1 end
    if btn(1) then dx = 1 end
    if btn(2) then dy = -1 end
    if btn(3) then dy = 1 end

    local new_x = player.x + dx
    local new_y = player.y + dy

    local tx = flr(new_x / 8)
    local ty = flr(new_y / 8)

    if not is_solid(tx, ty) then
        player.x = new_x
        player.y = new_y
    end
end

function draw_darkness()
    camera()
    local px = player.x - cam_x
    local py = player.y - cam_y

    for y=0,127 do
        for x=0,127 do
            if ((x - px)^2 + (y - py)^2) > 30*30 then
                pset(x, y, 0) 
            end
        end
    end
end

function _draw()
    cls()

    cam_x = mid(0, player.x - 64, 36*8 - 128)
    cam_y = mid(0, player.y - 64, 36*8 - 128)
    camera(cam_x, cam_y)

    map(0, 0, 0, 0, 36, 36)
    spr(9, player.x, player.y)
    draw_mist()
    draw_darkness()
    

end
__gfx__
445555444455554444444334661666161616111666666666661111116666666611111166999999993333333333bbbbb300000000000000000000000000000000
456666545556655544444444611161116666666661161616611111116161611611111116999999993b33333b3333333300000000000000000000000000000000
56666665566666654334444461116111161611166116161166666611116161161166666699999999333333333bbbb33300000000000000000000000000000000
5666666556666665444444336111611116161111666616116111161111616666116111169999999933333333bb333b3300000000000000000000000000000000
5666556555566555444334446666666616161116611116116666161111611116116166669999999933333b33b3333bb300000000000000000000000000000000
5655666544566544444444446111611166666666666666116116161111666666116161169999999933333333b333333300000000000000000000000000000000
5666656544566544334444446666666616161116611111116116161611111166616161169999999933333333333bbb3b00000000000000000000000000000000
566666654455554444444334611161111616111166111111666666661111116666666666999999993b33333333333bbb00000000000000000000000000000000
44444444565555553333333344488844333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
44444444555555553333333344889884333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
4444444455555565333333b344899984333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
444444445565555533b3333344889884333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
44444444555565553333333344488844333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
4444444465555555b333333344443444333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
44444444555555563333333344443344333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
444444445655565533333b3344433444333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
44440000000044440000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
44005555555500440000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
40666666666555040000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666655500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06655665655665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06656566656565500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06655665655665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06656565656665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06656565656665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06556566555665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06655566655665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
06666666666665500000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000
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
40202101012120210101010101010101012120210101012120202020202021010121204000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40202121212110212121212121212121212120210101012120202020201021212121204000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40202020202020202020202020202020202020210101012120102020202020202020204000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70303030303030303030303030303030303030303030303030303030303030303030305000000000000000000000000000000000000000000000000000000000
__map__
0803030303030303030303030303030303030303030303030303030303030303030303060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120202020202020202020202020202020202020202020202020202020202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010121301020202020201020202010202020202010202020202020202020202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010121212121212121212121212121212121212121212121212121212120201040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010101010101010101010101010101010101010101010101010101010120202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010101010101010101010101010101010101013101010101010101010120202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010121212121212121212121212121212121212121010121212121010120201040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120202020202020202020202020202020202121010120202121010120202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120202020202020102020202020202020202121010120201121010121212040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
041210101012020212121212121212121212121202010212101012010212101010100a040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
041210101012010212101310101010101010101202020212101012121212131010100a040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
041210101012020212101010101010101010101202020212101010101010101010100a040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120202121010121212121212101012020202121010101010101010121212040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120202121010120201020212101012020202121212121212121212120202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010120201121010120202020212101012020202020202020102020202020202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010121212121010120202020212101012021212121212121212121212121202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010101010101010120202020212101012011210101010101010101010131202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412101010101010101010120202020212101012021213101010101010101010101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0412121212121212121212120212121212101012121210101212121212121210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402010202020202020201020212101010101010101010101202020202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121212121202020202020212101010101010101010101201020202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010101212121212121212101010101010101010101202020201021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010101010131010101010101012121212121212121202020202021210101201040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010101010101010101010101012020202020202020202010202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010101010101010101010131212020212121212120202020202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0401121310121212101012121212121202010212101010121212121212121210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120112101012202102121212120212101010101010101010101010101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120212101012303102121010120212101010101010101310101010101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120212101012020102121010120212101010121212121212121210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120212101012020201121010120212101010120202020202011210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120212131012121212121013120212101010120102020202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402121010120212101010101010101010120112101010120202020202021210101202040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
