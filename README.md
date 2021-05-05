# lua-gestures

This pure-Lua library impements gesture recognition by matching them against pre-trained gestures. It supports only single-stroke gestures.

The algorithm is not sensitive to rotation and scaling of drawn gesture, but it is sensitive to gesture drawing direction. For example, same gesture will be recognized as either '[' or ']' depending on starting point. If both drawing directions need to be supported, the library can simply be trained two gestures with same name. This will work well unless there is a clash with another symmetrical gesture (like in the [] example).

The original algorithm is [$1 Unistroke Recognizer](http://depts.washington.edu/acelab/proj/dollar/index.html). The Lua port was written by [Lance Ulmer](https://github.com/lanceulmer/dollar.lua/). The lua-gestures project fixes found bugs and changes the API significantly.

# Usage

Requiring the lib returns the constructor function which has to be called to get the recognizer object.

`local gestures = require('gestures')()`

If needed, several different recognizer objects can be constructed, each with its own set of gestures to compare against. This is useful to separate gestures into smaller sets and call each recognizer depending on UI context.

The library starts out with empty set of gestures. The recognizer can be populated with some built-in presets (check the [original page](http://depts.washington.edu/acelab/proj/dollar/index.html) for reference):

`gestures.presets()`

To add new custom gesture to recognizer, first record its points and assign name to the gesture.

`gestures.add(name, points)`

`name` is a string, `points` is either a flat list of coordinates `{x1, y1, x2, y2 ...}` or nested list of coordinates `{{x1, y1}, {x2, y2} ...}`. The function returns number of gestures currently registered under the name. It is normal to add multiple gestures under same name as part of training.

To recognize user gesture, collect the points forming the gesture and pass them into the function:

`gesture.recognize(points, useProtractor)`

The `useProtractor` bool value specifies if the gesture recognition uses the faster Protractor search algorithm, or the original Golden Section Search (default is `false`). The function will return name (string) of closest match, as well as numerical score on how good the match is. Score 0 is worst, more is better. Beware, protractor and golden section search use different scoring scale.

The defined gestures can be removed at any time:

`gesture.remove(name)`

This will remove all gestures registered under the supplied name and return the number of gestures removed.

See included [LÖVE](https://love2d.org/) project for a working demo.

# License

The library is licensed under "New BSD License". Original license and Lua port license are included in source files.