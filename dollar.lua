--
-- Declarations
--
local NumTemplates, NumPoints, SquareSize, Origin, Diagonal, HalfDiagonal, AngleRange, AnglePrecision
local Point, Rectangle, Template, Result, DollarRecognizer, Resample, IndicativeAngle, RotateBy, ScaleTo, TranslateTo, Vectorize, OptimalCosineDistance, DistanceAtBestAngle, DistanceAtAngle, Centroid, BoundingBox, PathDistance, PathLength, Distance, Deg2Rad, Rad2Deg
local sqrt, atan2, cos, sin, atan, acos, abs, min, pi, Infinity = math.sqrt,math.atan2, math.cos, math.sin, math.atan, math.acos, math.abs, math.min, math.pi, math.huge
--
-- Point class
--
Point = function(x, y) -- constructor
    local this = {}
    this.X     = x
    this.Y     = y
    return this
end
--
-- Rectangle class
--
Rectangle = function(x, y, width, height) -- constructor
    local this  = Point(x, y)
    this.Width  = width
    this.Height = height
    return this
end
--
-- Template class: a unistroke template
--
Template = function(name, points) -- constructor
    local this    = {}
    this.Name     = name
    this.Points   = Resample(points, NumPoints)
    local radians = IndicativeAngle(this.Points)
    this.Points   = RotateBy(this.Points, -radians)
    this.Points   = ScaleTo(this.Points, SquareSize)
    this.Points   = TranslateTo(this.Points, Origin)
    this.Vector   = Vectorize(this.Points) -- for Protractor
    return this
end
--
-- Result class
--
Result = function(name, score) -- constructor
    local this = {}
    this.Name  = name
    this.Score = score
    return this
end
--
-- deg/rad helpers
--
Deg2Rad = function(d) return (d * pi / 180.0) end
Rad2Deg = function(r) return (r * 180.0 / pi) end
--
-- DollarRecognizer class constants
--
NumTemplates   = 16
NumPoints      = 64
SquareSize     = 250.0
Origin         = Point(0, 0)
Diagonal       = sqrt(SquareSize * SquareSize + SquareSize * SquareSize)
HalfDiagonal   = 0.5 * Diagonal
AngleRange     = Deg2Rad(45.0)
AnglePrecision = Deg2Rad(2.0)
Phi            = 0.5 * (-1.0 + sqrt(5.0)) -- Golden Ratio
--
-- DollarRecognizer class
--
DollarRecognizer = function() -- constructor
    --
    -- one predefined template for each unistroke type
    --
    local this         = {}
    this.Templates     = {}
    this.Templates[1]  = Template("triangle",             {Point(137,139), Point(135,141), Point(133,144), Point(132,146), Point(130,149), Point(128,151), Point(126,155), Point(123,160), Point(120,166), Point(116,171), Point(112,177), Point(107,183), Point(102,188), Point(100,191), Point(95,195), Point(90,199), Point(86,203), Point(82,206), Point(80,209), Point(75,213), Point(73,213), Point(70,216), Point(67,219), Point(64,221), Point(61,223), Point(60,225), Point(62,226), Point(65,225), Point(67,226), Point(74,226), Point(77,227), Point(85,229), Point(91,230), Point(99,231), Point(108,232), Point(116,233), Point(125,233), Point(134,234), Point(145,233), Point(153,232), Point(160,233), Point(170,234), Point(177,235), Point(179,236), Point(186,237), Point(193,238), Point(198,239), Point(200,237), Point(202,239), Point(204,238), Point(206,234), Point(205,230), Point(202,222), Point(197,216), Point(192,207), Point(186,198), Point(179,189), Point(174,183), Point(170,178), Point(164,171), Point(161,168), Point(154,160), Point(148,155), Point(143,150), Point(138,148), Point(136,148)});
    this.Templates[2]  = Template("x",                    {Point(87,142), Point(89,145), Point(91,148), Point(93,151), Point(96,155), Point(98,157), Point(100,160), Point(102,162), Point(106,167), Point(108,169), Point(110,171), Point(115,177), Point(119,183), Point(123,189), Point(127,193), Point(129,196), Point(133,200), Point(137,206), Point(140,209), Point(143,212), Point(146,215), Point(151,220), Point(153,222), Point(155,223), Point(157,225), Point(158,223), Point(157,218), Point(155,211), Point(154,208), Point(152,200), Point(150,189), Point(148,179), Point(147,170), Point(147,158), Point(147,148), Point(147,141), Point(147,136), Point(144,135), Point(142,137), Point(140,139), Point(135,145), Point(131,152), Point(124,163), Point(116,177), Point(108,191), Point(100,206), Point(94,217), Point(91,222), Point(89,225), Point(87,226), Point(87,224)});
    this.Templates[3]  = Template("rectangle",            {Point(78,149), Point(78,153), Point(78,157), Point(78,160), Point(79,162), Point(79,164), Point(79,167), Point(79,169), Point(79,173), Point(79,178), Point(79,183), Point(80,189), Point(80,193), Point(80,198), Point(80,202), Point(81,208), Point(81,210), Point(81,216), Point(82,222), Point(82,224), Point(82,227), Point(83,229), Point(83,231), Point(85,230), Point(88,232), Point(90,233), Point(92,232), Point(94,233), Point(99,232), Point(102,233), Point(106,233), Point(109,234), Point(117,235), Point(123,236), Point(126,236), Point(135,237), Point(142,238), Point(145,238), Point(152,238), Point(154,239), Point(165,238), Point(174,237), Point(179,236), Point(186,235), Point(191,235), Point(195,233), Point(197,233), Point(200,233), Point(201,235), Point(201,233), Point(199,231), Point(198,226), Point(198,220), Point(196,207), Point(195,195), Point(195,181), Point(195,173), Point(195,163), Point(194,155), Point(192,145), Point(192,143), Point(192,138), Point(191,135), Point(191,133), Point(191,130), Point(190,128), Point(188,129), Point(186,129), Point(181,132), Point(173,131), Point(162,131), Point(151,132), Point(149,132), Point(138,132), Point(136,132), Point(122,131), Point(120,131), Point(109,130), Point(107,130), Point(90,132), Point(81,133), Point(76,133)});
    this.Templates[4]  = Template("circle",               {Point(127,141), Point(124,140), Point(120,139), Point(118,139), Point(116,139), Point(111,140), Point(109,141), Point(104,144), Point(100,147), Point(96,152), Point(93,157), Point(90,163), Point(87,169), Point(85,175), Point(83,181), Point(82,190), Point(82,195), Point(83,200), Point(84,205), Point(88,213), Point(91,216), Point(96,219), Point(103,222), Point(108,224), Point(111,224), Point(120,224), Point(133,223), Point(142,222), Point(152,218), Point(160,214), Point(167,210), Point(173,204), Point(178,198), Point(179,196), Point(182,188), Point(182,177), Point(178,167), Point(170,150), Point(163,138), Point(152,130), Point(143,129), Point(140,131), Point(129,136), Point(126,139)});
    this.Templates[5]  = Template("check",                {Point(91,185), Point(93,185), Point(95,185), Point(97,185), Point(100,188), Point(102,189), Point(104,190), Point(106,193), Point(108,195), Point(110,198), Point(112,201), Point(114,204), Point(115,207), Point(117,210), Point(118,212), Point(120,214), Point(121,217), Point(122,219), Point(123,222), Point(124,224), Point(126,226), Point(127,229), Point(129,231), Point(130,233), Point(129,231), Point(129,228), Point(129,226), Point(129,224), Point(129,221), Point(129,218), Point(129,212), Point(129,208), Point(130,198), Point(132,189), Point(134,182), Point(137,173), Point(143,164), Point(147,157), Point(151,151), Point(155,144), Point(161,137), Point(165,131), Point(171,122), Point(174,118), Point(176,114), Point(177,112), Point(177,114), Point(175,116), Point(173,118)});
    this.Templates[6]  = Template("caret",                {Point(79,245), Point(79,242), Point(79,239), Point(80,237), Point(80,234), Point(81,232), Point(82,230), Point(84,224), Point(86,220), Point(86,218), Point(87,216), Point(88,213), Point(90,207), Point(91,202), Point(92,200), Point(93,194), Point(94,192), Point(96,189), Point(97,186), Point(100,179), Point(102,173), Point(105,165), Point(107,160), Point(109,158), Point(112,151), Point(115,144), Point(117,139), Point(119,136), Point(119,134), Point(120,132), Point(121,129), Point(122,127), Point(124,125), Point(126,124), Point(129,125), Point(131,127), Point(132,130), Point(136,139), Point(141,154), Point(145,166), Point(151,182), Point(156,193), Point(157,196), Point(161,209), Point(162,211), Point(167,223), Point(169,229), Point(170,231), Point(173,237), Point(176,242), Point(177,244), Point(179,250), Point(181,255), Point(182,257)});
    this.Templates[7]  = Template("zig-zag",              {Point(307,216), Point(333,186), Point(356,215), Point(375,186), Point(399,216), Point(418,186)});
    this.Templates[8]  = Template("arrow",                {Point(68,222), Point(70,220), Point(73,218), Point(75,217), Point(77,215), Point(80,213), Point(82,212), Point(84,210), Point(87,209), Point(89,208), Point(92,206), Point(95,204), Point(101,201), Point(106,198), Point(112,194), Point(118,191), Point(124,187), Point(127,186), Point(132,183), Point(138,181), Point(141,180), Point(146,178), Point(154,173), Point(159,171), Point(161,170), Point(166,167), Point(168,167), Point(171,166), Point(174,164), Point(177,162), Point(180,160), Point(182,158), Point(183,156), Point(181,154), Point(178,153), Point(171,153), Point(164,153), Point(160,153), Point(150,154), Point(147,155), Point(141,157), Point(137,158), Point(135,158), Point(137,158), Point(140,157), Point(143,156), Point(151,154), Point(160,152), Point(170,149), Point(179,147), Point(185,145), Point(192,144), Point(196,144), Point(198,144), Point(200,144), Point(201,147), Point(199,149), Point(194,157), Point(191,160), Point(186,167), Point(180,176), Point(177,179), Point(171,187), Point(169,189), Point(165,194), Point(164,196)});
    this.Templates[9]  = Template("left square bracket",  {Point(140,124), Point(138,123), Point(135,122), Point(133,123), Point(130,123), Point(128,124), Point(125,125), Point(122,124), Point(120,124), Point(118,124), Point(116,125), Point(113,125), Point(111,125), Point(108,124), Point(106,125), Point(104,125), Point(102,124), Point(100,123), Point(98,123), Point(95,124), Point(93,123), Point(90,124), Point(88,124), Point(85,125), Point(83,126), Point(81,127), Point(81,129), Point(82,131), Point(82,134), Point(83,138), Point(84,141), Point(84,144), Point(85,148), Point(85,151), Point(86,156), Point(86,160), Point(86,164), Point(86,168), Point(87,171), Point(87,175), Point(87,179), Point(87,182), Point(87,186), Point(88,188), Point(88,195), Point(88,198), Point(88,201), Point(88,207), Point(89,211), Point(89,213), Point(89,217), Point(89,222), Point(88,225), Point(88,229), Point(88,231), Point(88,233), Point(88,235), Point(89,237), Point(89,240), Point(89,242), Point(91,241), Point(94,241), Point(96,240), Point(98,239), Point(105,240), Point(109,240), Point(113,239), Point(116,240), Point(121,239), Point(130,240), Point(136,237), Point(139,237), Point(144,238), Point(151,237), Point(157,236), Point(159,237)});
    this.Templates[10] = Template("right square bracket", {Point(112,138), Point(112,136), Point(115,136), Point(118,137), Point(120,136), Point(123,136), Point(125,136), Point(128,136), Point(131,136), Point(134,135), Point(137,135), Point(140,134), Point(143,133), Point(145,132), Point(147,132), Point(149,132), Point(152,132), Point(153,134), Point(154,137), Point(155,141), Point(156,144), Point(157,152), Point(158,161), Point(160,170), Point(162,182), Point(164,192), Point(166,200), Point(167,209), Point(168,214), Point(168,216), Point(169,221), Point(169,223), Point(169,228), Point(169,231), Point(166,233), Point(164,234), Point(161,235), Point(155,236), Point(147,235), Point(140,233), Point(131,233), Point(124,233), Point(117,235), Point(114,238), Point(112,238)});
    this.Templates[11] = Template("v",                    {Point(89,164), Point(90,162), Point(92,162), Point(94,164), Point(95,166), Point(96,169), Point(97,171), Point(99,175), Point(101,178), Point(103,182), Point(106,189), Point(108,194), Point(111,199), Point(114,204), Point(117,209), Point(119,214), Point(122,218), Point(124,222), Point(126,225), Point(128,228), Point(130,229), Point(133,233), Point(134,236), Point(136,239), Point(138,240), Point(139,242), Point(140,244), Point(142,242), Point(142,240), Point(142,237), Point(143,235), Point(143,233), Point(145,229), Point(146,226), Point(148,217), Point(149,208), Point(149,205), Point(151,196), Point(151,193), Point(153,182), Point(155,172), Point(157,165), Point(159,160), Point(162,155), Point(164,150), Point(165,148), Point(166,146)});
    this.Templates[12] = Template("delete",               {Point(123,129), Point(123,131), Point(124,133), Point(125,136), Point(127,140), Point(129,142), Point(133,148), Point(137,154), Point(143,158), Point(145,161), Point(148,164), Point(153,170), Point(158,176), Point(160,178), Point(164,183), Point(168,188), Point(171,191), Point(175,196), Point(178,200), Point(180,202), Point(181,205), Point(184,208), Point(186,210), Point(187,213), Point(188,215), Point(186,212), Point(183,211), Point(177,208), Point(169,206), Point(162,205), Point(154,207), Point(145,209), Point(137,210), Point(129,214), Point(122,217), Point(118,218), Point(111,221), Point(109,222), Point(110,219), Point(112,217), Point(118,209), Point(120,207), Point(128,196), Point(135,187), Point(138,183), Point(148,167), Point(157,153), Point(163,145), Point(165,142), Point(172,133), Point(177,127), Point(179,127), Point(180,125)});
    this.Templates[13] = Template("left curly brace",     {Point(150,116), Point(147,117), Point(145,116), Point(142,116), Point(139,117), Point(136,117), Point(133,118), Point(129,121), Point(126,122), Point(123,123), Point(120,125), Point(118,127), Point(115,128), Point(113,129), Point(112,131), Point(113,134), Point(115,134), Point(117,135), Point(120,135), Point(123,137), Point(126,138), Point(129,140), Point(135,143), Point(137,144), Point(139,147), Point(141,149), Point(140,152), Point(139,155), Point(134,159), Point(131,161), Point(124,166), Point(121,166), Point(117,166), Point(114,167), Point(112,166), Point(114,164), Point(116,163), Point(118,163), Point(120,162), Point(122,163), Point(125,164), Point(127,165), Point(129,166), Point(130,168), Point(129,171), Point(127,175), Point(125,179), Point(123,184), Point(121,190), Point(120,194), Point(119,199), Point(120,202), Point(123,207), Point(127,211), Point(133,215), Point(142,219), Point(148,220), Point(151,221)});
    this.Templates[14] = Template("right curly brace",    {Point(117,132), Point(115,132), Point(115,129), Point(117,129), Point(119,128), Point(122,127), Point(125,127), Point(127,127), Point(130,127), Point(133,129), Point(136,129), Point(138,130), Point(140,131), Point(143,134), Point(144,136), Point(145,139), Point(145,142), Point(145,145), Point(145,147), Point(145,149), Point(144,152), Point(142,157), Point(141,160), Point(139,163), Point(137,166), Point(135,167), Point(133,169), Point(131,172), Point(128,173), Point(126,176), Point(125,178), Point(125,180), Point(125,182), Point(126,184), Point(128,187), Point(130,187), Point(132,188), Point(135,189), Point(140,189), Point(145,189), Point(150,187), Point(155,186), Point(157,185), Point(159,184), Point(156,185), Point(154,185), Point(149,185), Point(145,187), Point(141,188), Point(136,191), Point(134,191), Point(131,192), Point(129,193), Point(129,195), Point(129,197), Point(131,200), Point(133,202), Point(136,206), Point(139,211), Point(142,215), Point(145,220), Point(147,225), Point(148,231), Point(147,239), Point(144,244), Point(139,248), Point(134,250), Point(126,253), Point(119,253), Point(115,253)});
    this.Templates[15] = Template("star",                 {Point(75,250), Point(75,247), Point(77,244), Point(78,242), Point(79,239), Point(80,237), Point(82,234), Point(82,232), Point(84,229), Point(85,225), Point(87,222), Point(88,219), Point(89,216), Point(91,212), Point(92,208), Point(94,204), Point(95,201), Point(96,196), Point(97,194), Point(98,191), Point(100,185), Point(102,178), Point(104,173), Point(104,171), Point(105,164), Point(106,158), Point(107,156), Point(107,152), Point(108,145), Point(109,141), Point(110,139), Point(112,133), Point(113,131), Point(116,127), Point(117,125), Point(119,122), Point(121,121), Point(123,120), Point(125,122), Point(125,125), Point(127,130), Point(128,133), Point(131,143), Point(136,153), Point(140,163), Point(144,172), Point(145,175), Point(151,189), Point(156,201), Point(161,213), Point(166,225), Point(169,233), Point(171,236), Point(174,243), Point(177,247), Point(178,249), Point(179,251), Point(180,253), Point(180,255), Point(179,257), Point(177,257), Point(174,255), Point(169,250), Point(164,247), Point(160,245), Point(149,238), Point(138,230), Point(127,221), Point(124,220), Point(112,212), Point(110,210), Point(96,201), Point(84,195), Point(74,190), Point(64,182), Point(55,175), Point(51,172), Point(49,170), Point(51,169), Point(56,169), Point(66,169), Point(78,168), Point(92,166), Point(107,164), Point(123,161), Point(140,162), Point(156,162), Point(171,160), Point(173,160), Point(186,160), Point(195,160), Point(198,161), Point(203,163), Point(208,163), Point(206,164), Point(200,167), Point(187,172), Point(174,179), Point(172,181), Point(153,192), Point(137,201), Point(123,211), Point(112,220), Point(99,229), Point(90,237), Point(80,244), Point(73,250), Point(69,254), Point(69,252)});
    this.Templates[16] = Template("pigtail",              {Point(81,219), Point(84,218), Point(86,220), Point(88,220), Point(90,220), Point(92,219), Point(95,220), Point(97,219), Point(99,220), Point(102,218), Point(105,217), Point(107,216), Point(110,216), Point(113,214), Point(116,212), Point(118,210), Point(121,208), Point(124,205), Point(126,202), Point(129,199), Point(132,196), Point(136,191), Point(139,187), Point(142,182), Point(144,179), Point(146,174), Point(148,170), Point(149,168), Point(151,162), Point(152,160), Point(152,157), Point(152,155), Point(152,151), Point(152,149), Point(152,146), Point(149,142), Point(148,139), Point(145,137), Point(141,135), Point(139,135), Point(134,136), Point(130,140), Point(128,142), Point(126,145), Point(122,150), Point(119,158), Point(117,163), Point(115,170), Point(114,175), Point(117,184), Point(120,190), Point(125,199), Point(129,203), Point(133,208), Point(138,213), Point(145,215), Point(155,218), Point(164,219), Point(166,219), Point(177,219), Point(182,218), Point(192,216), Point(196,213), Point(199,212), Point(201,211)});
    --
    -- The $1 Gesture Recognizer API begins here -- 3 methods
    --
    this.Recognize = function(points, useProtractor)
        local points  = Resample(points, NumPoints)
        if #points ~= NumPoints then
            return Result('unrecognized (too few points)', 0)
        end
        local radians = IndicativeAngle(points)
        points        = RotateBy(points, -radians)
        points        = ScaleTo(points, SquareSize)
        points        = TranslateTo(points, Origin)
        local vector  = Vectorize(points) -- for Protractor

        local b = Infinity
        local t = 1
        for i = 1, #this.Templates, 1 do -- for each unistroke template
            local d = nil
            if useProtractor then -- for Protractor
                d = OptimalCosineDistance(this.Templates[i].Vector, vector)
            else -- Golden Section Search (original $1)
                d = DistanceAtBestAngle(points, this.Templates[i], -AngleRange, AngleRange, AnglePrecision)
            end
            if d < b then
                b = d -- best (least) distance
                t = i -- unistroke template
            end
        end
        return Result(this.Templates[t].Name, useProtractor and 1.0 / b or 1.0 - b / HalfDiagonal)
    end
    --
    -- add/delete new templates
    --
    this.AddTemplate = function(name, points)
        this.Templates[#this.Templates + 1] = Template(name, points) -- append new template
        local num = 0
        for i, template in ipairs(this.Templates) do
            num = num + (template.Name == name and 1 or 0)
        end
        return num
    end
    this.DeleteUserTemplates = function()
        for i = #this.Templates, NumTemplates + 1, -1 do
            table.remove(this.Templates, i) -- clear any beyond the original set
        end

        return NumTemplates
    end
    return this
end
--
-- Private helper functions from this point down
--
Resample = function(points, n)
    local I = PathLength(points) / (n - 1) -- interval length
    local D = 0.0
    local newpoints = {points[1]}
    local i = 2
    while i <= #points do
        local d = Distance(points[i - 1], points[i])
        if (D + d) >= I then
            local qx = points[i - 1].X + ((I - D) / d) * (points[i].X - points[i - 1].X)
            local qy = points[i - 1].Y + ((I - D) / d) * (points[i].Y - points[i - 1].Y)
            local q  = Point(qx, qy)
            newpoints[#newpoints+1] = q -- append new point 'q'
            table.insert(points, i, q) -- insert 'q' at position i in points s.t. 'q' will be the next i
            D = 0.0
        else
            D = D + d
        end
        i = i + 1
    end
    -- somtimes we fall a rounding-error short of adding the last point, so add it if so
    if #newpoints == n - 1 then
        newpoints[#newpoints+1] = Point(points[#points].X, points[#points].Y)
    end
    return newpoints
end
IndicativeAngle = function(points)
    local c = Centroid(points)
    return atan2(c.Y - points[1].Y, c.X - points[1].X)
end
RotateBy = function(points, radians) -- rotates points around centroid
    local c   = Centroid(points)
    local cos = cos(radians)
    local sin = sin(radians)

    local newpoints = {}
    for i = 1, #points, 1 do
        local qx = (points[i].X - c.X) * cos - (points[i].Y - c.Y) * sin + c.X
        local qy = (points[i].X - c.X) * sin + (points[i].Y - c.Y) * cos + c.Y
        newpoints[#newpoints+1] = Point(qx, qy)
    end
    return newpoints
end
ScaleTo = function(points, size) -- non-uniform scale assumes 2D gestures (i.e., no lines)
    local B         = BoundingBox(points)
    local newpoints = {}
    for i = 1, #points, 1 do
        local qx = points[i].X * (size / B.Width)
        local qy = points[i].Y * (size / B.Height)
        newpoints[#newpoints+1] = Point(qx, qy)
    end
    return newpoints
end
TranslateTo = function(points, pt) -- translates points' centroid
    local c         = Centroid(points)
    local newpoints = {}
    for i = 1, #points, 1 do
        local qx = points[i].X + pt.X - c.X
        local qy = points[i].Y + pt.Y - c.Y
        newpoints[#newpoints+1] = Point(qx, qy)
    end
    return newpoints
end
Vectorize = function(points) -- for Protractor
    local sum    = 0.0
    local vector = {}
    for i = 1, #points, 1 do
        vector[#vector+1] = points[i].X
        vector[#vector+1] = points[i].Y
        sum = sum + points[i].X * points[i].X + points[i].Y * points[i].Y
    end
    local magnitude = sqrt(sum)
    for i = 1, #vector, 1 do
        vector[i] = vector[i] / magnitude
    end
    return vector
end
OptimalCosineDistance = function(v1, v2) -- for Protractor
    local a = 0.0
    local b = 0.0
    for i = 1, #v1, 2 do
        a = a + v1[i] * v2[i] + v1[i + 1] * v2[i + 1]
        b = b + v1[i] * v2[i + 1] - v1[i + 1] * v2[i]
    end
    local angle = atan(b / a)
    return acos(a * cos(angle) + b * sin(angle))
end
DistanceAtBestAngle = function(points, T, a, b, threshold)
    local x1 = Phi * a + (1.0 - Phi) * b
    local f1 = DistanceAtAngle(points, T, x1)
    local x2 = (1.0 - Phi) * a + Phi * b
    local f2 = DistanceAtAngle(points, T, x2)
    while abs(b - a) > threshold do
        if (f1 < f2) then
            b  = x2
            x2 = x1
            f2 = f1
            x1 = Phi * a + (1.0 - Phi) * b
            f1 = DistanceAtAngle(points, T, x1)
        else
            a  = x1
            x1 = x2
            f1 = f2
            x2 = (1.0 - Phi) * a + Phi * b
            f2 = DistanceAtAngle(points, T, x2)
        end
    end
    return min(f1, f2)
end
DistanceAtAngle = function(points, T, radians)
    local newpoints = RotateBy(points, radians)
    return PathDistance(newpoints, T.Points)
end
Centroid = function(points)
    local x, y = 0.0, 0.0
    for i = 1, #points, 1 do
        x = x + points[i].X
        y = y + points[i].Y
    end
    x = x / #points
    y = y / #points
    return Point(x, y)
end
BoundingBox = function(points)
    local minX, maxX, minY, maxY = Infinity, -Infinity, Infinity, -Infinity
    for i = 1, #points, 1 do
        if points[i].X < minX then
            minX = points[i].X
        end
        if points[i].X > maxX then
            maxX = points[i].X
        end
        if points[i].Y < minY then
            minY = points[i].Y
        end
        if points[i].Y > maxY then
            maxY = points[i].Y
        end
    end
    return Rectangle(minX, minY, maxX - minX, maxY - minY)
end
PathDistance = function(pts1, pts2)
    local d = 0.0
    for i = 1, #pts1, 1 do -- assumes pts1.length == pts2.length
        d = d + Distance(pts1[i], pts2[i])
    end
    return d / #pts1
end
PathLength = function(points)
    local d = 0.0
    for i = 2, #points, 1 do
        d = d + Distance(points[i - 1], points[i])
    end
    return d
end
Distance = function(p1, p2)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    return sqrt(dx * dx + dy * dy)
end
return {DollarRecognizer=DollarRecognizer}
