Neighborhood = require('../').Neighborhood
RemoteObjects = require('../').RemoteObjects
assert = require "assert"

n1 = null
n2 = null
process = null

describe 'neighborhood test suite', ->
	before (done) ->
		done null
	
	it 'start controller', (done) ->
		n1 = new Neighborhood
			name: 'master'
			port: 7777
			district: 'github.com'
			controller: true
		
		n1.on 'online', done
		n1.on 'error', done
	
	it 'start worker', (done) ->
		n2 = new Neighborhood
			name: 'slave'
			district: 'github.com'
			
		n2.on 'online', done
		n2.on 'error', done
	
	it 'create remote object', (done) ->
		process = new RemoteObjects.RemoteProcess(n1.neighbors[0], done)
	
	it 'fork remote process', (done) ->
		process.fork 'dev3.coffee'
		process.on 'online', -> done()
		process.on 'error', done
	
	it 'kill remote process', (done) ->
		process.kill()
		process.on 'close', -> done()
		process.on 'error', done