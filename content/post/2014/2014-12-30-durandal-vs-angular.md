---
title: "Durandal vs Angular"
url: "/durandal-vs-angular"
date: "2014-12-31"
lastmod: "2016-05-18"
---

Yep, time to throw in my $.02. I've used Durandal on multiple personal projects, as well as a large professional project spanning several months. I have used Angular on two personal projects, and am currently using it at work. I have a lot more experience with Durandal than I do with Angular, so if I make any factual errors here feel free to let me know. I would love to be wrong about some of my gripes, since that would mean not having to deal with them.

# Configuration

Configuration is work you want to do before you application really starts. It could involve configuration your router, setting up constants that various modules need, loading plugins, or anything else that needs to happen before the first page is shown to the user.

So how does Angular do configuration? With **configuration modules** of course. What makes a configuration module different than other modules? Well, it can only have constants and providers injected, it can't use services or factories. Additionally, it cannot perform any asychronous work. Period.

If you want to talk to your server to get information that you use for configuring your routes (like which links to show in the nav bar) you can't. Both because you can't load services in configuration modules, and because the configuration module completes synchronously. This just isn't an option.

Here is how Durandal does it's application config and startup:

        define(['durandal/app'], function(app) {
            app.configurePlugins({
                router: true,
                dialog: true
            });
    
            app.start().then(function () {
                app.setRoot('shell/shell');
            });
        });
    

Wait, do you need to do some configuration before your application starts? Is some of it asynchronous? Is some of it in a service module? Whatever, piece of cake.

    define(['durandal/app', 'some/serviceModule'], 
        function(app, module) {
            app.configurePlugins({
                router: true,
                dialog: true
            });
            
    		module.promiseReturningMethod()
                .then(function() {
                    //Do some shit
                })
                .then(app.start)
                .then(function () {
                    app.setRoot('shell/shell');
                });
        });
    

Durandal handles async like a champ since it uses promises internally for everything. Configuration is whatever the hell you want it to be, because Durandal has no concept of specialized modules for configuration. If you want to run some code you just load the module and run it. Want to run back to your webserver to get some configuration values before your app starts? Go ahead. Want to just run some stupid animation before databinding? Whatever, Durandal doesn't care.

Awesome.

Durandal wins by such a large margin here that it's shocking to me. This is my single largest problem with Angular.

# Page Lifecycle

Let's say a user tries to navigate from one page to another. What kind of control do you have over this, and where are the hooks for that control?

In Angular it depends on the router you are using. The community seems to be pretty heavily on the side of the [UI Router](https://github.com/angular-ui/ui-router) because of it's ability to handle nested routes, [unlike ngRoute](http://stackoverflow.com/a/15637469/788260).

The UI Router provides two hooks for controlling navigation.

- You can attach callbacks to `$stateChangeStart` to inspect the state change. You can sychronously cancel it, and then redirect if you want. You get access to `event, toState, toParams, fromState, fromParams` to make the decision with. This can be from anywhere.
- You can create a `resolve` handler to gather data to inject into the controller. This can be done with promises, which the router resolves before instantiating the controller. This handler is defined during configuration, as part of the state.

[Durandal's lifecycle](http://durandaljs.com/documentation/Hooking-Lifecycle-Callbacks.html) has several events, but only three offer control over the lifecycle. For this section the **current** viewmodel is the active page and the **target** viewmodel is the page being navigated to.

- `canDeactive` is a method defined on the current page viewmodel which can synchronously or asychronously stop navigation.
- `canActivate` is a method defined on the target page viewmodel which can sychronously or asychronously stop navigation.
- `activate` is a method on the targte page viewmodel which recieves activation parameters from the router. It can also delay navigation from completing by returning a promise, which the router will wait on.

Additionally, navigation can be guarded by attaching a `guardRoute` handler to the router. This can be done from anywhere.

So Angular allows navigation to be canceled sychronously from handlers which can be defined anywhere. Durandal allows navigation to be cancelled synchronously from handlers which can be defined anywhere, or with standard viewmodel methods which can return sync or promises. This is a clear win for Durandal, but it gets better.

Angular activates controller's with optional promises, but these promises are defined *outside* the controller, during state configuration. This limits their flexibility (you can't actually use the controllers inside of these promise), and keeps the activation logic for controllers spread out. Durandal activates viewmodels with optional promises defined *inside* the viewmodel, which can reference the viewmodel and any of its dependencies, and keeps the activation logic in one place.

Durandal does this miles better than Angular.

# Custom DOM Behavior

Angular's answer to custom DOM behavior is the directive (there are also things like filters but let's stay focused). The [directive definition object](https://docs.angularjs.org/api/ng/service/$compile) has got to be, hands down, the most confusing thing in Angular. It can be a `link` or a `controller`, have an isolated scope or a normal inheriting scope, bind to [attributes with a multi-symbol syntax](https://docs.angularjs.org/api/ng/service/$compile#-scope-), and a just staggering number of other configuration properties. I still don't understand how all of them interact together, and there are some crazy edge cases.

Durandal handles Custom DOM behavior with either a component, a widget, or a binding handler. Components and binding handlers are both Knockout concepts, and Durandal introduced widgets before Knockout Components to serve a similar case. Here's the thing though: all of them have super simple API's, without sacrificing a single ounce of power of flexibility.

- Binding Handler: `function(element, valueAccessor, allBindings, viewModel, bindingContext)`. Of these, usually only the 1st two are ever needed. Analogous to "attribute directives."
- Widget: Just a regular Durandal viewmodel module, with support for transclusion with `data-part` HTML attributes. Analogous to "transclusion directives."
- Component: Analogous to "controller directives." Register with

     ko.components.register('some-component-name', {
           viewModel: [viewModelOrRequirePath],
           template: [templateOrRequirePath
    }
    

Each of them are for a specific use case, which may seem confusing at first. That may be fair point, but actually working with them is very straightforward due to their simple API's.

It's very hard for me to look at Angular's directives and see anything but a mess.

# Dependency Injection and Testing (Mocks)

Durandal's answer to this is still RequireJS. Nothing new. If you want to mock out your dependencies though, nothing is provided for you. In fact, testing with Durandal at all can be kind of challenging. However, RequireJS is a standard tech, so external plugins and guides exist for doing this.

Angular has excellent tools here. [Karma](http://karma-runner.github.io/0.12/index.html) works basically out of the box, and Angular has built-in DI mocking.

I have to give it to Angular here, they took testing seriously and it shows. I would really like to see Durandal improve in this area.

# Documentation

Durandal's documenation is pretty light. There is definitely a sense that it was rushed, there are pieces that feel incomplete, and sometimes information feels like its on the wrong page. However, its possible to read through the whole thing in a single sitting. In addition to the actual documentation Durandal has API pages have been automatically generated, but they are largely worthless.

Angular's documentation is thick, but I find it incredibly frustrating. Its verbose, often reading like a technical book instead of documentation. Many pages are slim, lacking in examples, or worse lacking the actual API for the thing. It can also be painful when the examples blend in with the actual API, making it difficult to find what options are available without reading large and irrelevant blocks of text.

Even worse, Angular's documentation always defaults to the most recent build, instead of the last stable release. This can cause major problems when the API has changed and you are in a rush. I've been bitten by this several times, most often with the promise page (the API is completely changed between 1.2 and 1.3).

Both frameworks could use improvement here, but I honestly prefer Durandal's. Durandal's API has a much smaller surface area than Angular's, so it gets away with smaller documentation without suffering as much.

# Versioning

Angular doesn't practice semantic versioning. Durandal does. Need I continue?

Actually yes, I need to, because Angular doesn't even practice API versioning. They have even introduced *breaking changes* between release candidates before. Not just breaking changes like "this was working one way because of a bug and we fixed it", but actually changing the *names* and *parameters* of methods.

When an API goes to RC it should be **frozen**. Period. Angular's management of versions is incredibly frustrating.

# Summary

I think it's pretty fair to compare these two frameworks, despite the heavily unbalanced popularity, community, and developement effort behind them. Angular has the lead in all three, and they are both targeting the same market and trying to serve the same purpose. And yet I prefer Durandal.

Angular feels over-engineered, complicated, and doesn't seem to have a problem with this. It handles component lifecycle poorly, creates a staggering amount of new concepts (i.e. scope, directives, providers) some with little or even negative value, has no respect for versioning, and seems OK with the fact that it has an incredibly steep learning curve.

Durandal was easy to learn (though in fairness, I already knew Knockout, which was also easy to learn), has a simple-yet-powerful API, introduces only a few new concepts, and respects versioning. It has some work to do in the testing arena, and its documentation could be improved, but these don't tip the scales for me.
