EventEmitter = require('events').EventEmitter

DNODE = require 'dnode'


class exports.Server extends EventEmitter

    constructor: (@LOG, spec) ->
        @connections = []
        @rpcServer = DNODE(spec)

    listen: (aPort, aHost, aCallback) ->
        # If the server is already running
        if @rpcServer.server
            return aCallback(@rpcServer.server.address())

        self = @
        log = @LOG
        rpcServer = @rpcServer
        connections = @connections

        onerror = ->
            resolved = false
            handler = (err) ->
                if resolved then return
                resolved = true
                if err.code is 'EADDRINUSE'
                    return setTimeout(startServer , 50)
                return self.emit('error', err)
            return handler

        startServer = ->
            errorHandler = onerror()

            rpcServer.once 'ready', ->
                server = rpcServer.server
                addr = server.address()
                if not addr then return

                rpcServer.removeListener('error', errorHandler)

                server.on 'connection', (connection) =>
                    address = connection.remoteAddress
                    log.info("RPC connection from #{address}")
                    connection.once 'close', (hadError) =>
                        if hadError
                            log.warn("RPC socket transmission error from #{connection.remoteAddress}")
                        log.info("RPC socket closed from #{address}")
                        return
                    connections.push(connection)
                    return

                return aCallback(addr)

            rpcServer.on('error', errorHandler)
            rpcServer.listen(aPort, aHost)
            return

        startServer()
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
