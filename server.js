const http = require('http');
const url = require('url');
const fs = require('fs');
const { exec } = require('child_process');

const config = require('./config');
const { NationalRailClient, SoapException } = require('./api');
const client = new NationalRailClient(config.token);

const londonStations = JSON.parse(fs.readFileSync('ruby-pathfinder/data/stations.json'));

const sendError = (res, code, error) => {
    res.statusCode = code;
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(JSON.stringify({error}));
};

const sendData = (res, data) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(data);
};

const sendText = (res, data) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(data);
};

const server = http.createServer(async (req, res) => {
    const requested = url.parse(req.url, true);
    const pathSplat = requested.pathname.split('/').filter(x => !!x);
    const operation = pathSplat[0];
    const params = requested.query;

    if (operation === '-') {
        if (pathSplat.length > 1 && pathSplat[1] == 'stations') {
            return fs.readFile('ruby-pathfinder/data/stations.json', (err, data) => {
                if (err) {
                    sendError(res, 500, err);
                }
                else {
                    sendData(res, data);
                }
            });
        }

        if (pathSplat.length > 1 && pathSplat[1] == 'lines') {
            return fs.readFile('ruby-pathfinder/data/lines.json', (err, data) => {
                if (err) {
                    sendError(res, 500, err);
                }
                else {
                    sendData(res, data);
                }
            });
        }

        if (!config.enableRubyPathfinder) {
            sendError(res, 502, 'Ruby pathfinder capability disabled by server config.');
            return;
        }

        const from = londonStations[params.from] ? params.from : null;
        const to = londonStations[params.to] ? params.to : null;

        if (!from || !to) {
            sendError(res, 400, 'Origin or destination station invalid.');
            return;
        }

        exec(`cd ruby-pathfinder && ruby pathfinder.rb '${from}' -- '${to}'`, (err, stdout, stderr) => {
            if (err || stderr) {
                sendError(res, 500, err && stderr ? { err, stderr } : err || stderr);
                return;
            }
            sendData(res, stdout);
            return;
        });

        return;
    }

    const chars = operation.split('');
    const methodName = chars[0].toLowerCase() + chars.slice(1, chars.length).join('');

    try {
        const results = await client[methodName](params);
        sendData(res, JSON.stringify(results));
    }
    catch (ex) {
        if (ex instanceof SoapException) {
            console.log('soap:Fault received from NR server:', ex.message); // eslint-disable-line no-console
            sendError(res, 400, ex.message);
        }
        else {
            sendError(res, 404, ex.message);
        }
    }
});

server.listen(config.port, () => {
    console.log(`Server listening on ${config.port}.`); // eslint-disable-line no-console
});
