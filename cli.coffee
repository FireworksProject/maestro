process.title = 'maestro'

PROC = require 'proctools'
LOG = require('fplatform-logger').createLogger(process.title)

SVC = require './lib/service'

TITLE_RX = /\smaestro\s/

main = (argv) ->
    killOld (err) ->
        if err
            console.error(err.stack or err.toString())
            process.exit(2)

        hostname = argv[2]
        appdir = argv[3]

        opts =
            appdir: appdir
            hostname: hostname
            LOG: LOG
        service = SVC.createService opts, (err, info) ->
            {proxy, rpcserver} = info
            LOG.info("started proxy server on #{proxy.address}:#{proxy.port}")
            LOG.info("started rpc server on #{rpcserver.address}:#{rpcserver.port}")
            return
        return
    return

killOld = (aCallback) ->
    kill = (procs) ->
        if not procs or procs.length is 1 then return aCallback()
        pid = procs.shift()
        return PROC.kill(pid).then(kill)

    PROC.findProcess(TITLE_RX).then(kill).fail(aCallback)
    return

main(process.argv)
