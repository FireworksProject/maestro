#!/usr/bin/env node

var FS = require('fs')
  , PATH = require('path')
  , abspath = PATH.resolve(__dirname, '../package.json')

var pkg = JSON.parse(FS.readFileSync(abspath, 'utf8'));
process.stdout.write(pkg.version);
