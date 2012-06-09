EventEmitter = require('events').EventEmitter

RPC = require './rpcserver'
PRX = require './proxy'
CTRL = require './controller'

# aOpts.appdir
# aOpts.hostname
exports.createService = (aOpts, aCallback) ->
    self = new EventEmitter()

    mProxy = PRX.createProxy()
    mController = CTRL.createController({appdir: aOpts.appdir})

    mRPCServer = RPC.createServer({
        register_app: (app, callback) ->
            mProxy.register(app.name, app.hostname)
            return callback(null, app)

        restart_app: (appname, callback) ->
            mController.restartApp appname, (err, app) ->
                if err then return callback(err)
                mProxy.update(app.name, app.port)
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
