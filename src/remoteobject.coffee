utils = require './utils'

EventEmitter = require('events').EventEmitter

class RemoteObject extends EventEmitter
	neighbor: null
	
	constructor: (@neighbor, callback) ->
		@guid = utils.guid()
		@neighbor.createRemoteObject @, callback

	destroy: ->
		@neighbor.destroyRemoteObject @
	
	call: ->
		@neighbor.callRemoteFunction @guid, arguments...

exports.RemoteObject = RemoteObject