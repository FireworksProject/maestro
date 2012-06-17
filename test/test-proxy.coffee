HTTP = require 'http'

REQ = require 'request'

gLogBuffer = ''
gNullStream =
    write: (chunk) ->
        gLogBuffer += chunk

gGetLogs = ->
    rv = gLogBuffer
    gLogBuffer = ''
    return rv

DEFAULT_PROXY_PORT = 8000
LOG = require('fplatform-logger').createLogger('test-proxy', {stream: gNullStream})

describe 'http proxy module', ->
    PRX = require '../dist/lib/proxy'

    gServer = null

    createServer = ->
        gServer = PRX.createProxy({LOG: LOG})
        return gServer


    beforeEach (done) ->
        gLogBuffer = ''
        return done()


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


    it 'should accept an HTTP request', (done) ->
        @expectCount(6)
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

                log = JSON.parse(gGetLogs().split('\n')[0])
                expect(log.level).toBe(30)
                expect(log.host_header).toBe('default.example.com:8080')
                expect(log.target_port).toBe(8008)
                expect(log.source_ip).toBe('127.0.0.1')
                return done()
            return
        return


    it 'should return 404 for unregistered domains', (done) ->
        @expectCount(6)
        proxy = createServer()
        proxy.listen DEFAULT_PROXY_PORT, 'localhost', (info) ->
            REQ.get "http://localhost:#{DEFAULT_PROXY_PORT}", (err, res, body) ->
                expect(res.statusCode).toBe(404)
                expect(res.body).toBe("host 'localhost:8000' not found on this server.")

                log = JSON.parse(gGetLogs().split('\n')[0])
                expect(log.level).toBe(30)
                expect(log.host_header).toBe('localhost:8000')
                expect(log.target_port).toBeUndefined()
                expect(log.source_ip).toBe('127.0.0.1')
                return done()
            return
        return
    return
