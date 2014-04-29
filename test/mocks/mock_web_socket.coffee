exports.MockWebSocket = class MockWebSocket
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

MockWebSocket.CONNECTING = 0
MockWebSocket.OPEN = 1
MockWebSocket.CLOSED = 2
