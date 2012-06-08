PATH = require 'path'

DEFAULT_OPTS =
    hostname: '127.0.0.1'
    appdir: PATH.join(__dirname, 'fixtures')

DEFAULT_PROXY_PORT = 8000
DEFAULT_MONITOR_PORT = 7272


describe 'service module', ->
    SRVC = require '../dist/lib/service'

    gService = null

    createService = (callback) ->
        gService = SRVC.createService(DEFAULT_OPTS, callback)
        return gService

    beforeRun (done) ->
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

    return
