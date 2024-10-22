local m = {}
m.__index = m

local atan2, cos, sin, atan, acos = math.atan2, math.cos, math.sin, math.atan, math.acos
local sqrt, abs, min, max, huge = math.sqrt, math.abs, math.min, math.max, math.huge

local ORIGIN = {0, 0}
local POINT_COUNT = 64
local HALF_DIAGONAL = 0.5 * math.sqrt(2)  -- of a unit square
local ANGLE_RANGE = math.pi / 4
local ANGLE_PRECISION = math.pi / 90  -- 2 degrees
local PHI = 0.5 * (-1.0 + math.sqrt(5.0))  -- golden ratio


local function centroid(points)
  local x, y = 0.0, 0.0
  for i = 1, #points do
    x = x + points[i][1]
    y = y + points[i][2]
  end
  return {x / #points, y / #points}
end


local function rotateby(points, radians)
  local c = centroid(points)
  local cos_r = cos(radians)
  local sin_r = sin(radians)

  local newpoints = {}
  for i = 1, #points do
    local qx = (points[i][1] - c[1]) * cos_r - (points[i][2] - c[2]) * sin_r + c[1]
    local qy = (points[i][1] - c[1]) * sin_r + (points[i][2] - c[2]) * cos_r + c[2]
    newpoints[i] = {qx, qy}
  end
  return newpoints
end


local function distance(p1, p2)
  local dx = p2[1] - p1[1]
  local dy = p2[2] - p1[2]
  return sqrt(dx * dx + dy * dy)
end


local function distanceAtAngle(points, template, radians)
  local newpoints = rotateby(points, radians)
  local d = 0.0
  for i = 1, #newpoints do
    d = d + distance(newpoints[i], template.points[i])
  end
  return d / #points
end


local function pathlength(points)
  local d = 0.0
  for i = 2, #points do
    d = d + distance(points[i - 1], points[i])
  end
  return d
end


local function boundingbox(points)
  local minX, maxX, minY, maxY = huge, -huge, huge, -huge
  for i = 1, #points do
    minX = min(minX, points[i][1])
    maxX = max(maxX, points[i][1])
    minY = min(minY, points[i][2])
    maxY = max(maxY, points[i][2])
  end
  return {minX, minY, maxX - minX, maxY - minY}  -- x, y, width, height
end


local function resample(points, n)
  if type(points[1]) == 'number' then
    local flatpoints = points
    points = {}
    for i = 1, #flatpoints / 2 do
      points[i] = {flatpoints[i * 2 - 1], flatpoints[i * 2]}
    end
  end

  local I = pathlength(points) / (n - 1)
  local D = 0.0
  local newpoints = {points[1]}

  local i = 2
  while i <= #points do
    local d = distance(points[i - 1], points[i])
    if (D + d) >= I then
      local qx = points[i - 1][1] + ((I - D) / d) * (points[i][1] - points[i - 1][1])
      local qy = points[i - 1][2] + ((I - D) / d) * (points[i][2] - points[i - 1][2])
      table.insert(newpoints, {qx, qy})
      points[i - 1] = {qx, qy}
      D = 0.0
    else
      D = D + d
      i = i + 1
    end
  end

  if #newpoints == n - 1 then
    table.insert(newpoints, {points[#points][1], points[#points][2]})
  end
  return newpoints
end


local function scalePoints(points, size, uniform)
  local bbox = boundingbox(points)
  local newpoints = {}
  for i = 1, #points do
    local qx, qy
    if uniform then
      local scale = max(bbox[3], bbox[4])
      qx = points[i][1] * (size / scale)
      qy = points[i][2] * (size / scale)
    else
      qx = points[i][1] * (size / bbox[3])
      qy = points[i][2] * (size / bbox[4])
    end
    newpoints[i] = {qx, qy}
  end
  return newpoints
end


local function translatePoints(points, pt)
  local c = centroid(points)
  local newpoints = {}
  for i = 1, #points do
    newpoints[i] = {
      points[i][1] + pt[1] - c[1],
      points[i][2] + pt[2] - c[2]
    }
  end
  return newpoints
end


local function vectorizePoints(points)
  local sum = 0.0
  local vector = {}
  for i = 1, #points do
    vector[#vector + 1] = points[i][1]
    vector[#vector + 1] = points[i][2]
    sum = sum + points[i][1] * points[i][1] + points[i][2] * points[i][2]
  end
  local magnitude = sqrt(sum)
  for i = 1, #vector do
    vector[i] = vector[i] / magnitude
  end
  return vector
end


local function distanceAtBestAngle(points, template)
  local a = -ANGLE_RANGE
  local b = ANGLE_RANGE
  local x1 = PHI * a + (1.0 - PHI) * b
  local f1 = distanceAtAngle(points, template, x1)
  local x2 = (1.0 - PHI) * a + PHI * b
  local f2 = distanceAtAngle(points, template, x2)

  while abs(b - a) > ANGLE_PRECISION do
    if f1 < f2 then
      b = x2
      x2 = x1
      f2 = f1
      x1 = PHI * a + (1.0 - PHI) * b
      f1 = distanceAtAngle(points, template, x1)
    else
      a = x1
      x1 = x2
      f1 = f2
      x2 = (1.0 - PHI) * a + PHI * b
      f2 = distanceAtAngle(points, template, x2)
    end
  end
  return min(f1, f2)
end


local function optimalCosineDist(v1, v2, oriented)
  local a, b = 0.0, 0.0
  for i = 1, #v1, 2 do
    a = a + v1[i] * v2[i] + v1[i + 1] * v2[i + 1]
    b = b + v1[i] * v2[i + 1] - v1[i + 1] * v2[i]
  end
  local angle = atan(b / a)
  local d = acos(a * cos(angle) + b * sin(angle))
  if oriented and abs(angle) > ANGLE_RANGE then d = d + 1 end
  return d
end


function m.new(oriented, uniform, protractor)
  local self = setmetatable({
    templates = {},
    oriented = oriented ~= false,     -- rotation-sensitive gestures
    uniform = uniform ~= false,       -- gestures uniformly scaled or left unscaled
    protractor = protractor ~= false, -- use improved faster algorithm
    capturing = {},
  }, m)
  return self
end


function m:add(name, points)
  local template = {
    name = name,
    points = resample(points, POINT_COUNT),
  }
  if not self.oriented then
    local radians = atan2(centroid(template.points)[2] - template.points[1][2],
                         centroid(template.points)[1] - template.points[1][1])
    template.points = rotateby(template.points, -radians)
  end
  template.points = scalePoints(template.points, 1, self.uniform)
  template.points = translatePoints(template.points, ORIGIN)
  template.vector = vectorizePoints(template.points)
  table.insert(self.templates, template)

  local count = 0
  for _, t in ipairs(self.templates) do
    if t.name == name then count = count + 1 end
  end
  return count
end


function m:remove(name)
  local count = 0
  for i = #self.templates, 1, -1 do
    if self.templates[i].name == name then
      count = count + 1
      table.remove(self.templates, i)
    end
  end
  return count
end


function m:clear()
  self.templates = {}
end


function m:capture(x, y)
  table.insert(self.capturing, {x, y})
end


function m:recognize(points)
  if not points then
    points = self.capturing
    self.capturing = {}
  end
  points = resample(points, POINT_COUNT)
  if #points ~= POINT_COUNT then return nil, 0 end

  if not self.oriented then
    local radians = atan2(centroid(points)[2] - points[1][2],
                         centroid(points)[1] - points[1][1])
    points = rotateby(points, -radians)
  end

  points = scalePoints(points, 1, self.uniform)
  points = translatePoints(points, ORIGIN)
  local vector = vectorizePoints(points)

  local bestDistance = huge
  local bestIndex = 1

  for i, template in ipairs(self.templates) do
    local d
    if self.protractor then
      d = optimalCosineDist(template.vector, vector, self.oriented)
    else
      d = distanceAtBestAngle(points, template)
    end
    if d < bestDistance then
      bestDistance = d
      bestIndex = i
    end
  end

  local name = self.templates[bestIndex] and self.templates[bestIndex].name
  local score = self.protractor and 1.0 / bestDistance or 1.0 - bestDistance / HALF_DIAGONAL
  return name, score, bestIndex
end


function m:toString()
  local lines = {}
  for _, template in ipairs(self.templates) do
    local points = {}
    for _, point in ipairs(template.points) do
      table.insert(points, string.format('{%.2f, %.2f}', point[1], point[2]))
    end
    local line = string.format("{ name = '%s', points = {%s} }", tostring(template.name), table.concat(points, ', '))
    table.insert(lines, line)
  end
  return '{ ' .. table.concat(lines, ',\n') .. ' }'
end


function m:fromString(gesture_definitions)
  local func = assert(load("return " .. gesture_definitions))
  local deserializedData = func()
  for _, entry in ipairs(deserializedData) do
    self:add(entry.name, entry.points)
  end
end


return m