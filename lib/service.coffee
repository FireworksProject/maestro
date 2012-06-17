EventEmitter = require('events').EventEmitter

RPC = require './rpcserver'
PRX = require './proxy'
CTRL = require './controller'

# aOpts.appdir
# aOpts.hostname
exports.createService = (aOpts, aCallback) ->
    LOG = aOpts.LOG
    self = new EventEmitter()

    mProxy = PRX.createProxy({LOG: LOG})
    mController = CTRL.createController({appdir: aOpts.appdir})

    mRPCServer = RPC.createServer(LOG, {
        register_app: (app, callback) ->
            mProxy.register(app.name, app.hostname)
            LOG.info("register app: #{app.name} to #{app.hostname}")
            return callback(null, app)

        restart_app: (appname, callback) ->
            mController.restartApp appname, (err, app) ->
                if err
                    LOG.error(err, "restart app error")
                    return callback(err)

                LOG.info("restart app: #{app.name} on #{app.port}")
                mProxy.update(app.name, app.port)
                LOG.info("update app: #{app.name} on #{app.port}")
                return callback(null, appname)
            return
    })

    mProxy.listen 8000, aOpts.hostname, (proxyAddress) ->
        mRPCServer.listen 7272, aOpts.hostname, (rpcAddress) ->
            aCallback(null, {proxy: proxyAddress, rpcserver: rpcAddress})
            return
        return

    self.close = (callback) ->
        mRPCServer.close ->
            return mProxy.close(callback)
        return

    return self
