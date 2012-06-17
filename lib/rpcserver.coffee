EventEmitter = require('events').EventEmitter

DNODE = require 'dnode'


class exports.Server extends EventEmitter

    constructor: (@LOG, spec) ->
        @connections = []
        @rpcServer = DNODE(spec)

    listen: (aPort, aHost, aCallback) ->
        @rpcServer.once 'ready', =>
            return aCallback(@rpcServer.server.address())
        @rpcServer.listen(aPort, aHost)
        @rpcServer.server.on 'connection', (connection) =>
            address = connection.remoteAddress
            @LOG.info("RPC connection from #{address}")
            connection.once 'close', (hadError) =>
                if hadError
                    @LOG.warn("RPC socket transmission error from #{connection.remoteAddress}")
                @LOG.info("RPC socket closed from #{address}")
                return
            @connections.push(connection)
            return
        return @

    close: (aCallback) ->
        connection.destroy() for connection in @connections
        @rpcServer.once('close', aCallback)
        @rpcServer.close()
        return @


exports.createServer = (LOG, spec) ->
    register_app = spec.register_app
    restart_app = spec.restart_app

    server = new exports.Server(LOG, {
        register_app: register_app
        restart_app: restart_app
    })

    return server
