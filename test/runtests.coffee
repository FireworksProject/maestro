FS = require 'fs'
PATH = require 'path'

TRM = require 'treadmill'

checkTestFile = (filename) ->
    return /^test/.test(filename)

resolvePath = (filename) ->
    return PATH.join(__dirname, filename)

listing = FS.readdirSync(__dirname)
filepaths = listing.filter(checkTestFile).map(resolvePath)

TRM.run filepaths, (err) ->
    if err then process.exit(2)
    process.exit()
