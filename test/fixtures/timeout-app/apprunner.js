var name = process.argv[3];
var port = process.argv[5];
process.title = "apprunner."+ name;

var HTTP = require('http');

setTimeout(function () {
    HTTP.createServer(function (req, res) {
        res.writeHead(200, {'content-type': 'text/plain'})
        res.end('hello world');
    }).listen(port, 'localhost', function () {
        console.log('server running');
    })
}, 1400);
