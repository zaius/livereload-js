exports.MockHandlers = class MockHandlers
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
