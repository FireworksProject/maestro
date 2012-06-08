PATH = require 'path'

REQ = require 'request'

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
            expect(info.monitor.address).toBe(DEFAULT_OPTS.hostname)
            expect(info.monitor.port).toBe(DEFAULT_MONITOR_PORT)
            return done()
        return


    it 'should accept an http rcp request to register an app', (done) ->
        @expectCount(3)
        service = createService (err, info) ->
            app =
                name: 'default-app'
                hostname: 'default.example.com'
            opts =
                uri: "http://#{DEFAULT_OPTS.hostname}:#{DEFAULT_MONITOR_PORT}"
                json: {method: 'register_app', params: [app]}
            REQ.post opts, (err, res, body) ->
                if err then return done(err)
                expect(res.statusCode).toBe(201)
                result = body.result
                expect(result.name).toBe('default-app')
                expect(result.hostname).toBe('default.example.com')
                return done()
        return


    it 'should accept an http rcp request to restart an app', (done) ->
        @expectCount(2)
        service = createService (err, info) ->
            opts =
                uri: "http://#{DEFAULT_OPTS.hostname}:#{DEFAULT_MONITOR_PORT}"
                json: {method: 'restart_app', params: 'default-app'}
            REQ.post opts, (err, res, body) ->
                if err then return done(err)
                expect(res.statusCode).toBe(201)
                result = body.result
                expect(result).toBe('default-app')
                return done()
            return
        return

    return


describe 'service controller', ->
    SRVC = require '../dist/lib/service'

    gService = null


    registerRestartWebapp = (app, next) ->
        # Make the rpc request to register the app
        opts =
            uri: "http://#{DEFAULT_OPTS.hostname}:#{DEFAULT_MONITOR_PORT}"
            json: {method: 'register_app', params: [app]}
        REQ.post opts, (err, res, body) ->
            if err then return next(err)

            # Make the rpc requesta to start the app
            opts =
                uri: "http://#{DEFAULT_OPTS.hostname}:#{DEFAULT_MONITOR_PORT}"
                json: {method: 'restart_app', params: app.name}
            REQ.post opts, (err, res, body) ->
                if err then return next(err)
                return next()
            return
        return


    beforeEach (done) ->
        gService = SRVC.createService DEFAULT_OPTS, (err, info) ->
            if err then return done(err)
            app =
                name: 'default-app'
                hostname: 'default.example.com'
            registerRestartWebapp app, (err) ->
                return done(err)
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
                if err then return done(err)
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
