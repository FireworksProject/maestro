EventEmitter = require('events').EventEmitter

DNODE = require 'dnode'


class exports.Server extends EventEmitter

    constructor: (spec) ->
        @connections = []
        @rpcServer = DNODE(spec)

    listen: (aPort, aHost, aCallback) ->
        @rpcServer.once 'ready', =>
            return aCallback(@rpcServer.server.address())
        @rpcServer.listen(aPort, aHost)
        @rpcServer.server.on 'connection', (connection) =>
            @connections.push(connection)
            return
        return @

    close: (aCallback) ->
        connection.destroy() for connection in @connections
        @rpcServer.once('close', aCallback)
        @rpcServer.close()
        return @


exports.createServer = (spec) ->
    register_app = spec.register_app
    restart_app = spec.restart_app

    server = new exports.Server({
        register_app: register_app
        restart_app: restart_app
    })

    return server
