process.title = 'maestro'

SVC = require './lib/service'

main = (argv) ->
    hostname = argv[2]
    appdir = argv[3]

    opts =
        appdir: appdir
        hostname: hostname
    service = SVC.createService opts, (err, info) ->
        console.log(info)
        return
    return

main(process.argv)
