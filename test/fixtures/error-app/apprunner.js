var name = process.argv[3];
var port = process.argv[5];
process.title = "apprunner."+ name;

var HTTP = require('http');

HTTP.createServer(function (req, res) {
    throw new Error('test fatal error');
}).listen(port, 'localhost', function () {
    console.log('server running');
})
