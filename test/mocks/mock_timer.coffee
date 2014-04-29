exports.MockTimer = class MockTimer
  constructor: (@func) ->
    MockTimer.timers.push this
    @time = null

  start: (timeout) ->
    @time = MockTimer.now + timeout

  stop: ->
    @time = null

  fire: ->
    @time = null
    @func()

MockTimer.reset = ->
  MockTimer.timers = []
  MockTimer.now = 0
MockTimer.advance = (period) ->
  MockTimer.now += period
  for timer in MockTimer.timers
    timer.fire() if timer.time? and timer.time <= MockTimer.now
MockTimer.reset()
