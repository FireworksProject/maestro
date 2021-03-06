EventEmitter = require('events').EventEmitter

HTPX = require 'http-proxy'


class exports.Proxy extends EventEmitter

    constructor: (@LOG) ->
        @applications = {}
        @addresses = {}
        self = @
        @server = createServer @LOG, (hostname) ->
            return self.lookup(hostname)

    update: (aName, aPort) ->
        hostname = @applications[aName]
        @addresses[hostname] = aPort
        return @

    register: (aName, aHost) ->
        @applications[aName] = aHost
        return @

    lookup: (aHost) ->
        return @addresses[aHost]

    address: ->
        return @server.address()

    listen: (aPort, aHost, aCallback) ->
        resolved = false
        server = @server

        onerror = (err) =>
            if err.code is 'EADDRINUSE'
                return setTimeout(startServer , 50)
            return @emit('error', err)

        startServer = ->
            server.once('error', onerror)

            server.listen aPort, aHost, ->
                server.removeListener('error', onerror)
                if resolved then return
                resolved = true
                aCallback(server.address())
                return
            return

        startServer()
        return @

    close: (aCallback) ->
        @server.once('close', aCallback)
        @server.close()
        return @


exports.createProxy = (aOpts) ->
    return new exports.Proxy(aOpts.LOG)


createServer = (LOG, portForHost) ->
    server = HTPX.createServer (req, res, proxy) ->
        hostHeader = req.headers.host or ''
        hostname = hostHeader.split(':').shift()
        opts =
            host: '127.0.0.1'
            port: portForHost(hostname)

        log =
            host_header: hostHeader
            target_port: opts.port
            source_ip: req.connection.remoteAddress
        LOG.info(log, "app request")

        if typeof opts.port isnt 'number'
            if req.url is '/_ping_'
                resBody = "pong"
                statusCode = 200
            else
                resBody = "host '#{hostHeader}' not found on this server."
                statusCode = 404

            resHeaders =
                'content-type': 'text/plain'
                'content-length': Buffer.byteLength(resBody)

            res.writeHead(statusCode, resHeaders)
            res.end(resBody, 'utf8')
            return

        proxy.proxyRequest(req, res, opts)
        return

    return server
