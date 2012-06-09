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

    return
