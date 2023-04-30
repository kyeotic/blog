---
title: "FireBind: Knockout bindings for Firebase"
pathname: "/firebind"
publish_date: 2013-12-11
---

Everybody loves [Knockout](http://knockoutjs.com) (or they should, because it's fantastic). I think less people know about [Firebase](https://www.firebase.com/), but its a very cool service. It basically provides a real-time backend for persistent data, along with either client libraries or a REST api for subscribing to the changes in that data.

When I first found out about Firebase, I had already been working on [a personal project](https://github.com/tyrsius/chaoscrusade) that had been inspired by [Meteor](http://www.meteor.com) which had a similar cross-client-real-time-data backend. It isn't nearly as clean as Firebase, but then it was something I hand-rolled with NodeJS and [Socket.IO](http://socket.io/). Luckily, the Knockout bindings I had written for this were pretty easily adapted to using Firebase instead, since they worked similarly.

So I made [FireBind](https://github.com/tyrsius/FireBind).

It adds two constructor's to the `ko` object. One for array's, which Firebase would call a set, and one for model's, which Firebase would call a location.

### FireModels

> `ko.fireModel(context, propertyMap, firebaseRef)`

`ko.fireModel` creates an object whose properties are all `computed` observables that intercept all writes. The writes are passed to the firebase api. It also has an internal handler for the `value` event for each property. Since local changes are sent through the Firebase api, local and remote writes are indistuingishable to the client. Luckily, Firebase implements latency compensation, so local writes will still appear instantly, and be reversed if Firebase rejects them.

The method add's the properties in the `propertyMap` object to the `context` object, using the values of the `propertyMap` as the default values. It is meant to be run on an object while inside of that object's constructor.

The firebase reference is the reference to the collection. If you've used Firebase you will know how to get this, but if not just take a look at the example fiddle at the end of the post.

### FireSets

> `ko.fireSet(firebaseRef, ChildConstructor, config)`

`ko.fireSet` returns an `observableArray` whose methods have all been replaced with ones that instead write to a Firebase set. It also adds handlers for the Firebase collection for the `child_added`, `child_removed` and `child_moved` events. These handlers will write to the underlying array. Just like the **FireModels**, all local writes are sent to the firebase api, and handlers take care of updating the underlying array.

The `ChildConstructor` is a constructor that will be used to create each child item inside the `child_added` handler. The constructor will be called with three parameters: the `id` (or "name", in firebase lingo) of the child, a `data` object representing the other values of the child, and the `firebaseRef` for the child.

The `config` object has two optional properties that control how the set works. `idProperty`, which defauls to `'id'`, tells the set which property on it's children should be used for the firebase location "name".

The `orderBy` property controls how the firebase priority will be set. If you leave it out, the priority will be set as an ascending integer. This will keep things ordered chronologically, but there isn't any transactional control at the moment. If you specify a property, that property of the child objects will be used to set the item priorirty. If you do this, the `reverse` and `move` will throw when you call them, since you cannot try to modify the order when it's set by the value of children's properties. `Sort` will no-op in this case.

#### A note on `splice`

The current version of Firebind (v0.5.1 at time of writing) does not suppor the `splice` method on firesets. If you need to move items inside the set, there is a `move` method, that takes the current index of the item you want to move, and the index you want to move it to, as arguments.

### Putting them together

[This JsFiddle](http://jsfiddle.net/tyrsius/eaeY5/) shows a simple example of both of these together, to form a recursively bound tree of Users (don't think to hard about a real use case here, it's a demo).

As you can see, **FireModels** are a little more complicated to construct that **FireSets**. One unfortunate consequence of FIrebase's implementation is that empty properties are not given to the client, so local model's must always list them out in the `propertyMap`, instead of just passing the `data` the constructor gets directly to `ko.fireModel`.

While writing this guide, I thought of several ways I could improve Firebind, and I think I will have some time after the holiday season to work on it. I want to simplify the api, and hopefully make it a little more flexible with the constructors.
