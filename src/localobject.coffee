class LocalObject
	neighbor: null
	
	constructor: (@guid, @neighbor) ->
	
	emit: ->
		@neighbor.dispatchRemoteEvent @guid, arguments...
	
	destroy: ->

exports.LocalObject = LocalObject