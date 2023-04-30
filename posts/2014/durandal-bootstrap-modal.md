---
title: "Replacing the Durandal Modal with Boostrap's Modal"
pathname: "/durandal-bootstrap-modal"
publish_date: 2014-06-05
tags: ["twitter bootstrap", "bootstrap"]
---

Durandal 2.1 is now in pre-release. Despite claiming to have upgraded Bootstrap to 3.1 Durandal is still using a non-responsible, non-bootstrap based modal dialog. Thankfully, switching it out is pretty easy. Somewhere early in your startup process, just dump this code in. It will replace both the custom modal dialog host, as well as the Message Box on `app.showMessage`.

    dialog.addContext('bootstrap', {
        addHost: function (dialogInstance) {
            var body = $('body'),
            	host = $('<div class="modal fade"><div class="modal-dialog"><div class="modal-content"></div></div></div>');
            host.appendTo(body);
            dialogInstance.host = host.find('.modal-content').get(0);
            dialogInstance.modalHost = host;
        },
        removeHost: function (dialogInstance) {
        	$(dialogInstance.modalHost).modal('hide');
            $('body').removeClass('modal-open');
            $('.modal-backdrop').remove();
        },
        compositionComplete: function (child, parent, context) {
            var dialogInstance = dialog.getDialog(context.model),
                $child = $(child);
            $(dialogInstance.modalHost).modal({ backdrop: 'static', keyboard: false, show: true });
    
            //Setting a short timeout is need in IE8, otherwise we could do this straight away
            setTimeout(function () {
                $child.find('.autofocus').first().focus();
            }, 1);
    
            if ($child.hasClass('autoclose') || context.model.autoclose) {
                $(dialogInstance.blockout).click(function () {
                    dialogInstance.close();
                });
            }
        }
    });
    
    //rebind dialog.show to default to a new context
    var oldShow = dialog.show;
    dialog.show = function(obj, data, context) {
        return oldShow.call(dialog, obj, data, context || 'bootstrap');
    };
    
    
