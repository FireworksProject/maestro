HTTP = require 'http'

EventEmitter = require('events').EventEmitter


class exports.Monitor extends EventEmitter

    constructor: ->
        self = @
        @server = HTTP.createServer (req, res) ->
            body = ''
            req.setEncoding('utf8')
            req.on 'data', (chunk) ->
                body += chunk
                return
            req.on 'end', ->
                rpcRequest = JSON.parse(body)
                self.handleRequest(rpcRequest, res)
                return
            return

    handleRequest: (aReq, aRes) ->
        callback = (err, rv) ->
            response =
                result: rv
                error: null
            returnValue = JSON.stringify(response)
            aRes.writeHead(201, {
                'content-type': 'application/json'
                'content-length': Buffer.byteLength(returnValue)
            })
            aRes.end(returnValue)
            return

        methodName = aReq.method
        switch methodName
            when 'register_app'
                params = ['register_app'].concat(aReq.params)
            when 'restart_app'
                params = ['restart_app'].concat(aReq.params)

        params.push(callback)
        EventEmitter::emit.apply(@, params)
        return @

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

exports.Monitor::subscribe = exports.Monitor::addListener


exports.createMonitor = ->
    return new exports.Monitor()
