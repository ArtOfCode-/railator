const xmlbuilder = require('xmlbuilder');
const fetch = require('node-fetch');
const xmlParser = require('fast-xml-parser');

const methods = [
    "GetArrBoardWithDetails", "GetArrDepBoardWithDetails", "GetArrivalDepartureBoardByCRS", "GetArrivalDepartureBoardByTIPLOC",
    "GetArrivalBoardByCRS", "GetArrivalBoardByTIPLOC", "GetDepartureBoardByCRS", "GetDepartureBoardByTIPLOC", "GetDepBoardWithDetails",
    "GetDisruptionList", "GetFastestDepartures", "GetFastestDeparturesWithDetails", "GetHistoricDepartureBoard", "GetHistoricServiceDetails",
    "GetHistoricTimeLine", "GetNextDepartures", "GetNextDeparturesWithDetails", "GetServiceDetailsByRID", "QueryHistoricServices", "QueryServices"
];

const apiBaseUrl = 'https://lite.realtime.nationalrail.co.uk/OpenLDBSVWS/ldbsv12.asmx';

const isObject = obj => obj === Object(obj);

module.exports = class NationalRailClient {
    static denamespacify(obj) {
        if (obj instanceof Array) {
            const result = [];
            obj.forEach(x => {
                if (isObject(x) || x instanceof Array) {
                    result.push(NationalRailClient.denamespacify(x));
                }
                else {
                    result.push(x);
                }
            });
            return result;
        }
        else {
            const result = {};
            Object.keys(obj).forEach(k => {
                const splat = k.split(':');
                const newName = splat[splat.length - 1];
                if (isObject(obj[k]) || obj[k] instanceof Array) {
                    result[newName] = NationalRailClient.denamespacify(obj[k]);
                }
                else {
                    result[newName] = obj[k];
                }
            });
            return result;
        }
    }

    constructor (token) {
        this._token = token;

        methods.forEach(m => {
            const chars = m.split('');
            const methodName = chars[0].toLowerCase() + chars.slice(1, chars.length).join('');
            this[methodName] = this.createRequester(m);
        });
    }

    createSoapRequest(body) {
        return xmlbuilder.create({
            'soap:Envelope': {
                '@xmlns:soap': 'http://www.w3.org/2003/05/soap-envelope',
                '@xmlns:typ': 'http://thalesgroup.com/RTTI/2013-11-28/Token/types',
                '@xmlns:ldb': 'http://thalesgroup.com/RTTI/2017-10-01/ldbsv/',
                'soap:Header': {
                    'typ:AccessToken': {
                        'typ:TokenValue': this._token
                    }
                },
                'soap:Body': body
            }
        }).end({ pretty: true });
    }

    createRequester(method) {
        const requestType = `ldb:${method}Request`;
        return async params => {
            const xmlParams = {};
            Object.keys(params).forEach(p => {
                xmlParams[`ldb:${p}`] = params[p];
            });

            const body = this.createSoapRequest({
                [requestType]: xmlParams
            });
            const response = await fetch(apiBaseUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/soap+xml',
                    'Accept-Encoding': 'gzip, deflate'
                },
                body
            });

            const raw = await response.text();
            const data = xmlParser.parse(raw);
            const responseType = `${method}Response`;
            const bodyData = data['soap:Envelope']['soap:Body'][responseType];
            return NationalRailClient.denamespacify(bodyData[Object.keys(bodyData)[0]]);
        };
    }
};