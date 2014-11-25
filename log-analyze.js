/*
 * Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 *
 * log-analyze.js
 *
 */

$(document).ready(function() {

        var title = $("body > h1");
        if (!title.length) {
            alert("title is null");
            return;
        }

        var wrapper = title.next("div");
        if (!wrapper.length) {
            alert("wrapper is null");
            return;
        }

        // enrich contents with anchors and build toc
        var i = 0;
        var toc = $('<ol id="toc"/>');
        var id;
        var h;
        wrapper.find("h2").each(function() {
                id = "h2." + i;
                h = $(this);
                h.before($("<a/>").attr("id", id));
                toc.append($("<li>")
                           .append($("<a>")
                                   .attr("href", "#" + id)
                                   .text(h.text())));
                i++;
            });

        // update the page
        title.after(toc);
    });

/* log-analyze.js */
