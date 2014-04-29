assert = require 'assert'
{ Timer } = require '../src/timer'

describe 'Timer', ->

  it 'should fire an event once in due time', (done) ->
    @timeout 50

    timer = new Timer(->
      done()
    )

    assert.equal no, timer.running()
    timer.start 5
    assert.equal yes, timer.running()


  it 'timer should not fire after it is stopped', (done) ->
    @timeout 50

    timer = new Timer ->
      throw 'Timer fired'

    timer.start 20
    setTimeout((-> timer.stop()), 10)

    setTimeout done, 30


  # I absolutely cannot get this async callback working properly on expresso.
  # Hence the switch to mocha.
  it 'should restart interval on each start() call', (done) ->
    @timeout 50

    okToFire = no
    fired = no
    timer = new Timer ->
      assert.equal yes, okToFire
      done()
      fired = yes

    timer.start 10
    setTimeout((-> okToFire = yes), 15)
    setTimeout((-> timer.start 20 ), 5)
