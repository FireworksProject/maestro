EventEmitter = require('events').EventEmitter

TEL = require 'telegram'


class exports.Monitor extends EventEmitter

    constructor: ->
        @server = TEL.createServer()
        @server.subscribe 'app-register', (message) =>
            [name, hostname] = message.split(' ')
            @emit('app-register', {name: name, hostname: hostname})
            return
        @server.subscribe 'app-restart', (message) =>
            appname = message
            @emit('app-restart', appname)
            return

    address: ->
        return @server.address()

    listen: (aPort, aHost, aCallback) ->
        @server.listen aPort, aHost, =>
            aCallback(@server.address())
        return @

    close: (aCallback) ->
        @server.once('close', aCallback)
        return @

exports.Monitor::subscribe = exports.Monitor::addListener


exports.createMonitor = ->
    return new Monitor()
