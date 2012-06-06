PROC = require 'proctools'

gProcTitle = /\smaestro\s/

afterRun (done) ->
    kill = (proc) ->
        if not proc.length then return done()
        promise = PROC.kill(proc[0].pid).then ->
            return done()
        return promise

    PROC.findProcess(gProcTitle).then(kill).fail(done)
    return

it 'should run on command', (done) ->
    @expectCount(4)

    whenRunning = (serverProc) ->
        # line = JSON.parse(serverProc.stdoutBuffer)
        # expect(line.msg).toBe("telegram server running at 127.0.0.1:7272")
        expect(serverProc.stderrBuffer).toBe('')

        PROC.findProcess(gProcTitle).then (found) ->
            foundProc = found[0] or {}
            expect(found.length).toBe(1)
            expect(foundProc.pid).toBeA('number')
            expect(serverProc.pid).toBe(foundProc.pid)
            return done()
        return

    opts =
        command: 'dist/cli.js'
        args: []
        buffer: on

    PROC.runCommand(opts).then(whenRunning).fail(done)
    return
