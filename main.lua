local overworld = {
  "w...............",
  "w............M..",
  "ww..........MMM.",
  "ww.........MMCMM",
  "www.............",
  "wwww............",
  "wwww............",
  "wwww............",
  "wwww............",
  "www.............",
  "www.............",
  "www.............",
  "wwww............",
  "wwwww...........",
  "wwwww...........",
  "wwwwww..........",
}

local cave = {
  "MMMMMMMMMM",
  "M,,,,,,,,M",
  "M,,,,B,,,M",
  "M,,,,,,,,M",
  "M,,,,,,,,M",
  "M,,,,,,,,M",
  "M,,,,,,,,M",
  "M,,,,,,,,M",
  "MMMCMMMMMM",
}

local playerSprite = {
  [[      ]],
  [[      ]],
  [[  O   ]],
  [[ \|/  ]],
  [[  |   ]],
  [[ / \  ]],
}

local bossSprite = {
  [[      ]],
  [[      ]],
  [[      ]],
  [[      ]],
  [[ ^88^ ]],
  [[//  \\]],
}

-- Explain loops and write this
function gameLoop()
  print("Press any key to start")
  while true do
    input.process()
    world.draw()
  end
end

-- Go over boolean and boolean operators
function can_walk_on(c)
  return c == "." or c == "C" or c == "," or c == "B"
end

-- Add to the else-if chain
function draw_tile(c)
  if c == "w" then
    io.write("\027[97;104m" .. c .. " ")
  elseif c == "." then
    io.write("\027[97;102m" .. c .. " ")
  elseif c == "@" then
    io.write("\027[97;46m" .. c .. " ")
  elseif c == "M" then
    io.write("\027[97;43m" .. c .. " ")
  elseif c == "C" then
    io.write("\027[97;40m" .. c .. " ")
  elseif c == "," then
    io.write("\027[97;41m" .. c .. " ")
  else
	io.write(c .. " ")
  end
end

playerMoves = {
	stab = {1, "You stab the boss"},
	punch = {2, "A good right hook!"},
}

bossMoves = {
	bite = {2, "The boss takes a bite out of you"},
	wobble = {0, "He lost his balance"},
}

-- Make the turn selections easy-to-use functions so we can write this part
function run_turn()
  print_opening()
  for name, m in pairs(playerMoves) do
  	print("  - " .. name)
  end

  local playerMove = get_player_move()
  print_move(playerMove)

  local bossMove = get_boss_move()
  print_move(bossMove)

  gameState.player.health = gameState.player.health - bossMove.damage
  gameState.boss.health = gameState.boss.health - playerMove.damage

  if gameState.player.health <= 0 then
	gameState.battleState = "lose"
  elseif gameState.boss.health <= 0 then
	gameState.battleState = "win"
  end
end

gameState = {
  inBattle = false,
  battleState = "open",
  currentMap = overworld,
  player = {x = 5, y = 5, health = 5},
  boss = {health = 7},
}

function print_opening()
  print("You have " .. gameState.player.health .. " health and the boss has " .. gameState.boss.health .. " health.")
  print("What will you do?")
end

function print_move(m)
  print(m.text .. " - " .. m.damage .. " Damage")
end

function find_entrance(m)
  for i = 1, #m do
    for j = 1, m[i]:len() do
      local c = m[i]:sub(j, j)
      if c:lower() == "c" then
        return j, i
      end
    end
  end
end

function on_touch(c)
  c = c:lower()
  if c == "c" then
    local player = gameState.player
    if gameState.currentMap == overworld then
      gameState.currentMap = cave
      player.x, player.y = find_entrance(gameState.currentMap)
    else
      gameState.currentMap = overworld
      player.x, player.y = find_entrance(gameState.currentMap)
    end
  elseif c == "b" then
	  gameState.inBattle = true
  end
end

function get_player_move()
  local choice = io.read()
  while not playerMoves[choice] do
  	print"Pick a move (name must be exact)"
  	choice = io.read()
  end
  
  return {damage = playerMoves[choice][1], text = playerMoves[choice][2]}
end

function get_boss_move()
  local bossMoveList = {}
  for name, _ in pairs(bossMoves) do table.insert(bossMoveList, name) end
  local bossMove = bossMoves[bossMoveList[math.random(1, #bossMoveList)]]
  
  return {damage = bossMove[1], text = bossMove[2]}
 end

world = {
  overworld = function()
    local m = gameState.currentMap
    for i = 1, #m do
      for j = 1, m[i]:len() do
        if j == gameState.player.x and i == gameState.player.y then
          draw_tile("@")
        else
          draw_tile(m[i]:sub(j, j))
        end
      end
      io.write("\027[0m\n")
    end
  end,

  battle = function()
    for i = 1, 10 do
      for j = 1, 15 do
	    -- sprite layer
		if i >= 3 and i <= 8 then
			-- player
			io.write("  " .. playerSprite[i - 3 + 1] .. "        " .. bossSprite[i - 3 + 1])
			break
		elseif i < 9 then
          io.write("  ")
        else
          io.write("\027[97;101m  ")
        end
      end
      io.write("\027[0m\n")
    end
  end,

  draw = function()
    os.execute("clear")
    if gameState.inBattle then
      world.battle()
    else
      world.overworld()
    end
  end,
}

function getch_unix()
  os.execute("stty cbreak </dev/tty >/dev/tty 2>&1")
  local key = io.read(1)
  os.execute("stty -cbreak </dev/tty >/dev/tty 2>&1")
  return key      
end

input = {
  overworld = function()
    local c = getch_unix()

    local player = gameState.player
    local currentMap = gameState.currentMap
    local oldX, oldY = player.x, player.y
    if c == "w" then
      if player.y > 1 then
        player.y = player.y - 1
      end
    elseif c == "s" then
      if player.y < #currentMap then
        player.y = player.y + 1
      end
    elseif c == "a" then
      if player.x > 1 then
        player.x = player.x - 1
      end
    elseif c == "d" then
      if player.x < #currentMap[1] then
        player.x = player.x + 1
      end 
    end

    local tile = currentMap[player.y]:sub(player.x, player.x)
    if not can_walk_on(tile) then
      player.x = oldX
      player.y = oldY
    else
      on_touch(tile)
    end
  end,

  battle = function()
    if gameState.battleState == "open" then
      gameState.battleState = "turnSelection"
    elseif gameState.battleState == "turnSelection" then
      run_turn()

      print("(Enter to continue)")
      io.read()
    elseif gameState.battleState == "win" then
      os.execute("clear")
      print("You win :)")
      print()
      print("Credits:")
      print("  Writer: Nicholas Casto")
      print("  Director: Nicholas Casto")
      print("  Lead Actor: Nicholas Casto")
      print("  The Important Bits: You")
      os.exit()
    elseif gameState.battleState == "lose" then
      os.execute("clear")
      print("You lose :(")		
      print()
      print("Credits:")
      print("  Writer: Nicholas Casto")
      print("  Director: Nicholas Casto")
      print("  Lead Actor: Nicholas Casto")
      print("  The Important Bits: You")
      os.exit()
    end
  end,

  process = function()
    if gameState.inBattle then
      input.battle()
    else
      input.overworld()
    end
  end,
}

gameLoop()
