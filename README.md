# lua-gestures

![demo](./love-demo/demo.gif)

This library implements single-stroke gesture recognition in pure Lua code. The trained letters, numbers, symbols and drawings can be reliably recognized, based on just a single training sample for each gesture. It can be used for text entry method, as a way to trigger actions in design tools, or for casting spells in magic games.

The drawn gesture is captured as a list of coordinates. From this list the library can determine which of the previously-trained gesture is the closest match. New gestures can be added on the fly, and the trained gestures can be exported into string representation for later use.

The original algorithm is [$1 Unistroke Recognizer](http://depts.washington.edu/acelab/proj/dollar/index.html). The Lua port was written by [Lance Ulmer](https://github.com/lanceulmer/dollar.lua/). Building on top of it, the *lua-gestures* project fixes some found bugs, provides few more useful options, simplifies the API, and provides demo applications for testing and managing custom gestures.

Gestures are limited to single-stroke patterns, so the recognizer cannot be used for conventional alphabet with letters such as "X" (two strokes). It is still possible to adapt letters to single-stroke variations and type with good accuracy. The huge benefit of single-stroke gesture is ease of detection of intended start and end of gesture. For example, as soon as mouse is released the gesture is considered done and it can be processed without waiting for confirmation.

The algorithm is sensitive to gesture drawing direction. If both drawing directions need to be supported, the same gesture can be reversed and added to recognizer second time under the same name.

## Basic usage

```lua
gestures = require('gestures').new()

-- populate the recognizer with different gesture templates
gestures:add('gesture 1', list_of_points1)
gestures:add('gesture 2', list_of_points2)

-- app collects mouse coordinates per-frame or on mouse-move event
gestures:capture(x, y)

-- after gesture is completed (on mouse released) perform the recognition
name = gestures:recognize()
-- returned name is now either 'gesture 1' or 'gesture 2'
```

## Recognizer configuration

Just like $1 original, this library includes 2 algorithms to match gesture against trained gestures. The original $1 unistroke algorithm used "Golden Section Search" to iteratively arrive at best angle between gesture and template. The "Protractor" algorithm is later improvement which uses closed form expression to arrive at angle that fits best. Because protractor variant is faster, it is used as default.

With a configuration option the recognizer can be rotationally sensitive. This means that '+' won't be recognized as 'x', which is often needed as it allows for more gestures to be distinguished with same accuracy. If user needs to be able to draw gesture in any orientation, either disable this option or register multiple identical gestures in different directions (depending on the use case). Gestures are oriented (rotationally sensitive) by default.

Another added configuration option is uniform scaling. The original algorithm uses non-uniform scaling to better match complex gestures against templates. When all strokes are uniformly scaled, some thin gestures like '-' and '|' can be recognized more reliably. The possible issue here is that one dimension is much larger than other, so the non-uniform scaling would amplify the noise along smaller of two dimensions. Uniform scaling generally performs better and is therefore a default setting.

Take care when experimenting with options that the trained templates might have to be re-created. For example, templates that were extracted from non-oriented non-uniform recognizer will not give good results when used with oriented uniform recognizer.

```lua
gestures = require('gestures')
-- the function takes three parameters: oriented, uniform, protractor
default_recognizer = gestures.new() -- same as gestures.new(true, true, true)
unoriented_recognizer = gestures.new(false, true, true)
nonuniform_recognizer = gestures.new(true, false, true)
```

## API


### constructor

Requiring the lib returns the Lua class with `.new()` method that creates the recognizer object.

```lua
oriented, uniform, protractor = true, true, true
gestures = require('gestures')
recognizer = gestures.new(oriented, uniform, protractor)
```

The `oriented`, `uniform` and `protractor` arguments are booleans that configure the recognizer (as explained above). If not supplied they all default to `true`.

If needed, several different recognizer objects can be constructed, each with its own set of gestures to compare against. This is useful to separate the gestures into smaller sets (letters, numbers). In runtime the UI context can decide which recognizer is most suitable.

### add

`count = recognizer:add(name, points)`

The recognizer starts with empty set of trained gestures. Method `:add` trains the recognizer with a new gesture.

`name` is (usually) a string.
`points` is either a flat list of coordinates `{x1, y1, x2, y2 ...}` or nested list of coordinates `{{x1, y1}, {x2, y2} ...}`.

Multiple different gestures can be added under the same name as part of training. `:add` function returns the number of gestures currently registered under the same name.
The `name` can be anything (a function!), but strings are preferred for `:toString()` method compatibility.

### capture

`recognizer:capture(x, y)`

The `:capture()` is a convenience method that will record individual coordinates of the gesture stroke as they arrive, and collect them to be recognized when finished.

```Lua
recognizer = require('gestures').new()
recognizer:capture(x1, y1)
recognizer:capture(x2, y2)
result = recognizer:recognize()
-- with gesture recognized the collected points are purged to prepare for next capture
recognizer:capture(x1, y1)
```

Note that the `:capture()` method has limitation of only single gesture being recorded simultaneously. For ability to record two or more gestures in parallel, don't use this method but collect the points separately and pass them in with `:recognize(points)` variant.

### recognize

`name, score, index = recognizer:recognize(points)`

To recognize user gesture, collect the points forming the gesture and pass them into the `recognize` function. 

`points` is either a flat list of coordinates `{x1, y1, x2, y2 ...}` or nested list of coordinates `{{x1, y1}, {x2, y2} ...}`.

Function returns `name` (string, or whatever was supplied when adding the gesture) of closest match, `score` as numerical measure on how good the match is (0 is worst, more is better), and its `index` within list of trained gestures.
If no gesture was added to the recognizer this function would return `nil`. In case where only one gesture was added that gesture will always be returned as recognition result, with the varying score metric.

`name, score, index = recognizer:recognize()`

When called without arguments, the function will use the internal list of points that were collected with the `:capture()` method; those points will be discarded to prepare for capturing of the next gesture.

### remove

`recognizer:remove(name)`

This function removes all gestures registered with same `name` and returns the number of gestures removed. The defined gestures can be removed at any time.

### clear

`recognizer:clear()`

Removes all the gestures from the recognizer.

### toString

The list of trained gestures can be extracted from the recognizer.

`gesture_definitions = recognizer:toString()`

Function returns `serialized` string. It is formatted as a multiline Lua nested table.

Example output:
```Lua
{
{ name = 'gesture-1', points = {{-0.34, 0.32}, {-0.30, 0.34}, {-0.26, 0.36}, {-0.22, 0.38}}},
{ name = 'gesture-2', points = {{0.03, -0.02}, {0.06, 0.01}, {0.09, 0.03}, {0.12, 0.06}}},
}
```

### fromString

The trained gestures that were extracted from runtime with `toString` can be added back to the recognizer.

`recognizer:fromString(gesture_definitions)`

All previous gestures are also kept; use `:clear()` when it is necessary to purge them before loading in the new ones.

## Demo app

The included demo app uses the [LÖVE](https://love2d.org/) framework for graphics and IO. It can be used to evaluate the algorithm, learn its strengths and weaknesses, and as reference on how to incorporate it into UI framework.

The app is also useful for quickly defining custom gestures and extracting them for use in other projects. Just note that in LÖVE the +y is downward and so the captured gestures might need a vertical flip to work in other environments.

To run the app, download LÖVE interpreter and execute it with `love-demo` directory as parameter.

## License

The library is licensed under "New BSD License". Original license and Lua port license are included in source files.
