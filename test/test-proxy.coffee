HTTP = require 'http'

REQ = require 'request'

DEFAULT_PROXY_PORT = 8000

describe 'http proxy module', ->
    PRX = require '../dist/lib/proxy'

    gServer = null

    createServer = ->
        gServer = PRX.createProxy()
        return gServer


    afterEach (done) ->
        if gServer is null then return done()
        gServer.close ->
            gServer = null
            return done()
        return


    it 'should run on given address', (done) ->
        @expectCount(2)
        proxy = createServer()
        proxy.listen DEFAULT_PROXY_PORT, 'localhost', (info) ->
            expect(info.address).toBe('127.0.0.1')
            expect(info.port).toBe(DEFAULT_PROXY_PORT)
            return done()
        return


    it 'should', (done) ->
        appserver = null
        proxy = createServer()
        proxy.listen DEFAULT_PROXY_PORT, 'localhost', (info) ->
            appserver = HTTP.createServer (req, res) ->
                res.writeHead(200, {'content-type', 'text/plain'})
                res.end('hello from 8008')
                return
            appserver.listen(8008, 'localhost', testRequest)

            # Tell the proxy about the new app
            proxy.register('default-app', 'default.example.com')
            proxy.update('default-app', 8008)
            return

        testRequest = ->
            # Send a request to the app through the proxy
            opts =
                uri: "http://localhost:#{DEFAULT_PROXY_PORT}"
                headers: {'host': 'default.example.com:8080'}

            REQ.get opts, (err, res, body) ->
                appserver.close()
                # should probably continue *after* the close event fires

                expect(res.statusCode).toBe(200)
                expect(res.body).toBe('hello from 8008')
                return done()
            return
        return


    it 'should return 404 for unregistered domains', (done) ->
        proxy = createServer()
        proxy.listen DEFAULT_PROXY_PORT, 'localhost', (info) ->
            REQ.get "http://localhost:#{DEFAULT_PROXY_PORT}", (err, res, body) ->
                expect(res.statusCode).toBe(404)
                expect(res.body).toBe("host 'localhost:8000' not found on this server.")
                return done()
            return
        return
    return
