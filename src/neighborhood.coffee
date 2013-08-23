net = require 'net'
colors = require 'colors'

EventEmitter = require('events').EventEmitter
Lighthouse = require('./lighthouse').Lighthouse
Server = require('./server').Server
Neighbor = require('./neighbor').Neighbor
RemoteObjects = require('./neighbor').RemoteObjects

class Neighborhood extends EventEmitter
	lighthouse: null
	server: null
	client: null
	
	constructor: (config) ->
		@name = config.name
		@district = config.district
		
		@lighthouse = new Lighthouse
			port: config.port
			district: config.district
			name: config.name
			controller: config.controller

		@lighthouse.on 'info', (msg) =>
			@log msg, 'lhs'
		
		if config.controller
			@server = new Server @,
				port: config.port
			
			@server.on 'connect', (neighbor) =>
				# new neighbor connected
				
				neighbor.on 'error', (err) =>
					@emit 'error', err
				
				neighbor.on 'info', (msg) =>
					@log msg
				
				neighbor.on 'authorize', =>
					@emit 'connect', neighbor
			
			@server.on 'disconnect', (neighbor) =>
				# neighbor disconnected
				
				@emit 'disconnect'
			
			@server.on 'close', =>
				# server closed
				
				@emit 'offline', neighbor
			
			@server.on 'error', (err) =>
				@emit 'error', err
			
			@server.on 'info', (msg) =>
				@log msg, 'srv'
			
			@server.on 'listen', =>
				# server is listening
				
				@emit 'online'
		
		else
			@lighthouse.on 'light', (server) =>
				@lighthouse.stop()
				
				@client = new Neighbor @
				@client.connect server.host, server.port
	
				@client.on 'authorize', =>
					# connected to controller

					@emit 'online'
					
				@client.on 'close', (wasConnected) =>
					# disconnected from controller
					
					if wasConnected
						@emit 'offline'
					
					@lighthouse.start()
				
				@client.on 'error', (err) =>
					@emit 'error', err
				
				@client.on 'info', (msg) =>
					@log msg, 'cli'
				
	log: (msg, category) ->
		#console.log "[#{@name}#{if category then ":#{category}" else ":   "}] #{msg}"
		@emit 'info', msg
	
Object.defineProperty Neighborhood::, 'neighbors',
	get: ->
		if @server then return @server.clients
		if @client then return [@client]
		[]
		
exports.Neighborhood = Neighborhood
exports.RemoteObjects = RemoteObjects