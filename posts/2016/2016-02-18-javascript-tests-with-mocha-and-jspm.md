---
title: "JavaScript tests with Mocha and jspm"
pathname: "/javascript-tests-with-mocha-and-jspm"
publish_date: 2016-02-18
tags: ["jspm", "mocha", "unit-test"]
---

It's no secret that I love [jspm](http://jspm.io/). I think it does everything right. I think [Webpack](https://webpack.github.io/) requires far too much configuration. jspm is also much more standards-oriented, so I expect the patterns I learn and develop to last much longer, which is something I sorely need in JavaScript development.

However, testing it is difficult bordering on silly. I just spent three days trying to get tests to work, and the solution I have for you isn't perfect. It requires a harness file, and locking yourself into Babel 5 (for now). I tried [several](http://www.aptoma.com/es6-code-coverage-babel-jspm-karma-jasmine-istanbul/)[different](http://dancras.co.uk/2015/12/31/using-mocha-with-jspm.html)[guides](http://vadosware.com/2016/01/02/using-mocha-with-jspm/), each getting me close-but-not-quite-there.

Let's get to it.

## Setting up dependencies

You will need the following installed by npm, not jspm, since our harness file is run by node.

    "devDependencies": {
        "babel": "^5.8.35",
        "chai": "^3.5.0",
        "debug": "^2.2.0",
        "glob": "^7.0.0",
        "jspm": "^0.16.19",
        "mocha": "^2.4.5",
        "systemjs": "^0.18.17"
      }
    

You shouldn't need `debug`, but I experienced a node module error without it. Not sure what is going on there.

## A harness file

I am using a harness file to load tests with [node-glob](https://github.com/isaacs/node-glob) and then run them with the mocha programmatic api. This is also where I `require('babel/register')` to allow my tests to be written with ES6.

    var Mocha = require('mocha'),
        glob = require('glob')
    
    require('babel/register')
    
    // Instantiate a Mocha instance.
    var mocha = new Mocha()
    
    //Get all the test files
    glob.sync('src/**/*.test.js').forEach(function(file) {
      mocha.addFile(file)
    })
    
    var System = require('systemjs')
    require('../jspm.config.js') //Or whatever your config file is called
    
    //
    //Fixup SystemJS (more on this in a second)
    //
    
    
    // Run the tests.
    mocha.run(function(failures){
        process.on('exit', function () {
            process.exit(failures)
        })
    })
    

This will find all of my tests (I like to colocate them with my source files, you may prefer a `tests` directory), load them into mocha, and start the testing process.

For anything to work correctly though, you probably need to tinker with SystemJS to mock modules or remove any bundles you have configured. I have to mock out modules with browser dependencies, like [axios](https://github.com/mzabriskie/axios).

    System.delete(System.normalizeSync('util/http'));
    System.set(System.normalizeSync('util/http'), System.newModule({ default: { } }));
    

This will remove the existing module and replace it with a completely empty one. You might opt to load up [Sinon](http://sinonjs.org/) and replace the module with a spy here.

You can also remove any bundles you have with this line. I have to do this because my bundles and source code are stored differently than they are hosted, and SystemJS operates on the filesystem when run by node.

    System.bundles = {}
    

Save this file somewhere, and setup a test script to call it in your `package.json`

    "scripts": {
        "test": "node tests/harness.js"
    }
    

## Writing a test

Writing a test will still require you to load the module with SystemJS, unfortunately. You can't just `import` it in like normal. Babel will transform `import`s into `require` calls, and fail to find them since it will look in `node_modules` instead of `jspm_packages`.

    import { expect } from 'chai'
    import System from 'systemjs'
    
    describe('residents page', function() {
        let residents
    
        before(function () {
            return System.import('pages/residents')
                .then((mod) => residents = mod)
        })
    
        describe('Module Loading', function() {
            it('should load', function() {
                expect(residents.default).to.not.be.undefined
            })
        })
    })
    

You'll notice I don't use arrow functions for the mocha before hooks or test suites. Mocha discourages this in its documentation due to the lexical binding of `this` breaking there tests.
