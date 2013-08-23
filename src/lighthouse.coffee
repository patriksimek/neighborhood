dgram = require 'dgram'
utils = require './utils'

EventEmitter = require('events').EventEmitter

BROADCAST_INTERVAL = 500

class Lighthouse extends EventEmitter
	server: null
	client: null
	config: null
	running: false
	
	_timer: null
	
	constructor: (@config) ->
		@id = utils.guid()
		@start()
	
	start: ->
		if @running then return
		@running = true

		if @config.controller
			# --- Server ---
			
			@server = dgram.createSocket 'udp4'
			@server.bind =>
				@server.setBroadcast true
				@_timer = setInterval =>
					unless @running then return
					
					packet = 
						id: @id
						port: @config.port
						district: @config.district
						name: @config.name
						controller: @config.controller
	
					packet = new Buffer JSON.stringify packet
					@server.send packet, 0, packet.length, 22333, '255.255.255.255', (err, bytes) =>
				
				, @config.interval ? BROADCAST_INTERVAL
				
				@emit 'info', "lighthouse lights out on 255.255.255.255:22333".grey

		else
			# --- Client ---
			
			@client = dgram.createSocket 'udp4'
			@client.on "message", (msg, rinfo) =>
				unless @running then return
				
				try
					msg = JSON.parse msg
				catch ex
					msg = null
				
				if msg and msg.district is @config.district and msg.id isnt @id
					found = 
						name: msg.name
						port: msg.port
						host: rinfo.address

					@emit 'info', "controller found: #{found.name} (#{found.host}:#{found.port})".grey
					@emit 'light', found
	
			@client.bind 22333, =>
				@emit 'info', "lighthouse listen on #{@client.address().address}:#{@client.address().port}".grey

	stop: ->
		unless @running then return
		@running = false
		
		if @_timer
			clearInterval @_timer
			@_timer = null
		
		if @config.controller
			@server.close()
			@server = null
			
		else
			@client.close()
			@client = null

exports.Lighthouse = Lighthouse