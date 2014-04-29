# Approximate equivalent of jQuery.extend. Returns an object with all
# properties merged. When there are duplicate keys, the latest object take
# precendence.
extend = ->
  target = {}
  sources = [].slice.call arguments, 0
  for source in sources
    for own key, value of source
      target[key] = value
  target


Options = {}

fakeWindow =
  location:
    protocol: 'http:'
    hostname: 'localhost'

Options.defaults = (scope) ->
  {
    host: scope.location.hostname
    port: 35729
    mindelay: 1000
    maxdelay: 60000
    handshake_timeout: 5000
    snipver: null
    ext: null
    extver: null

    debug: true
    eager: false

    uri: (
      if scope.location.protocol == 'https:'
        proto = 'wss:'
      else
        proto = 'ws:'

      "#{proto}//#{@host}:#{@port}/livereload"
    )
  }


Options.extract = (scope) ->
  if typeof scope == 'undefined'
    if typeof window == 'undefined'
      scope = fakeWindow
    else
      scope = window

  env = scope.LiveReloadENV || {}
  extend Options.defaults(scope), env

exports.Options = Options
