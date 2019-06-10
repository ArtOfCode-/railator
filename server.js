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

    try {
        const results = await client[methodName](params);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.end(JSON.stringify(results));
    }
    catch (ex) {
        console.log('soap:Fault received from NR server:', ex.message); // eslint-disable-line no-console
        res.statusCode = 400;
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.end(JSON.stringify({error: ex.message}));
    }
});

server.listen(config.port, () => {
    console.log(`Server listening on ${config.port}.`); // eslint-disable-line no-console
});
