var HTTP = require('http');
var port = process.argv[3];
HTTP.createServer(function (req, res) {
    res.writeHead(200, {'content-type': 'text/plain'})
    res.end('hello world');
}).listen(port, 'localhost', function () {
    console.log('server running');
})
