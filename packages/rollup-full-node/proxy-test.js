/**
 * Module dependencies.
 */
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const {w3cwebsocket} = require('websocket')
const WebSocket = w3cwebsocket

/**
 * Configure proxy middleware
 */
const wsProxy = createProxyMiddleware('http://echo.websocket.org',
  {
  changeOrigin: true
});

const app = express();
app.use('/', express.static(__dirname)); // demo page
app.use(wsProxy); // add the proxy to express

const server = app.listen(3000);
server.on('upgrade', wsProxy.upgrade); // optional: upgrade externally

console.log('[DEMO] Server: listening on port 3000');
console.log('[DEMO] Opening: http://localhost:3000');

const socket = new WebSocket('ws://localhost:3000');
socket.onmessage = function (msg) {console.log(msg.data)};
setTimeout(() => {
try {
  console.log("sending")
socket.send('hello world');
} catch (e) {
  console.log(e.message)
}
}, 1000);

// require('open')('http://localhost:3000');

/**
 * Example:
 * Open http://localhost:3000 in WebSocket compatible browser.
 * In browser console:
 * 1. `const socket = new WebSocket('ws://localhost:3000');`          // create new WebSocket
 * 2. `socket.onmessage = function (msg) {console.log(msg)};`       // listen to socket messages
 * 3. `socket.send('hello world');`                                 // send message
 * >  {data: "hello world"}                                         // server should echo back your message.
 **/
