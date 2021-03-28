---
title: "Durandal Grid"
url: "/durandal-grid"
date: "2014-01-09"
lastmod: "2014-06-20"
tags: ["durandal", "widgets", "durandal-grid"]
---

I've used [KoGrid](http://knockout-contrib.github.io/KoGrid/#/overview) before, but I was never happy with the syntax for writing templates. You have to define your HTML as strings inside your Javascript. Yuck.

Durandal has an excellent system for managing HTML chunks with it's [Widget system](http://durandaljs.com/documentation/Creating-A-Widget/). You can allow for overriding of HTML *inside* the HTML, not your javascript. It keeps things cleanly seperated. So, of course, a Durandal grid widget was just a matter of time.

I actually made the original version of this way back in August of last year, but it just sat 90% done until about last week. It had a few bugs in it, and I had to create documentation, but it's finally done! I present [Durandal-Grid](http://durandalgrid.tyrsius.com/) ([source](https://github.com/tyrsius/durandal-grid)).

I am very happy with the syntax that results from using Durandal here.

### HTML Examples

**Simple**

```html
<table class="paging-container grid-table" data-bind="grid: gridConfig"></table>
```

**Custom Rows**

```html
<table class="" data-bind="grid: gridConfig">
    <tbody data-part="body" data-bind="foreach: { data: currentPageRows, as: 'row' }">
        <tr>
            <td data-bind="text: firstName"></td>
            <td data-bind="text: lastName"></td>
            <td data-bind="text: age"></td>
            <td><button class="btn btn-xs btn-danger" data-bind="click: $root.removeRow">Remove</button></td>
        </tr>
    </tbody>
</table>
```

### Javascript Examples

**Data-only**

```js
    gridConfig: { data: data }
```

**With Options**

```js
return {
    gridConfig: { 
        data: data,
        pageSize: 5,
        showPageSizeOptions: true,
        pageSizeOptions: [5, 10, 15],
        columns: [
            { header: 'First Name', property: 'firstName' },
            { header: 'Last Name', property: 'lastName' },
            { header: 'Age', property: 'age', canSort: true, 
                sort: function(a,b) { 
                        return a.age < b.age ? -1 : 1; 
                    } 
            },
            { header: 'Number', property: 'slot'}
        ]
    }
};
```
