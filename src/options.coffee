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

Options.defaults =
  host: 'localhost'
  port: 35729
  mindelay: 1000
  maxdelay: 60000
  handshake_timeout: 5000
  snipver: null
  ext: null
  extver: null
  debug: true

  uri: ->
    if document.location.protocol == 'https:'
      proto = 'wss:'
    else
      proto = 'ws:'

    "#{proto}//#{@host}:#{@port}/livereload"


Options.extract = ->
  env = window.LiveReloadENV || {}
  options = extend Options.defaults, env
  for own key, value of options
    options[key] = value.apply(options) if typeof value == 'function'
  options

exports.Options = Options
