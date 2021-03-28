---
title: "Testing Durandal Code with Jasmine"
url: "/durandal-testing"
date: "2013-12-10"
lastmod: "2016-05-14"
tags: ["durandal", "unit-test", "jasmine", "phantomjs"]
---

Unit Testing in javascript is usually pretty straightforward. You pick a framework like [Jasmine](https://github.com/pivotal/jasmine) or [QUnit](http://qunitjs.com/), you write some tests, and you run them in your browser or in something headless like [PhantomJS](http://phantomjs.org/).

I prefer Jasmine, due solely to exposure, for my test framework. I prefer PhantomJS for running my tests because it is fast and can be done from the terminal, or other browser-less environments like your SSH-to-your-server.

Durandal+Jasmine presents two challenges to the standard setup here.

1. Promises, of the Q variety at least, always run asynchronously (meaning they will be on the next tick no matter what). We don't want to muck with the internals of Q and make the promises synchronous, because that would invalidate our test results.
2. Integration tests will require Durandal framework objects  and plugins (like `app` or `router`) to be loaded. This means bootstrapping Durandal in your test environment.

The framework that Durandal provides is under-equipped to handle these problems. At the time I am writing this, it actually has a severe problem that causes several tests to break: different test groups are all run in the same context, and pollute each other!

The first problem is easy enough to solve. Jasmine natively has some tools for handling async tests, but they are awkward and require a lot of biolerplate. Derick Baily has written an excellent plugin for Jasmine called [Jasmine.Async](https://github.com/derickbailey/jasmine.async) which wraps it up nicely.

The second problem is a bit trickier.

### Organizing our code

All of the code I am about to show you assumes your test directory looks like this:

    project
    |--source
    |	+--YOUR PROJECT SOURCE CODE
    +--tests
    	|--lib
    	|	|--spec.js
    	|	|--spec.html
    	|	|--jasmine.js
    	|	|--jasmineAsync.js
    	|	|--jasmine.console-reporter.js
    	|	|--q.js
    	|	+--durandalHarness.js
    	|--testSpec1.js
    	+--testSpec2.js
    

I organize them this way because once it's set up, I don't need to change anything in the `lib` folder. The tests are what I care about, so I want them seperate and visible. We will cover what each of these files is in turn.

### Creating a 'Spec' file for PhantomJS

PhantomJS runs its tests from a Javascript file, commonly called the `spec` file. Our spec file needs to load Jasmine, Jasmine.Async, any non-AMD code our app requires (in my case the asbolutely wonderful [SugarJS](http://sugarjs.com/) and the [Q library](https://github.com/kriskowal/q)), configure RequireJS and Durandal, and finally run our tests. I am also going to be using the special `jasmine.console-reporter` provided by the Durandal test framework, with a few personal modifications.

I split the spec file in to two parts, because adding javasscript to the page via Phantom's javascript API is clunky. I just use `spec.js` to order the instructions, and I use `spec.html` to setup the environment.

#### The spec.js file

    //Safety Net, exit after two seconds
    setTimeout(function () {
        phantom.exit();
    }, 2000);
    
    //globals: phantom, require, runTests
    var fs = require('fs'),
        Q = require('./q'),
        page = require('webpage').create(),
        specFiles;
    
    //Collect all of the test files we want to run
    //In this case I am assuming they are all the .js files
    //that are up one level
    specFiles = fs.list('../')
        .filter(function (item) {
            return item.indexOf('.js') !== -1;
        })
        //Take the files are append 'tests/' so that our
        //requireJS config can reference them properly
        .map(function (item) {
            return 'tests/' + item.substring(0, item.length - 3);
        });
    
    //Include this line if you want an output the tests
    //you are about to run
    //console.log('\nRunning spec files:' + specFiles.map(function (s) { return '\n' + s; }));
    
    //The console-reporter is new()-ed up for each tests
    //We need a way to track failures across all the run tests
    var runSpecs = { run: 0, failed: 0 };
    var checkForResults = function (message) {
        if (message.indexOf('Specs:') !== -1) {
            runSpecs.run += parseInt(message.replace('Specs: ', ''), 10);
        } else if (message.indexOf('Specs Failed:') !== -1) {
            runSpecs.failed += parseInt(message.replace('Specs Failed: ', ''), 10);
        } else {
            return false;
        }
        return true;
    };
    
    //All of our tests need to run in a clean environment
    //But Phantom can only handle one page at a time
    //Q chains are an easy way to queue up the work
    var test = Q();    
    var chainTest = function (promise, test) {
        return promise.then(function () {
            var defer = Q.defer();    
            page.onConsoleMessage = function (msg) {
                if (msg === "ConsoleReporter finished") {
                    defer.resolve();
                    return;
                }
                if (!checkForResults(msg))
                    console.log(msg);
            };            
            page.onLoadFinished = function () {
                page.evaluate(function (test) {
                    window.specFiles = [test];
                    require(['lib/durandalHarness']);
                }, test);
            };    
            page.open('spec.html');    
            return defer.promise;
        });
    };
    
    //Chain all the tests into one sequence
    for (var i = 0; i < specFiles.length; i++) {
        test = chainTest(test, specFiles[i]);
    }
    
    //Run all the tests, then log the final results
    test.then(function () {
        console.log("");
        console.log("Finished");
        console.log("-----------------");
        console.log('Specs: ' + runSpecs.run + ', Failed: ' + runSpecs.failed);
    }).then(phantom.exit);
    
    test.fail(function(error) {
        console.log('An error occured', error);
        phantom.exit(runSpecs.failed == 0 ? 0 : 1);
    });
    
    test.done();
    

Basically, this file tells Phantom to locate all of the test specs in the parent directory. Then it creates a promise for each test that loads the `spec.html`, connects the `console-reporter`, requires the `durandalHarness` (more on this later), and run the tests. Then it chains all the promises together, and runs the whole thing.

#### The spec.html file

        <!DOCTYPE html>
        <html>
        <head>
            <script type="text/javascript" src="jasmine.js"></script>
            <script type="text/javascript" src="jasmineAsync.js"></script>
            <script type="text/javascript" src="jasmine.console-reporter.js"></script>
            <script type="text/javascript" src="../../source/lib/sugar-1.4.min.js"></script>
            <script type="text/javascript" src="../../source/lib/q.min.js"></script>
            <script type="text/javascript" src="../../source/lib/jquery-1.9.1.js"></script>
            <script type="text/javascript" src="../../source/lib/knockout-2.3.0.js"></script>
            <script type="text/javascript" src="../../source/lib/require/require.js"></script>
            <script type="text/javascript">
                require.config({
                    baseUrl: '../../source/app',
                    paths: {
                        'tests': '../../tests/',
                        'lib': '../../tests/lib/',
                        'text': '../lib/require/text',
                        'durandal': '../lib/durandal/js',
                        'plugins': '../lib/durandal/js/plugins',
                        'transitions': '../lib/durandal/js/transitions',
                        'knockout': '../lib/knockout-2.3.0',
                        'jquery': '../lib/jquery-1.9.1'
                    }
                });
                var runTests = function (specfiles) {
                    require(specfiles, function () {
                        var consoleReporter = new jasmine.ConsoleReporter();
                        jasmine.getEnv().addReporter(consoleReporter);
                        jasmine.getEnv().execute();
                    });
                };
            </script>
        </head>
        <body>
        </body>
        </html>
    

The `script` tags are pretty straightforward. They are running from phantom, so they are relative to the current directory. For our project code, we have to back out and go into the `source` folder. Note here that these paths are written as if `source` directly contains your Durandal code, and this is probably not the case. Adjust your paths accordingly.

the `require.config` might look a bit confusing. The `baseUrl` needs to be the `app` directory so that all the string dependencies in your Durandal modules have the same "relativity" they would as if they were running normally in your browser. But then we need to be able require in our tests, so we need paths to go up and back into the `tests` directory.

Finally, we create ` runTests()` that the `durandalHarness` will call once Durandal has finished its `app.start()` process.

#### The durandalHarness.js file

    define(['durandal/system', 'durandal/app', 'knockout'], function (system, app, ko) {
        app.configurePlugins({
            //Durandal plugins
            router: true,
            dialog: true,
            //App plugins
            widget: {
                kinds: ['grid']
            },
            knockoutExtensions: true,
            knockoutCommands: true,
            qPatch: true,
            envPatch: true
        });
        app.start().then(function () {
            runTests(window.specFiles);
        });
    });
    

This is basically going to mirror your `main.js` file. You need to have Durandal install the plugins so that your code that interacts with them will behave the same way its going to behave in the real-world. You can add any additional configuration you need before calling `runTests()`.

Our environment is setup now. We can write a test, and run it from the terminal. Here is an example test, just to give you an idea.

#### Example test spec

    define(['services/facilities', 'order/add'], function (facilityService, OrderAdd) {
        describe('OrderAddViewmodel', function () {
    
            var async = new AsyncSpec(this),
                sut;
            
            beforeEach(function() {
                sut = new OrderAdd();
            });
    
            it('changing jobTypes sets specialties', function () {
                var jobType = { id: 1, specialties: [{ id: 1, name: 'guy' }, { id: 2, name: 'something' }] };
                
                sut.selectedJobType(jobType);
                
                expect(sut.specialties()).toBe(jobType.specialties);
                expect(sut.selectedSpecialty()).toBe(null);
            });
    
            async.it('activate gets facilities from service', function (done) {
                var facilities = [{ id: 1, name: 'guy' }, { id: 2, name: 'something' }];
    
                //This promise test works a bit differently than the ones below, since it returns the promise,
                //Instead of completing it internally. We can simply attach a .then() to the function call
                spyOn(facilityService, 'getFacilities').andCallFake(function () { return Q(facilities); });
                sut.activate().then(function() {
                    expect(facilityService.getFacilities).toHaveBeenCalled();
                    expect(sut.facilities()).toBe(facilities);
                    done();
                });
            });
        });
    });
    

That's pretty much it. You can call `phantom spec.js` to run these tests from the terminal.

> Like a lot of my Durandal boiler-plate, you can find all of this code in [this Github Repo](https://github.com/tyrsius/VariousExtensions). This code is all inside the `durandalTest` directory.
