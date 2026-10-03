import "@testing-library/jest-dom";

if (typeof global.fetch === "undefined") {
  global.fetch = jest.fn();
}

if (typeof global.Response === "undefined") {
  global.Response = class Response {
    constructor(body, init = {}) {
      this.status = init.status || 200;
      this.ok = this.status >= 200 && this.status < 300;
      this.headers = new Map(
        Object.entries(init.headers || {})
      );
      this._body = body;
    }

    async json() {
      return JSON.parse(this._body);
    }

    async text() {
      return String(this._body);
    }
  };
}

if (typeof global.Headers === "undefined") {
  global.Headers = class Headers {
    constructor(entries = {}) {
      this._map = new Map(Object.entries(entries));
    }

    get(name) {
      return this._map.get(name);
    }
  };
}
