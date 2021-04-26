const baseFetch = require('node-fetch');

module.exports = {
    isObject: obj => obj === Object(obj),

    wait: async timeout => {
        return new Promise(resolve => {
            setTimeout(resolve, timeout);
        });
    },

    fetch: async (url, options = {}) => {
        return new Promise((resolve, reject) => {
            options = options || {};
            const controller = new AbortController();
            const timeoutId = !!options.timeout ? setTimeout(() => controller.abort(), options.timeout) : null;
            delete options.timeout;
            baseFetch(url, Object.apply(options, { signal: controller.signal })).then(response => {
                resolve(response);
                if (timeoutId) {
                    clearTimeout(timeoutId);
                }
            }).catch(err => reject(err));
        });
    }
};
