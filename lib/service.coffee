EventEmitter = require('events').EventEmitter

MON = require './monitor'
PRX = require './proxy'
CTRL = require './controller'

# aOpts.appdir
# aOpts.hostname
exports.createService = (aOpts, aCallback) ->
    self = new EventEmitter()
    mMonitor = MON.createMonitor()
    mProxy = PRX.createProxy()
    mController = CTRL.createController({appdir: aOpts.appdir})

    mMonitor.on 'app-register', (app) ->
        mProxy.register(app.name, app.hostname)
        return

    mMonitor.on 'app-restart', (appname) ->
        mController.restartApp(appname)
        return

    mController.on 'update', (app) ->
        mProxy.update(app.name, app.port)
        return

    mProxy.listen 8000, aOpts.hostname, (proxyAddress) ->
        mMonitor.listen 7272, aOpts.hostname, (monitorAddress) ->
            aCallback(null, {proxy: proxyAddress, monitor: monitorAddress})
            return
        return

    self.close = (callback) ->
        mMonitor.close ->
            return mProxy.close(callback)
        return

    return self
