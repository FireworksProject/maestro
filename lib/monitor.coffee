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
            if err then return rpcRespondFail(aRes, err)
            return rpcRespondOK(aRes, rv)

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


rpcRespondOK = (aResponse, aResult) ->
    response = rpcResponseText(null, aResult)
    rpcWrite(aResponse, 201, response)
    return


rpcRespondFail = (aResponse, aError) ->
    response = rpcResponseText(aError)
    rpcWrite(aResponse, 500, response)
    return


rpcResponseText = (err, rv) ->
    response =
        result: rv or null
        error: err or null
    return JSON.stringify(response)


rpcWrite = (aResponse, aStatus, aText) ->
    aResponse.writeHead(aStatus, {
        'content-type': 'application/json'
        'content-length': Buffer.byteLength(aText)
    })
    aResponse.end(aText)
    return
