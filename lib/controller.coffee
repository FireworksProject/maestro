PATH = require 'path'

EventEmitter = require('events').EventEmitter

Q = require 'q'
PROC = require 'proctools'


class exports.Controller extends EventEmitter

    constructor: (spec) ->
        @appdir = spec.appdir
        @logging = if typeof spec.logging is 'boolean' then spec.logging
        else on

    restartApp: (aName, aCallback) ->
        startAppServer(aName, @appdir, @, @logging).fail(aCallback).then (app) ->
            aCallback(null, {name: aName, port: app.port})
            exclude = app.pid
            return killAppServers(aName, exclude)
        return @


exports.createController = (spec) ->
    return new exports.Controller(spec)


startAppServer = (aName, aPath, aEmitter, af_Log) ->
    promise = PROC.findOpenPort().then (port) ->
        opts =
            command: 'node'
            args: [
                PATH.join(aPath, aName, 'apprunner.js')
                '--name', aName
                '--port', port
            ]
            buffer: yes
            timeLimit: 3333
        return PROC.runCommand(opts).then (proc) ->
            if af_Log
                if proc.stdoutBuffer then process.stdout.write(proc.stdoutBuffer)
                if proc.stderrBuffer then process.stderr.write(proc.stderrBuffer)
                proc.stdout.pipe(process.stdout)
                proc.stderr.pipe(process.stderr)
            proc.port = port
            return proc
    return promise


killAppServers = (aName, aExclude) ->
    deferred = Q.defer()

    killProcesses = (processes) ->
        if not processes.length then return deferred.resolve()
        pid = processes.shift().pid
        if pid is aExclude then return killProcesses()
        PROC.kill(pid).fail(deferred.reject).then ->
            return killProcesses(processes)
        return

    regex = new RegExp("\\sapprunner\\.#{aName}\\s")
    PROC.findProcess(regex).then(killProcesses).fail(deferred.reject)
    return deferred.promise
