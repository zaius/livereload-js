assert = require 'assert'

{ Options }    = require '../src/options'
{ Connector }  = require '../src/connector'
{ PROTOCOL_7 } = require '../src/protocol'

HELLO = { command: 'hello', protocols: [PROTOCOL_7], ver: '2.0.8' }

class MockHandlers
  constructor: ->
    @_log = []

  obtainLog: ->
    result = @_log.join("\n")
    @_log = []
    result

  log: (message) ->
    @_log.push message

  connecting: ->
    @log "connecting"
  socketConnected: -> {}
  connected: (protocol) ->
    @log "connected(#{protocol})"
  disconnected: (reason) ->
    @log "disconnected(#{reason})"
  message: (message) ->
    @log "message(#{message.command})"

class MockTimer
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


class MockWebSocket
  sent: []
  _log: []
  readyState: null

  constructor: ->
    @sent = []
    @_log = []
    @readyState = MockWebSocket.CONNECTING

  obtainSent: ->
    result = @sent
    @sent = []
    result

  log: (message) ->
    @_log.push message

  send: (message) ->
    @sent.push message

  close: ->
    @readyState = MockWebSocket.CLOSED
    @onclose()

  connected: ->
    @readyState = MockWebSocket.OPEN
    @onopen()

  disconnected: ->
    @readyState = MockWebSocket.CLOSED
    @onclose()

  receive: (message) ->
    @onmessage data: message

  assertMessages: (messages) ->
    # sent is always an array. cast messages to be the same.
    expected = [].concat messages
    actual = (JSON.parse msg for msg in @obtainSent())
    assert.deepEqual actual, expected

MockWebSocket.CONNECTING = 0
MockWebSocket.OPEN = 1
MockWebSocket.CLOSED = 2


shouldBeConnecting = (handlers) ->
  assert.equal handlers.obtainLog(), 'connecting'

shouldReconnect = (handlers, timer, failed, callback) ->
  if failed
    delays = [1000, 2000, 4000, 8000, 16000, 32000, 60000, 60000, 60000]
  else
    delays = [1000, 1000, 1000]

  for delay in delays
    timer.advance delay-100
    assert.equal handlers.obtainLog(), ''

    timer.advance 100
    shouldBeConnecting handlers

    callback()


connectAndPerformHandshake = (handlers, webSocket, callback) ->
  assert.notEqual webSocket, null

  webSocket.connected()
  webSocket.assertMessages HELLO
  assert.equal handlers.obtainLog(), ''

  webSocket.receive JSON.stringify(HELLO)
  assert.equal handlers.obtainLog(), 'connected(7)'

  callback()



describe 'Connector', ->

  it 'should connect and perform handshake', ->
    MockTimer.reset()
    handlers  = new MockHandlers()
    options   = Options.extract()
    timer     = MockTimer
    connector = new Connector(options, MockWebSocket, timer, handlers)
    webSocket = connector.socket

    sendReload = ->
      json = JSON.stringify command: 'reload', path: 'foo.css'
      webSocket.receive json
      assert.equal handlers.obtainLog(), 'message(reload)'

    shouldBeConnecting handlers
    connectAndPerformHandshake handlers, webSocket, ->
      sendReload()


  it 'should repeat connection attempts', ->
    MockTimer.reset()
    handlers  = new MockHandlers()
    options   = Options.extract()
    timer     = MockTimer
    connector = new Connector(options, MockWebSocket, timer, handlers)
    webSocket = connector.socket

    shouldBeConnecting handlers

    cannotConnect = ->
      assert.notEqual webSocket, null
      webSocket.disconnected()
      log = handlers.obtainLog()
      assert.equal log, 'disconnected(cannot-connect)'

    cannotConnect()

    retries = 0
    shouldReconnect handlers, timer, yes, ->
      cannotConnect()
      ++retries
    assert.equal retries, 9


  it 'should reconnect after disconnection', ->
    MockTimer.reset()
    handlers  = new MockHandlers()
    options   = Options.extract()
    timer     = MockTimer
    connector = new Connector(options, MockWebSocket, timer, handlers)
    webSocket = connector.socket

    connectionBroken = ->
      webSocket.disconnected()
      assert.equal handlers.obtainLog(), 'disconnected(broken)'

    shouldBeConnecting handlers
    connectAndPerformHandshake handlers, webSocket, ->
      connectionBroken()

    shouldReconnect handlers, timer, no, ->
      connectAndPerformHandshake handlers, webSocket, ->
        connectionBroken()


  it 'should timeout handshake after 5 sec', ->
    MockTimer.reset()
    handlers  = new MockHandlers()
    options   = Options.extract()
    timer     = MockTimer
    connector = new Connector(options, MockWebSocket, timer, handlers)
    webSocket = connector.socket

    shouldBeConnecting handlers
    assert.notEqual webSocket, null

    webSocket.connected()
    webSocket.assertMessages HELLO
    assert.equal handlers.obtainLog(), ''

    timer.advance 5001
    assert.equal handlers.obtainLog(), "disconnected(handshake-timeout)"
