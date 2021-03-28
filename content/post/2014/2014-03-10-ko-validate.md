---
title: "Validation in Knockout"
url: "/ko-validate"
date: "2014-03-10"
lastmod: "2014-05-02"
tags: ["knockout", "validation"]
---

There is already a library for doing validation in Knockout, aply named [Knockout-Validation](https://github.com/Knockout-Contrib/Knockout-Validation). I don't really remember what issues I ran into when I used it so long ago, but I remember giving up on it. It also doesn't appear to [play well with RequireJS](http://stackoverflow.com/questions/18033268/configuring-knockout-validation-in-durandal-spa-application), which is critical if you work in Durandal as I do.

It's syntax isn't that bad, but I think it gets a bit verbose for multiple validations-per-value. I built my own validation extender/binding-handler pair for Knockout that I use, and it doesn't have any issue with RequireJs.

It consists of an extender and a binding handler.

### The binding handler

    <input type="text" data-bind="validate: title" />
    

`validate` wraps the standard `value` binding, and sets the `isModified` sub-observable on the extended observable. This stops errors from showing before the element has been ineteracted with.

### The extender

Like ko-validation I use an extender, but unlike ko-validation I use just one: `isValid`. It add's four sub-observables to the extended observable:

1. `isValid()` - boolean indicating the validity.
2. `isModified()` - boolean indicating whether the value has been touched. It is set to true by the  `validate` binding handler
3. `showError()` - boolean indicating whether the error message should be shown. It is `!isValid() && isModified()`.
4. `errorMessage()` - the error message to display.

It supports several syntaxes, ranging from "bare-minimum" to "totally customized."

#### Just Required

    this.title = ko.observable().extend({ isValid: true});
    

This will use the default validation method, `value !== undefined && value !== null && (value.length === undefined || value.length > 0)`, and uses the default message `Invalid Value`.

#### Custom message

    this.title = ko.observable().extend({ isValid: { message: 'Error' } });
    

Will use the default validation method, and show the specified error.

#### Standard options

    this.title = ko.observable().extend({ isValid: { validate: { min: 2}, message: 'must be at least 2' });
    

Passing an object to `validate` will create a validation function based on some standard properties. Currently, it supports the following options:

- `min` and `max`. Will check these values *as numbers*.
- `minLength` and `maxLength` will check these values *as strings*.
- `options` will check values against this *array*. Any value in the array is valid.

All of these can also be primitive or observable values. `validate` and `messsage` can (and probably should) both be passed to the extender.

#### Custom validation

    this.title = ko.observable().extend({ isValid: { validate: function (value) { return value !== undefined && value instanceof Array; });
    

If you pass a function to `validate` it will be used to test the validity of the observable. The function will recieve any value written, and the value will be invalid if the function returns `false`. If the custom function accesses any observables, it will establish a dependency and re-run when those observables change (just like a `computed`).

#### Multiple validations

    self.payLow = ko.observable(data.payLow || 0).extend({
        numeric: { precision: 2, min: 0, max: payMax },
        isValid: [
            {
                validate: { min: 1 },
                message: 'Required'
            },
            {
                validate: { max: payMax },
                message: ko.computed(function() { 
                    return 'Must be at most $' + payMax(); 
                })
            }
        ]
    });
    

The extender can also take an array of validation objects, each of which will be used to determine validity. The `errorMessage` sub-observable will be set to the message of the first failing specification only.

### That's it

From this, you should be able to create any kind of validation you need. Let me know what you think. The source is located [on Github](https://github.com/tyrsius/ko-validate/tree/master).

This code was developed at work, and is being open sourced because I have an awesome manager. Thanks Ken!
