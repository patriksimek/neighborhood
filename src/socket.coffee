utils = require './utils'
net = require 'net'

EventEmitter = require('events').EventEmitter

HEADER_LENTGH = 8

serialize = (data) ->
	header = new Buffer(HEADER_LENTGH)
	header.write 'nbrh'
	header.writeUInt32LE 0, 4

	data = new Buffer(JSON.stringify(data))
	packet = Buffer.concat [header, data]
	packet.writeUInt32LE packet.length, 4

	packet

deserialize = (data) ->
	try
		packet = data.toString 'utf8', HEADER_LENTGH
		return JSON.parse(packet)
	catch ex
		return null

capitalize = (str) ->
	str.charAt(0).toUpperCase() + str.slice(1)

serializeArguments = (args) ->
	for arg, i in args
		if arg instanceof Error
			args[i] = {__error__: {message: arg.message, type: arg.name}}

deserializeArguments = (args) ->
	for arg, i in args
		if arg?.__error__
			if arg.__error__.type is 'SocketError'
				klass = SocketError
			else
				klass = global[arg.__error__.type] ? Error
				
			args[i] = new klass arg.__error__.message
		
# --- Neighbor ---

class Socket extends EventEmitter
	_callbacks: null
	
	name: 'socket'
	connected: false
	
	constructor: (@socket) ->
		if @socket
			@connected = true
		else
			@socket = socket = new net.Socket
		
		buffer = new Buffer(0)
		currentPacketLength = 0

		@_callbacks = {}
		
		socket.on 'connect', =>
			@connected = true
			@emit 'connect'
		
		socket.on 'close', =>
			wasConnected = @connected
			
			@connected = false
			buffer = null
			currentPacketLength = 0
			@emit 'close', wasConnected
			
			for guid, cb of @_callbacks
				cb new SocketError "Connection was lost!"

			@_callbacks = {}
		
		socket.on 'error', (err) =>
			@emit 'error', err

		socket.on 'data', (data) =>
			buffer = Buffer.concat [buffer, data]

			while true
				if currentPacketLength is 0
					# waiting for new packet
					if buffer.length > HEADER_LENTGH
						if buffer.toString('utf8', 0, 4) isnt 'nbrh'
							@emit 'error', new SocketError 'Received data with invalid header! Clearing buffer.'
							buffer = new Buffer(0)
							break
						
						currentPacketLength = buffer.readInt32LE 4
					
					else
						break
				
				if currentPacketLength > 0
					# getting more data
					
					if buffer.length >= currentPacketLength
						# got full packet data
						parsed = deserialize buffer.slice 0, currentPacketLength
						
						if parsed then do (parsed) =>
							deserializeArguments parsed.args
							
							if parsed.cmd is '__callback__'
								# got callback
								cbid = parsed.args.shift()
								args = parsed.args

								@emit 'info', "[sck:cb] <- (#{cbid}, #{args.join(', ')})".cyan
								
								if @_callbacks[cbid]
									@_callbacks[cbid].apply @, args
									delete @_callbacks[cbid]
								
								else
									@emit 'error', new SocketError 'Received callback with unknown cbID.'

							else
								# replace ref with callback
								last = parsed.args?[parsed.args.length - 1]
								cb = last?.__callback__
								if cb
									last = parsed.args[parsed.args.length - 1] = =>
										@call '__callback__', cb, arguments...
									
									last.toString = -> "[callback]"
								
								# propagate event
								@emit 'info', "[sck:call] <- #{parsed.cmd} (#{parsed.args.join(', ')})".cyan
								
								cmd = "on#{capitalize(parsed.cmd)}"
								if @[cmd]
									@[cmd].apply @, parsed.args
									
								else if last instanceof Function
									last new SocketError "Function #{cmd} not found on socket!"
						
						buffer = buffer.slice currentPacketLength
						currentPacketLength = 0
					
					else
						break
				
				else
					break
	
	close: ->
		@socket.end()
	
	connect: (host, port, callback) ->
		@socket.connect port, host, callback
	
	call: (cmd, args...) ->
		serializeArguments args
		
		if cmd isnt '__callback__'
			last = args[args.length - 1]
			if last instanceof Function
				unless @connected
					return last(new SocketError "Connection is not established!")
					
				# replace callback with ref
				cbid = utils.guid()
				@_callbacks[cbid] = last
					
				args[args.length - 1] = {__callback__: cbid, toString: -> '[callback]'}
			
			if @connected
				@emit 'info', "[sck:call] -> #{cmd} (#{args.join(', ')})".cyan
		
		else
			# args[0] is corellation id of callback

			if @connected
				@emit 'info', "[sck:cb] -> (#{args.join(', ')})".cyan
			
		unless @connected
			return
		
		data = serialize
			cmd: cmd
			args: args
						
		@socket.write data

class SocketError extends Error
	constructor: (message) ->
		@name = @constructor.name
		@message = message
		Error.captureStackTrace @, @constructor

exports.Socket = Socket
exports.SocketError = SocketError