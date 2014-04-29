class Timer
  id: null
  running: ->
    @id != null

  handler: ->
    @id = null
    @_callback() if typeof @_callback == 'function'

  constructor: (@_callback) ->
    this

  start: (timeout) ->
    clearTimeout @id if @id
    @id = setTimeout =>
      @handler()
    , timeout

  stop: ->
    clearTimeout @id if @id
    @id = null

exports.Timer = Timer
