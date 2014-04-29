assert = require 'assert'

{ Options }    = require '../src/options'
{ Connector }  = require '../src/connector'
{ PROTOCOL_7 } = require '../src/protocol'
{ MockTimer }    = require './mocks/mock_timer'
{ MockHandlers }    = require './mocks/mock_handlers'
{ MockWebSocket }    = require './mocks/mock_web_socket'

HELLO = { command: 'hello', protocols: [PROTOCOL_7], ver: '2.0.8' }


shouldBeConnecting = (handlers) ->
  assert.equal handlers.obtainLog(), 'connecting'


assertMessages = (sent, messages) ->
  # sent is always an array. cast messages to be the same.
  expected = [].concat messages
  actual = (JSON.parse msg for msg in sent)
  assert.deepEqual actual, expected

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
  assertMessages webSocket.obtainSent(), HELLO
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
    assertMessages webSocket.obtainSent(), HELLO
    assert.equal handlers.obtainLog(), ''

    timer.advance 5001
    assert.equal handlers.obtainLog(), "disconnected(handshake-timeout)"
