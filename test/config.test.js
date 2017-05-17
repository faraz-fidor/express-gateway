'use strict';

const assert = require('chai').assert;
const sinon = require('sinon');

const pipelinesLoader = require('../src/config-loader/pipelines-loader');

describe('config parser', function() {
  let app = undefined;

  before(function() {
    app = {
      use: sinon.spy()
    };
    pipelinesLoader.bootstrap(app, {
      apiEndpoints: {
        foo: { path: '/foo' },
        bar: { path: '/bar' }
      },
      serviceEndpoints: {
        backend: {
          url: 'http://www.example.com'
        }
      },
      pipelines: [{
        name: 'pipeline1',
        apiEndpoints: [
          'foo', 'bar'
        ],
        policies: [{
            condition: ['always'],
            action: { name: 'throttle' },
          },
          {
            condition: { name: 'always' },
            action: {
              name: 'proxy',
              serviceEndpoint: 'backend'
            }
          }
        ]
      }]
    });
  });

  it('sets up handlers for each public endpoint', function() {
    assert(app.use.calledWithMatch('/foo', sinon.match.func));
    assert(app.use.calledWithMatch('/bar', sinon.match.func));
  });

  it('sets up policies correctly', function() {
    let router = app.use.getCall(0).args[1];
    assert.property(router, 'stack');
    assert.isArray(router.stack);
    assert.lengthOf(router.stack, 2);
  });
});