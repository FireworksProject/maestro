process.title = 'maestro'

LOG = require('fplatform-logger').createLogger(process.title)

SVC = require './lib/service'

main = (argv) ->
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

main(process.argv)
