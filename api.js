const xmlbuilder = require('xmlbuilder');
const fetch = require('node-fetch');
const xmlParser = require('fast-xml-parser');

const methods = [
    "GetArrBoardWithDetails", "GetArrDepBoardWithDetails", "GetArrivalDepartureBoardByCRS", "GetArrivalDepartureBoardByTIPLOC",
    "GetArrivalBoardByCRS", "GetArrivalBoardByTIPLOC", "GetDepartureBoardByCRS", "GetDepartureBoardByTIPLOC", "GetDepBoardWithDetails",
    "GetDisruptionList", "GetFastestDepartures", "GetFastestDeparturesWithDetails", "GetHistoricDepartureBoard", "GetHistoricServiceDetails",
    "GetHistoricTimeLine", "GetNextDepartures", "GetNextDeparturesWithDetails", "GetServiceDetailsByRID", "QueryHistoricServices", "QueryServices"
];

const referenceMethods = ["GetReasonCode", "GetReasonCodeList", "GetSourceInstanceNames", "GetStationList", "GetTOCList"];

const apiBaseUrl = 'https://lite.realtime.nationalrail.co.uk/OpenLDBSVWS/ldbsv12.asmx';
const apiActionBase = 'http://thalesgroup.com/RTTI/2012-01-13/ldbsv';
const referenceBaseUrl = 'https://lite.realtime.nationalrail.co.uk/OpenLDBSVWS/ldbsvref.asmx';
const refActionBase = 'http://thalesgroup.com/RTTI/2015-05-14/ldbsv_ref';

const isObject = obj => obj === Object(obj);

module.exports = class NationalRailClient {
    static denamespacify(obj) {
        if (obj instanceof Array) {
            const result = [];
            obj.forEach(x => {
                if (isObject(x) || x instanceof Array) {
                    if (x['attr'] && x['attr']['xmlns']) {
                        delete x['attr']['xmlns'];
                        if (Object.keys(x['attr']).length === 0) {
                            delete x['attr'];
                        }
                    }

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

                    if (result[newName]['attr'] && result[newName]['attr']['xmlns']) {
                        delete result[newName]['attr']['xmlns'];
                        if (Object.keys(result[newName]['attr']).length === 0) {
                            delete result[newName]['attr'];
                        }
                    }
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

        referenceMethods.forEach(m => {
            const chars = m.split('');
            const methodName = chars[0].toLowerCase() + chars.slice(1, chars.length).join('');
            this[methodName] = this.createRequester(m, true);
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

    createRequester(method, isReference = false) {
        const requestType = `ldb:${method}Request`;
        return async params => {
            const xmlParams = {};
            Object.keys(params).forEach(p => {
                xmlParams[`ldb:${p}`] = params[p];
            });

            const body = this.createSoapRequest({
                [requestType]: xmlParams
            });
            const response = await fetch(isReference ? referenceBaseUrl : apiBaseUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': `application/soap+xml;charset=UTF-8;action=${isReference ? refActionBase : apiActionBase}/${method}`,
                    'Accept-Encoding': 'gzip, deflate'
                },
                body
            });

            const raw = await response.text();
            const data = xmlParser.parse(raw, { textNodeName: 'content', attributeNamePrefix: '', attrNodeName: 'attr', ignoreAttributes: false });
            const responseType = `${method}Response`;
            const bodyData = data['soap:Envelope']['soap:Body'][responseType];
            return NationalRailClient.denamespacify(bodyData[Object.keys(bodyData).filter(x => x !== 'attr')[0]]);
        };
    }
};