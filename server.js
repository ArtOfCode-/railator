const http = require('http');
const url = require('url');

const config = require('./config');
const NationalRailClient = require('./api');
const client = new NationalRailClient(config.token);

const server = http.createServer(async (req, res) => {
    const requested = url.parse(req.url, true);
    const operation = requested.pathname.split('/').filter(x => !!x)[0];
    const params = requested.query;

    const chars = operation.split('');
    const methodName = chars[0].toLowerCase() + chars.slice(1, chars.length).join('');

    const results = await client[methodName](params);
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(results));
});

server.listen(config.port, () => {
    console.log(`Server listening on ${config.port}.`);
});
