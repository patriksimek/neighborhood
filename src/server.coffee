net = require 'net'

EventEmitter = require('events').EventEmitter
Neighbor = require('./neighbor').Neighbor

class Server extends EventEmitter
	net: null
	listening: false
	clients: null		# Array.<Neighbor>
	
	constructor: (neighborhood, config, callback) ->
		@net = net.createServer()
		@net.listen config.port
		@clients = []
		
		if callback then @on 'listen', callback

		@net.on 'connection', (socket) =>
			neighbor = new Neighbor neighborhood, socket

			@emit 'info', "neighbor connected from #{neighbor.socket.remoteAddress}".grey
			@clients.push neighbor
			@emit 'connect', neighbor

			neighbor.on 'close', =>
				neighbor.removeAllListeners()
				
				@emit 'info', 'neighbor disconnected'.grey
				@clients.splice @clients.indexOf(neighbor), 1
				@emit 'disconnect', neighbor
		
		@net.on 'listening', =>
			@listening = true
			
			@emit 'info', "listening on #{@net.address().address}:#{config.port}".grey
			@emit 'listen'
		
		@net.on 'error', (err) =>
			@emit 'error', err
		
		@net.on 'close', =>
			@net = null
			
			unless @listening
				@emit 'listen', new Error "Failed to start server."
				
			else
				@listening = false
				@emit 'close'
	
	destroy: ->
		@removeAllListeners()

exports.Server = Server