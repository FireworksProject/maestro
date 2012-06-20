PATH = require 'path'

PROC = require 'proctools'
DNODE = require 'dnode'
REQ = require 'request'

FIXTURES = PATH.join(__dirname, 'fixtures')
DEFAULT_PROXY_PORT = 8000
DEFAULT_MONITOR_PORT = 7272

gProcTitle = /\smaestro\s/

kill = (done) ->
    kill = (proc) ->
        if not proc.length then return done()
        promise = PROC.kill(proc[0].pid).then ->
            return done()
        return promise

    PROC.findProcess(gProcTitle).then(kill).fail(done)
    return

afterEach(kill)


it 'should run on command', (done) ->
    @expectCount(7)

    whenRunning = (serverProc) ->
        writeCount = 0
        buff = ''
        serverProc.stdout.on 'data', (chunk) ->
            buff += chunk
            writeCount += 1
            if writeCount > 1 then return test(buff, serverProc)
            return
        serverProc.stderr.on 'data', (chunk) ->
            return done(new Error(chunk))
        return

    test = (buff, serverProc) ->
        lines = buff.split('\n')
        proxyMessage = JSON.parse(lines[0])
        rpcMessage = JSON.parse(lines[1])

        expect(proxyMessage.level).toBe(30)
        expect(proxyMessage.msg).toBe("started proxy server on 127.0.0.1:8000")
        expect(rpcMessage.level).toBe(30)
        expect(rpcMessage.msg).toBe("started rpc server on 127.0.0.1:7272")

        PROC.findProcess(gProcTitle).then (found) ->
            foundProc = found[0] or {}
            expect(found.length).toBe(1)
            expect(foundProc.pid).toBeA('number')
            expect(serverProc.pid).toBe(foundProc.pid)
            return done()
        return

    opts =
        command: 'dist/cli.js'
        args: ['localhost']
        background: on

    PROC.runCommand(opts).then(whenRunning).fail(done)
    return


it 'should log application output', (done) ->
    @expectCount(1)

    timeout = null
    self = @
    whenRunning = (serverProc) ->
        DNODE.connect DEFAULT_MONITOR_PORT, '127.0.0.1', (remote) ->
            app =
                name: 'error-app'
                hostname: 'error.example.com'
            remote.register_app app, (err, result) ->
                remote.restart_app app.name, (err, result) ->
                    if err then done(new Error(err.message))
                    return test(serverProc.stderr)
                return
        return

    test = (serverStderr) ->
        serverStderr.on 'data', (chunk) ->
            check = /Error: test fatal error/.test(chunk)
            if check
                expect(check).toBe(true)
                if timeout then clearTimeout(timeout)
                return done()
            return

        req =
            uri: "http://localhost:8000"
            headers: {'host': 'error.example.com'}
        REQ.get req, (err, res, body) ->
            return
        return

    opts =
        command: 'dist/cli.js'
        args: ['localhost', FIXTURES]
        buffer: on

    PROC.runCommand(opts).then(whenRunning).fail(done)

    timeout = setTimeout(done, 1000)
    return
