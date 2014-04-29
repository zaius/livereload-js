LiveReload.js
=============

## What is LiveReload?

LiveReload is a tool for web developers and designers. See
[livereload.com](http://livereload.com/) for more info.

LiveReload.js connects to a LiveReload server via web sockets and listens for
incoming change notifications. When CSS or image file is modified, it is
live-refreshed without reloading the page. When any other file is modified, the
page is reloaded.


## Using livereload.js

On your build script / development environment, you need to have a livereload
server that notifies the client whenever a change is made.
 * [LiveReload 2.x GUI for Mac](http://livereload.com/)
 * [rack-livereload](https://github.com/johnbintz/rack-livereload)
 * [guard-livereload](https://github.com/guard/guard-livereload)
 * Your own server - refer to the
   [livereload prorocol](http://help.livereload.com/kb/ecosystem/livereload-protocol)


Once you have the server running, include the livereload.js file in any HTML
file that you want to be live-updated.

    <script src="http://localhost/livereload.js"></script>

You can download the file from
[dist/livereload.js in this repository](https://github.com/zaius/livereload-js/raw/master/dist/livereload.js).
Or you can install via bower.

    bower install --save-dev "git://github.com/zaius/livereload-js#master"

Most live-reload servers will also serve up their own copy of livereload.js.
Be careful that you are requesting the right version.


### Settings

You can set options in a global variable `LiveReloadENV` before including the
script. E.g.

    <script>
      window.LiveReloadENV = {
        host: '192.168.0.123',
        port: 31337
      };
    </script>
    <script src="http://localhost/livereload.js"></script>

This allows you to directly include the latest javascript from github.

    <script src="https://github.com/zaius/livereload-js/raw/master/dist/livereload.js"></script>

### Available settings

 * mindelay - minimum delay before the websocket attempts a reconnect (default 1000)
 * maxdelay - maximum delay before giving up on reconnecting (default 60000)
 * host - hostname of the server hosting the livereload server. (default window.location.hostname)
 * defer - whether to wait until the user switches back to the page before doing a full page reload. (default true)
 * debug - whether to output status / debugging to console.log (default true)


### Secure sockets

Most browsers frown upon connecting to a non-secure websocket when serving the
page over a secure connection. This version of livereload.js attempts to
connect via a secure websocket (wss) if the page is loaded over https.
Unfortunately many livereload servers don't support this. If you're running
into this problem, you will need to use a proxy in front of your livereload
server. An example [nginx](http://nginx.org) config that forwards to a dev
server on port 8000 and a livereload server on port 35729:

    server {
      listen 443 ssl;
      server_name example.dev;

      ssl_certificate  /keys/example.crt;
      ssl_certificate_key /keys/example.key;

      root /var/www/example.dev/public;

      location /livereload {
        proxy_pass http://localhost:35729;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
      }

      location @app {
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://localhost:8000;
      }

      location / {
        try_files $uri $uri/index.html $uri.html @app;
      }
    }


Then you need to make sure that https livereloads connections will be
sent via the existing https proxy. You can override the port using the settings
object.

      <script type="text/javascript">
        window.LiveReloadENV = {
          port: window.location.port ? 35729 : 443
        };
      </script>



## Communicating with livereload.js

It is possible to communicate with a running LiveReload script using DOM events:

 * fire LiveReloadShutDown event on `document` to make LiveReload disconnect
   and go away
 * listen for LiveReloadConnect event on `document` to learn when the
   connection is established
 * listen for LiveReloadDisconnect event on `document` to learn when the
   connection is interrupted (or fails to be established)

LiveReload object is also exposed as `window.LiveReload`, with
`LiveReload.disconnect()`, `LiveReload.connect()` and `LiveReload.shutDown()`
being available. However I'm not yet sure if I want to keep this API, so
consider it non-contractual (and email me if you have a use for it).


## Features

 * live CSS reloading
 * full page reloading
 * protocol, WebSocket communication
 * CSS @import support
 * live image reloading (IMG src, background-image and border-image properties,
   both inline and in stylesheets)
 * live in-browser LESS.js reloading


## Issues & Limitations

**Live reloading of imported stylesheets has a 200ms lag.** Modifying a CSS
`@import` rule to reference a not-yet-cached file causes WebKit to lose all
document styles, so we have to apply a workaround that causes a lag.

Our workaround is to add a temporary LINK element for the imported stylesheet
we're trying to reload, wait 200ms to make sure WebKit loads the new file, then
remove the LINK tag and recreate the @import rule. This prevents a flash of
unstyled content. (We also wait 200 more milliseconds and recreate the @import
rule again, in case those initial 200ms were not enough.)

**Live image reloading is limited to IMG src, background-image and border-image
styles.** Any other places where images can be mentioned?

**Live image reloading is limited to jpg, jpeg, gif and png extensions.** Maybe
need to add SVG there? Anything else?


## Development

Requirements
  * nodejs
  * coffee-script
  * ruby
  * rake
  * mocha

### Building

    rake build

output is in the `dist` folder.


### Running tests

    npm install
    rake


## License

livereload-js is available under the MIT license, see LICENSE file for details.
