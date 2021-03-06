PATH = require 'path'

REQ = require 'request'
DNODE = require 'dnode'

gLogBuffer = ''
gNullStream =
    write: (chunk) ->
        gLogBuffer += chunk

gGetLogs = ->
    rv = gLogBuffer
    gLogBuffer = ''
    return rv

DEFAULT_OPTS =
    hostname: '127.0.0.1'
    appdir: PATH.join(__dirname, 'fixtures')
    logging: off
    LOG: require('fplatform-logger').createLogger('test-service', {stream: gNullStream})

DEFAULT_PROXY_PORT = 8000
DEFAULT_MONITOR_PORT = 7272


describe 'service monitor', ->
    SRVC = require '../dist/lib/service'

    gService = null

    createService = (callback) ->
        gService = SRVC.createService(DEFAULT_OPTS, callback)
        return gService

    beforeEach (done) ->
        gLogBuffer = ''
        return done()

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
        @expectCount(5)
        service = createService (err, info) ->
            app =
                name: 'default-app'
                hostname: 'default.example.com'

            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.register_app app, (err, result) ->
                    logs = gGetLogs().split('\n')
                    connectionLog = JSON.parse(logs[0])
                    registerLog = JSON.parse(logs[1])
                    expect(connectionLog.level).toBe(30)
                    expect(connectionLog.msg).toBe("RPC connection from 127.0.0.1")
                    expect(registerLog.level).toBe(30)
                    expect(registerLog.msg).toBe("register app: default-app to default.example.com")

                    expect(result['default-app']).toBe('default.example.com')
                    return done()
                return
            return
        return


    it 'should accept a rcp request to restart an app', (done) ->
        @expectCount(5)
        service = createService (err, info) ->
            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.restart_app 'default-app', (err, result) ->
                    if err then return done(new Error(err.message))

                    # The last test will leave a hanging log line which we want
                    # to igore for this test.
                    logs = gGetLogs().split('\n')
                    if /RPC socket closed/.test(JSON.parse(logs[0]).msg)
                        logs.shift()

                    connectionLog = JSON.parse(logs[0])
                    registerLog = JSON.parse(logs[1])
                    expect(connectionLog.level).toBe(30)
                    expect(connectionLog.msg).toBe("RPC connection from 127.0.0.1")
                    expect(registerLog.level).toBe(30)
                    expect(/restart app: default-app on/.test(registerLog.msg)).toBe(true)

                    expect(result['default-app']).toBeUndefined()
                    return done()
                return
            return
        return


    it 'should register an app with long start time', (done) ->
        @expectCount(5)

        service = createService (err, info) ->
            app =
                name: 'timeout-app'
                hostname: 'timeout.example.com'

            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.register_app app, (err, result) ->
                    # The last test will leave a hanging log line which we want
                    # to igore for this test.
                    logs = gGetLogs().split('\n')
                    if /RPC socket closed/.test(JSON.parse(logs[0]).msg)
                        logs.shift()

                    connectionLog = JSON.parse(logs[0])
                    registerLog = JSON.parse(logs[1])
                    expect(connectionLog.level).toBe(30)
                    expect(connectionLog.msg).toBe("RPC connection from 127.0.0.1")
                    expect(registerLog.level).toBe(30)
                    expect(registerLog.msg).toBe("register app: timeout-app to timeout.example.com")

                    expect(result['timeout-app']).toBe('timeout.example.com')
                    return done()
                return
            return
        return


    it 'should restart an app with a long start time', (done) ->
        @expectCount(5)
        service = createService (err, info) ->
            DNODE.connect DEFAULT_MONITOR_PORT, DEFAULT_OPTS.hostname, (remote) ->
                remote.restart_app 'timeout-app', (err, result) ->
                    if err then return done(new Error(err.message))

                    # The last test will leave a hanging log line which we want
                    # to igore for this test.
                    logs = gGetLogs().split('\n')
                    if /RPC socket closed/.test(JSON.parse(logs[0]).msg)
                        logs.shift()

                    connectionLog = JSON.parse(logs[0])
                    registerLog = JSON.parse(logs[1])
                    expect(connectionLog.level).toBe(30)
                    expect(connectionLog.msg).toBe("RPC connection from 127.0.0.1")
                    expect(registerLog.level).toBe(30)
                    expect(/restart app: timeout-app on/.test(registerLog.msg)).toBe(true)

                    expect(result['timeout-app']).toBeUndefined()
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
                return next(null, result)
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
        @expectCount(5)
        opts =
            uri: "http://localhost:8000"
            headers: {'host': 'default.example.com'}
        REQ.get opts, (err, res, body) ->
            if err then return done(new Error(err.message))
            expect(res.statusCode).toBe(200)
            expect(body).toBe('hello world')
            testReplacement()
            return

        testReplacement = ->
            app =
                name: 'default-app'
                hostname: 'replaced.example.com'
            registerRestartWebapp app, (err, result) ->
                if err then return done(new Error(err.message))

                expect(result['default-app']).toBe('replaced.example.com')

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
