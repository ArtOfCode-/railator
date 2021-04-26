const { fetch, wait } = require('../util');
const colors = require('colors');
const debug = require('debug')('app:servers:tfl');
const ServerError = require('../server_error');
const config = require('../config');

let loaded = false, loadError = false;
const modes = ['tube', 'dlr', 'overground', 'tflrail'];
const types = ['NaptanMetroStation', 'NaptanRailStation'];

const apiBase = 'https://api.tfl.gov.uk/';

const apiRequest = async (uri, params = {}, timeout = null) => {
    params = Object.apply(params, {
        app_id: config.tfl_app_id,
        app_key: config.tfl_app_key
    });
    const requestUri = `${apiBase}${uri}?${Object.keys(params).map(k => `${k}=${params[k]}`).join('&')}`;
    const response = await fetch(requestUri, { timeout });
    return response;
};

const jsonRequest = async (uri, params = {}, timeout = null) => {
    const response = await apiRequest(uri, params, timeout);
    const json = await response.json();
    return json;
};

const jsonRequestWithRetries = async (uri, params = {}, retries = 3, backoff = 1000, timeout = 5000) => {
    while (retries > 0) {
        const resp = await apiRequest(uri, params, timeout);
        if (resp.status >= 200 && resp.status < 300) {
            const json = await resp.json();
            return json;
        }
        else {
            retries--;
            if (retries > 0) {
                debug(`${colors.yellow('warn')}: ${uri} returned ${resp.status}, retries remaining ${retries}`);
            }
            else {
                debug(`${colors.red('error')}: ${uri} returned ${resp.status}, no more retries`);
            }
            await wait(backoff);
        }
    }
};

let stopPoints = null;

(async () => {
    debug('Loading TfL data...');
    stopPoints = await jsonRequestWithRetries(`StopPoint/Type/${types.join(',')}`);
    if (stopPoints != null) {
        loaded = true;
    }
    else {
        loadError = true;
    }
    debug('Loaded.');
})();

module.exports = async (uri, params, req, res) => {
    const pathSplat = uri.split('/');
    const operation = pathSplat[0];

    // Operations requiring no data loading, or where data is loaded on the fly, go at the top.

    if (operation === 'Disruption') {
        const disruption = await jsonRequest('StopPoint/Mode/tube,dlr,overground,tflrail/Disruption');
        return { type: 'application/json', data: disruption };
    }

    if (!loaded) {
        const message = loadError ? 'Error loading TfL service data. Contact the server administrator.' :
            'TfL service data not yet loaded. Retry your request in a few minutes.';
        return { err: new ServerError(503, message) };
    }

    // Operations requiring data to be pre-loaded go after this point.

    if (operation === 'ListStopPoints') {
        console.log(stopPoints);
        return { type: 'application/json', data: stopPoints };
    }


    return { err: new ServerError(404, 'TfL action not found.') };
};