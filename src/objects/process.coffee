child = require 'child_process'

RemoteObject = require('../remoteobject').RemoteObject
LocalObject = require('../localobject').LocalObject

class RemoteProcess extends RemoteObject
	fork: ->
		@call 'fork', arguments...
	
	kill: ->
		@call 'kill', arguments...
	
	send: ->
		@call 'send', arguments...
	
	isConnected: (callback) ->
		@call 'isConnected', callback

class LocalProcess extends LocalObject
	process: null
	running: false
	
	_timeout: null
	
	fork: (modulePath, args, options) ->
		if @process then @kill()
		
		unless modulePath
			@emit 'error', new Error "Module to run in process must be specified!"
			
		@process = child.fork modulePath, args, options

		@process.on 'error', =>
			@emit 'error', arguments...

		@process.on 'disconnect', =>
			unless @running then return

			@emit 'disconnect', arguments...
		
		@process.on 'exit', =>
			unless @running then return
			
			@emit 'exit', arguments...
		
		@process.on 'close', =>
			unless @running then return

			@running = false
			@emit 'close', arguments...
			@process.removeAllListeners()
			@process = null
		
		@process.on 'message', (message) =>
			if message?.__process_online__ is true
				clearTimeout @_timeout
				@running = true
				@emit 'online'
			else
				@emit 'message', arguments...
		
		@_timeout = setTimeout =>
			if @running then return
			
			@emit 'error', new Error "Process fork timeouted!"
			@kill()
			
		, 30000
	
	kill: (signal) ->
		if @process
			@process.kill signal
	
	send: (message) ->
		if @process
			@process.send message
		else
			@emit 'error', new Error "Process is not running!"
	
	isConnected: (callback) ->
		callback null, @process.connected
	
	destroy: ->
		@kill()
		super()

exports.RemoteProcess = RemoteProcess
exports.LocalProcess = LocalProcess