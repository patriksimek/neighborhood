#neighborhood [Project abandoned]

Sharing objects between multiple NodeJS instances over TCP.

Work in progress, detailed documentation comming soon.

##Installation

    npm install neighborhood

##Getting started

Neighborhood is collection of servers with one master server (controller) and many clients (worker). Server is sending UDP broadcasts to network so clients can easily find it and expand neighborhood. District name must match on both client and server. When connected, you can easily create remote objects on clients. Currently, only RemoteProcess is available.

###Server

```javascript
var Neighborhood = require('neighborhood').Neighborhood;
var RemoteProcess = require('neighborhood').RemoteObjects.RemoteProcess

new nbh = new Neighborhood({
	name: 'master',
	port: 7777,
	district: 'github.com',
	controller: true
});

nbh.on('online', function() {
	// neighborhood is online (server is listening for connections)
});

nbh.on('connect', function(neighbor) {
	// new neighbor is connected
	
	var process = new RemoteProcess(neighbor)
	process.on('create', function() {
		process.fork('remotescript.js')
		process.on('online', function() {
			// remote process is online
			
			process.send('message to process');
		});
		process.on('close', function(code, signal) {
			// remote process was closed
		});
		process.on('message', function(message) {
			// message from process
		});
	});
	process.on('error', function(err) {
		// error handler
	});
});

nbh.on('disconnect', function() {
	// neighbor was disconnected
});

nbh.on('error', function(err) {
	// error handler
});
```

###Worker

```javascript
var Neighborhood = require('neighborhood').Neighborhood;

new nbh = new Neighborhood({
	name: 'slave',
	district: 'github.com'
});

nbh.on('online', function() {
	// neighborhood is online (worker is connected to server)
});

nbh.on('offline', function() {
	// neighborhood is offline (worker was disconnected from server)
});

nbh.on('error', function(err) {
	// error handler
});
```

##License

Copyright (c) 2013 Patrik Simek

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
