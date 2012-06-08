EventEmitter = require('events').EventEmitter

HTPX = require 'http-proxy'


class exports.Proxy extends EventEmitter

    constructor: ->
        @applications = {}
        @addresses = {}
        self = @
        @server = createServer (hostname) ->
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
        @server.listen aPort, aHost, =>
            aCallback(@server.address())
        return @

    close: (aCallback) ->
        @server.once('close', aCallback)
        @server.close()
        return @


exports.createProxy = ->
    return new exports.Proxy()


createServer = (portForHost) ->
    server = HTPX.createServer (req, res, proxy) ->
        hostHeader = req.headers.host
        opts =
            host: '127.0.0.1'
            port: portForHost(hostHeader)

        if typeof opts.port isnt 'number'
            resBody = "host '#{hostHeader}' not found on this server."
            resHeaders =
                'content-type': 'text/plain'
                'content-length': resBody.length

            aResponse.writeHead(404, resHeaders)
            aResponse.end(resBody, 'utf8')
            return

        proxy.proxyRequest(req, res, opts)
        return
    return
