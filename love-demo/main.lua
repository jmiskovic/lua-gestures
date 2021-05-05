local dollar = require('dollar')()
dollar.presets() -- populate gestures with presets (http://depts.washington.edu/acelab/proj/dollar/index.html)

local points = {}
local result = ''


function love.draw()
  if #points >= 4 then
    love.graphics.setLineWidth(3)
    love.graphics.line(points)
  end
  love.graphics.print('Left mouse draw to recognize gesture', 10, 10)
  love.graphics.print('Right mouse draw to record new gesture', 10, 30)
  love.graphics.print(result, 10, 60)
end

function love.mousepressed(x, y)
  points = {}
  points[#points+1] = x
  points[#points+1] = y
  -- lib also accepts nested list: points[#points+1] = {x, y} 
end

function love.mousemoved(x, y, dx, dy, istouch)
  if love.mouse.isDown(1) or love.mouse.isDown(2) then
    points[#points+1] = x
    points[#points+1] = y
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  if button == 1 then
    local name, score = dollar.recognize(points, true)
    result = string.format('%s %1.2f', name, score)
  elseif button == 2 then
    -- for simplicity all recorded gestures are stored under same name
    dollar.add('user-recorded', points)
  end
end

function love.keypressed(key)
  if key == 'backspace' then
    dollar.remove('user-recorded')
  end
end

function love.update(dt)
end
