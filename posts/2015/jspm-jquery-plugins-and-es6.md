---
title: "jspm, jQuery Plugins, and ES6"
pathname: "/jspm-jquery-plugins-and-es6"
publish_date: 2015-01-14
tags: ["aurelia", "jspm",  jquery-plugins,  es6,  jquery]
---

[jspm](http://jspm.io/) is a new package manager for JavaScript fornt-ends that comes with a universal [module loading system](https://github.com/systemjs/systemjs). It integrates nicely with [npm](https://www.npmjs.com/) by adding a `jspm` property to the `package.json` that specifies what the jspm dependencies are. Mine looks like this:

    "jspm": {
        "directories": {
          "baseURL": "client"
        },
        "dependencies": {
          "Magnific-Popup": "github:dimsemenov/Magnific-Popup@^1.0.0",
          "aurelia-bootstrapper": "^0.8.0",
          "aurelia-http-client": "^0.4.1",
          "bootstrap": "^3.3.1",
          "font-awesome": "^4.2.0",
          "jquery": "^2.1.3"
        }
      }
    

One of the really cool things about jspm is that, while it uses npm to load packages, it allows multiple endpoints to be defined. By default, it has a [Github](https://github.com/) endpoint. This allows packages to be installed from Github if they aren't in the npm registry. This is pretty handy when working with jQuery plugins, since most of them are not on the npm registry.

To control versioning and dependencies jspm also uses a `config.js`. This file is similar to RequireJS's [config](http://requirejs.org/docs/api.html#config): it maps package names to their sources, allows them to specify their dependencies, and it allows shims to be written for packages that don't follow a module loading pattern. If you've ever used RequireJS, you'll recognize the shim configuration as necessary for loading jQuery plugins, which are always looking to modify globally scoped objects.

# Shim Configuration

I am working with a jQuery plugin called [Magnific Popup](https://github.com/dimsemenov/Magnific-Popup), which provides some nice image lightbox gallery functionality. To get it to load nicely, I use this shim:

```json
"shim": {
  "packages": {
    "Magnific-Popup": {
      "main": "Magnific-Popup",
      "format": "global",
      "deps": "jquery",
      "exports": "$.magnificPopup"
    }
  }
}
```

Then below, in the map, I include the Github source:

```js
System.config({
    "map": {
      "Magnific-Popup": "github:dimsemenov/Magnific-Popup@1.0.0",
      //more stuff you don't care about
    }
})
```

If you want to see how these fit together, you can checkout the complete [config.js](https://github.com/tyrsius/portfolio/blob/8bc0217b087c65a6b4b3a4cd0d53e78e64faf4d0/client/config.js) I am using.

# Importing with ES6

If you are trying to use this plugin in an ES6 module, you have to import it first. Normalling an import in ES6 will look like this

    import {Router} from 'router-module';
    

But since jQuery and it's globally scoped plugins are loading into the `default` object, they need a bare import.

    import $ from 'jquery';
    import magnific from 'Magnific-Popup';
    

After that, you can use them on the `$` object as normal

    $('.image-link').magnificPopup({
      type: 'image',
      gallery: { enabled: true }
    });
    
