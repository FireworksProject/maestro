PATH = require 'path'

REQ = require 'request'
DNODE = require 'dnode'

DEFAULT_OPTS =
    hostname: '127.0.0.1'
    appdir: PATH.join(__dirname, 'fixtures')

DEFAULT_PROXY_PORT = 8000
DEFAULT_MONITOR_PORT = 7272


describe 'service monitor', ->
    SRVC = require '../dist/lib/service'

    gService = null

    createService = (callback) ->
        gService = SRVC.createService(DEFAULT_OPTS, callback)
        return gService

    afterEach (done) ->
        if gService is null then return done()
        gService.close ->
            gService = null
            return done()
        return

    
    it 'should start on given addresses', (done) ->
        @expectCount(4)
        service = createService (err, info) ->
            expect(info.proxy.address).toBe(DEFAULT_OPTS.hostname)
            expect(info.proxy.port).toBe(DEFAULT_PROXY_PORT)
            expect(info.rpcserver.address).toBe(DEFAULT_OPTS.hostname)
            expect(info.rpcserver.port).toBe(DEFAULT_MONITOR_PORT)
            return done()
        return


    it 'should accept a rcp request to register an app', (done) ->
        @expectCount(2)
        service = createService (err, info) ->
            app =
                name: 'default-app'
                hostname: 'default.example.com'

            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.register_app app, (err, result) ->
                    expect(result.name).toBe('default-app')
                    expect(result.hostname).toBe('default.example.com')
                    return done()
                return
            return
        return


    it 'should accept a rcp request to restart an app', (done) ->
        @expectCount(1)
        service = createService (err, info) ->
            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.restart_app 'default-app', (err, result) ->
                    if err then return done(new Error(err.message))
                    expect(result).toBe('default-app')
                    return done()
                return
            return
        return

    return


describe 'service controller', ->
    SRVC = require '../dist/lib/service'

    gService = null
    gRPC = null


    registerRestartWebapp = (app, next) ->
        gRPC.register_app app, (err, result) ->
            gRPC.restart_app app.name, (err, result) ->
                if err then next(err)
                return next()
            return
        return


    beforeEach (done) ->
        gService = SRVC.createService DEFAULT_OPTS, (err, info) ->
            if err then return done(err)

            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                gRPC = remote
                app =
                    name: 'default-app'
                    hostname: 'default.example.com'
                registerRestartWebapp app, (err) ->
                    if err then return done(new Error(err.message))
                    return done()
                return
            return
        return


    afterEach (done) ->
        if gService is null then return done()
        gService.close ->
            gService = null
            return done()
        return


    it 'should be able to remotely re-configure an app', (done) ->
        @expectCount(4)
        opts =
            uri: "http://localhost:8000"
            headers: {'host': 'default.example.com'}
        REQ.get opts, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            expect(body).toBe('hello world')
            testReplacement()
            return

        testReplacement = ->
            app =
                name: 'default-app'
                hostname: 'replaced.example.com'
            registerRestartWebapp app, (err) ->
                if err then return done(new Error(err.message))
                opts =
                    uri: "http://localhost:8000"
                    headers: {'host': 'replaced.example.com'}
                REQ.get opts, (err, res, body) ->
                    expect(res.statusCode).toBe(200)
                    expect(body).toBe('hello world')
                    return done()
                return
            return

        return

    return
