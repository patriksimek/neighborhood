utils = require './utils'

Socket = require('./socket').Socket
RemoteObject = require('./remoteobject').RemoteObject
LocalObject = require('./localobject').LocalObject
RemoteProcess = require('./objects/process').RemoteProcess
LocalProcess = require('./objects/process').LocalProcess

RemoteObjects =
	RemoteProcess: RemoteProcess
	LocalProcess: LocalProcess

class Neighbor extends Socket
	authorized: false
	neighborhood: null
	localObjects: null
	remoteObjects: null
	
	constructor: (@neighborhood, socket) ->
		super socket
		
		@localObjects = {}
		@remoteObjects = {}
		@on 'connect', @handshake.bind(@)
		@on 'close', @clear.bind(@)
	
	clear: ->
		for guid, object of @localObjects
			object.destroy()
		
		for guid, object of @remoteObjects
			object.destroy()
	
	handshake: ->
		@call 'handshake', @neighborhood.name, (err, name) =>
			if err
				@emit 'error', err
				return @close()
			
			@name = name
			@emit 'authorize'
	
	onHandshake: (name, callback) ->
		@name = name
		@authorized = true

		callback? null, @neighborhood.name
		
		process.nextTick =>
			@emit 'authorize'
	
	createRemoteObject: (object, callback) ->
		if object instanceof RemoteObject
			@remoteObjects[object.guid] = object
			@call 'createRemoteObject', object.guid, object.constructor.name, callback
		
	onCreateRemoteObject: (guid, type, callback) ->
		# replace remote with local
		type = "Local#{type.substr(6)}"
		
		if RemoteObjects[type]
			@localObjects[guid] = new RemoteObjects[type] guid, @
			
			if callback
				callback null
			else
				@dispatchRemoteEvent guid, 'create'
			
		else
			if callback
				callback new Error "Unknown remote object: #{type}!"
			else
				@dispatchRemoteEvent guid, 'error', new Error "Unknown remote object: #{type}!"
	
	destroyRemoteObject: (object) ->
		if object instanceof RemoteObject
			delete @remoteObjects[object.guid]
			@call 'destroyRemoteObject', object.guid
	
	onDestroyRemoteObject: (guid) ->
		@localObjects[object.guid].destroy()
		delete @localObjects[object.guid]

	dispatchRemoteEvent: (guid, event) ->
		@call 'dispatchRemoteEvent', arguments...
	
	onDispatchRemoteEvent: (guid, event, args...) ->
		if @remoteObjects[guid]
			@remoteObjects[guid].emit event, args...
	
	callRemoteFunction: (guid, name) ->
		if @remoteObjects[guid]
			@call 'callRemoteFunction', arguments...
	
	onCallRemoteFunction: (guid, name, args...) ->
		if @localObjects[guid]
			if @localObjects[guid][name]
				@localObjects[guid][name].call @localObjects[guid], args...
			else
				@call 'dispatchRemoteEvent', guid, 'error', new Error "Function #{name} not found on remote object."
		else
			@call 'dispatchRemoteEvent', guid, 'error', new Error "Shared object #{guid} not found."
	
exports.Neighbor = Neighbor
exports.RemoteObjects = RemoteObjects