const ServerError = require('../server_error');
const config = require('../config');
const { NationalRailClient, SoapException } = require('../api');
const debug = require('debug')('app:servers:railator');
const client = new NationalRailClient(config.token);

module.exports = async (uri, params, req, res) => {
    const pathSplat = uri.split('/');
    const operation = pathSplat[0];
    const chars = operation.split('');
    const methodName = chars[0].toLowerCase() + chars.slice(1, chars.length).join('');

    try {
        debug(`${methodName}: ${Object.keys(params).map(k => `(${k}: ${params[k]})`).join(', ')}`);
        const results = await client[methodName](params);
        return { type: 'application/json', data: results };
    }
    catch (ex) {
        if (ex instanceof SoapException) {
            debug(`soap:Fault received from NR server: ${ex.message}`);
            return { err: new ServerError(400, ex.message) };
        }
        else {
            return { err: new ServerError(500, ex.message) };
        }
    }
};
