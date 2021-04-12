module.exports = class ServerError extends Error {
  constructor (code, message, data) {
    super(message);
    this.code = code;
    this.data = data;
  }
};
