const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const debug = require('debug')('app:servers:pathfinder');
const config = require('../config');
const ServerError = require('../server_error');

debug('Loading pathfinder stations/lines...');
const stations = JSON.parse(fs.readFileSync(path.join(__dirname, '../ruby-pathfinder/data/stations.json')));
const lines = JSON.parse(fs.readFileSync(path.join(__dirname, '../ruby-pathfinder/data/lines.json')));
debug('Loaded.');

module.exports = async (uri, params, req, res) => {
    const pathSplat = uri.split('/');

    if (!config.enableRubyPathfinder) {
        return { err: new ServerError(503, 'Ruby pathfinder capability disabled by server config.') };
    }

    if (pathSplat[0] === 'stations') {
        debug('data: stations');
        return { type: 'application/json', data: stations };
    }

    if (pathSplat[0] === 'lines') {
        debug('data: lines');
        return { type: 'application/json', data: lines };
    }

    const from = stations[params.from] ? params.from : null;
    const to = stations[params.to] ? params.to : null;

    if (!from || !to) {
        return { err: new ServerError(400, 'Origin or destination station invalid.') };
    }

    debug(`path: ${from} ${to}`);

    const result = await new Promise(resolve => {
        const scriptPath = path.join(__dirname, '../ruby-pathfinder/pathfinder.rb');
        exec(`${config.ruby} ${scriptPath} '${from}' '${to}'`, (err, stdout, stderr) => {
            if (err || stderr) {
                resolve({ err: new ServerError(500, 'Ruby error', err && stderr ? { err, stderr } : err || stderr) });
            }
            resolve({ type: 'application/json', data: stdout });
        });
    });
    return result;
};
