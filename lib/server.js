const http = require('http');
const url = require('url');
const debug = require('debug')('app:base');
const { isObject } = require('./util');

const config = require('./config');

debug('Initialising servers...');
const servers = {
    railator: require('./servers/railator'),
    pathfinder: require('./servers/pathfinder'),
    tfl: require('./servers/tfl')
};

const sendError = (res, code, error) => {
    res.statusCode = code;
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(JSON.stringify({ error }));
};

const sendResponse = (res, type, data) => {
    res.setHeader('Content-Type', type);
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.end(isObject(data) ? JSON.stringify(data) : data);
};

const server = http.createServer(async (req, res) => {
    const requested = url.parse(req.url, true);
    const pathSplat = requested.pathname.split('/').filter(x => !!x);
    const server = pathSplat.splice(0, 1);
    const serverUri = pathSplat.join('/');
    const params = requested.query;

    if (!!servers[server]) {
        // Servers should return an object with type and data keys, where type is the MIME type to return.
        // If there's an error, the returned object should contain an err key with a ServerError value.
        const result = await servers[server](serverUri, params, req, res);
        if (result.err) {
            return sendError(res, result.err.code, { message: result.err.message, data: result.err.data });
        }
        else {
            return sendResponse(res, result.type, result.data);
        }
    }
    else {
        return sendError(res, 404, 'Server not found.');
    }
});

server.listen(config.port, () => {
    debug(`Server listening on ${config.port}.`); // eslint-disable-line no-console
});
