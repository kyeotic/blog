---
title: "Hot Reloading redux in jspm 0.17"
pathname: "/hot-reload-in-jspm-0-17"
publish_date: 2016-03-15
tags: ["jspm", "redux"]
---

I struggled quite a bit with this one, because understanding the components of hot reloading was very difficult. There are a lot of explanations out there that are light on details, or just downright wrong.

I read Dan Abramov's [recent post on Hot Reloading](https://medium.com/@dan_abramov/hot-reloading-in-react-1140438583bf#.jskstejhr). In it, he suggests trying the local storage approach. I tried [Redux LocalStorage](https://github.com/elgerlambert/redux-localstorage), but it has an issue when, hilariously, it has to [use its own merge](https://github.com/elgerlambert/redux-localstorage/issues/14). They say its fixed in 1.0, but its in release-candidate status, and has been for some time. I didn't trust it.

I should have taken Dan's advice from the very next paragraph, because using the hot reload api is much simpler.

The [hot reload section](http://jspm.io/0.17-beta-guide/hot-reloading.html) of the new jspm beta guide shows you how to setup the incredibly simple `__reload` hook. This is great for simple React application that use component state, but doesn't work for Flux/Redux implementations that store state outside of the components.

To get this working with redux, you need two pieces.

First, you need to be able to hydrate your store. Dan provided the code for this in [this github issue](https://github.com/reactjs/redux/pull/658).

    const HYDRATE_STATE = 'HYDRATE_STATE'
    
    export const store = createStore(
        makeHydratable(reducer, HYDRATE_STATE),
        initialState,
    )
    
    function makeHydratable(reducer, hydrateActionType) {
      return function (state, action) {
        switch (action.type) {
        case hydrateActionType:
          return reducer(action.state, action);
        default:
          return reducer(state, action);
        } 
      }
    }
    

The second piece is the `__reload` that calls this.

    export function __reload(m) {
    	if (m.store.dispatch) {
    		store.dispatch({
    			type: HYDRATE_STATE,
    			state: m.store.getState()
    		})
    	}
    }
    

I have these split into two different modules, since I like to keep my store configuration out of `main.js`. I don't know how you need to organize your code, but the important part is that the `main.js` module exports `store`, so that it is available to the `__reload` hook. Remember, the `m` argument to the `__reload` hook is the ***previous module***. The scope of the `__reload` hook is the ***current/new module***/
