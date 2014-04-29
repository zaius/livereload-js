assert = require 'assert'
jsdom = require 'jsdom'

{ Options } = require '../src/options'

describe 'Options', ->

  it 'should extract host and port from environment', ->
    html = "<script>window.LiveReloadENV = { host: 'somewhere.com', port: 9876 };</script>"
    window = jsdom.jsdom(html).createWindow()

    options = Options.extract window
    assert.notEqual options, null
    assert.equal 'somewhere.com', options.host
    assert.equal 9876, options.port


  it 'should extract additional options', ->
    html = "<script> window.LiveReloadENV = { snipver: 1, ext: 'Safari', extver: '2.0' }; </script>"
    window = jsdom.jsdom(html).createWindow()

    options = Options.extract window
    assert.equal '1', options.snipver
    assert.equal 'Safari', options.ext
    assert.equal '2.0', options.extver
