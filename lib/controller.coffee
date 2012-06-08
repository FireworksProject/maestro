PATH = require 'path'

EventEmitter = require('events').EventEmitter

Q = require 'q'
PROC = require 'proctools'


class exports.Controller extends EventEmitter

    constructor: (spec) ->
        @appdir = spec.appdir

    restartApp: (aName, aCallback) ->
        abspath = PATH.join(@appdir, aName)
        startAppServer(aName, abspath).fail(aCallback).then (app) ->
            aCallback(null, {name: aName, port: app.port})
            exclude = app.pid
            return killAppServers(aName, exclude)
        return @


exports.createController = (spec) ->
    return new exports.Controller(spec)


startAppServer = (aName, aPath) ->
    promise = PROC.findOpenPort().then (port) ->
        opts =
            command: 'node'
            args: [
                PATH.join(aPath, 'apprunner.js')
                '--port', port
            ]
            buffer: yes
        return PROC.runCommand(opts).then (proc) ->
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

    regex = new RegExp("\senginemill\s#{aName}\s")
    PROC.findProcess(regex).then(killProcesses).fail(deferred.reject)
    return deferred.promise
