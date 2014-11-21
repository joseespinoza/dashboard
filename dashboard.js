/*
 * Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 *
 * dashboard.js
 *
 */

var kDashboardId = '#dashboard-main';
var kParametersId = '#dashboard-parameters';
var kRefreshId = '#refresh';
var kTimestampId = '#timestamp';
var kSampleCountId = '#sample-count';
var labelPattern = /^([\w\-\.\:]+)::([\w\-\.]+)$/;

var message = null;
var parent = null;
var timer = null;
var parameters = null;
var spinner = null;

var tzOffset = new Date().getTimezoneOffset();

function scheduleNextUpdate(ts) {
    // 10-minute reload
    var now = new Date();
    var interval = 600 * 1000;

    // adjust to a few seconds after the next expected sample
    // eg 600 - 300 = 300, so correct by 295
    // so 600 - 295 = 305, so sleep 305
    var correction = ts ? (now - ts) - 5000 : 0;
    interval = (interval - correction > 5000)
        ? (interval - correction)
        : interval;

    timer = window.setTimeout(update, interval);
    // update the next reload text
    $(kRefreshId).text(new Date(now.valueOf() + interval)
                       .toLocaleString());
    // update the as-of text
    $(kTimestampId).text(ts ? ts.toLocaleString() : now.toLocaleString());

    // hide the spinner
    if (spinner && spinner.length) {
        spinner.fadeOut(32);
    }
}

function dataReceived(newData) {
    if (timer) {
        window.clearTimeout(timer);
    }

    // repaint based on new JSON data from ajax call
    // the newData should be an array of labelled series
    // must handle several series at once
    message.text('Received ' + newData.length);
    if (0 == newData.length) {
        message.text("No samples to display");
        scheduleNextUpdate();
        return;
    }

    // update sample count
    var size = newData[0].data.length;
    // needs string concatenation...
    $(kSampleCountId).text("" + size);

    // update timestamp from last sample
    var now = new Date();
    // update global offset, in case it has changed
    tzOffset = new Date().getTimezoneOffset();
    var ts = new Date(newData[0].data[size - 1][0]
                      + (60 * 1000 * tzOffset));

    // parcel out the data and plot it
    var plot;
    var data = {};
    newData.map(function(o, i) {
            message.text(i + " => " + o);
            plot = o.label.replace(labelPattern, "$2");
            o.label = o.label.replace(labelPattern, "$1");
            message.text("plot=" + plot + ", label=" + o.label);
            if (!(plot && o.label)) {
                alert('ASSERT: missing plot or label!');
                return;
            }
            if (!data[plot]) {
                data[plot] = [];
            }
            data[plot].push(o);
        });

    var n;
    for (var k in data) {
        var options = { xaxis: { mode: "time" },
                        yaxis: { min: 0 },
                        grid: { hoverable: true, clickable: true },
                        points: { show: true },
                        lines: { show: true },
                        legend: { show: false } };
        message.text(k + " => " + data[k]);
        n = $("#" + k);
        message.text(k + " => n=" + n.length);
        if (! n.length) {
            message.text("creating " + k);
            n = $("<div/>");
            n.append("<h2>" + k + "</h2>");
            n.append("<div class=\"time-plot\" id=\"" + k + "\" />");
            parent.append(n);
            n = $("#" + k);
        }
        $.plot(n, data[k], options);

        // add some hovering logic to each point...
        var previousPoint = null;
        n.bind("plothover", function (event, pos, item) {
                $("#x").text(pos.x.toFixed(2));
                $("#y").text(pos.y.toFixed(2));

                if (item) {
                    if (previousPoint != item.datapoint) {
                        previousPoint = item.datapoint;
                        $("#tooltip").remove();
                        var x = item.datapoint[0] + (60 * 1000 * tzOffset);
                        var y = item.datapoint[1].toFixed(2);
                        showTooltip(item.pageX, item.pageY,
                                    item.series.label
                                    + " = " + y
                                    + " at " + new Date(x).toLocaleString());
                    }
                }
                else {
                    $("#tooltip").remove();
                    previousPoint = null;
                }
            });

        // show the tooltip
        // TODO better edge handling for east side
        function showTooltip(x, y, contents) {
            $('<div id="tooltip" class="tooltip">'
              + contents + '</div>').css( {
                      top: y - 35,
                          left: x + 5,
                          }).appendTo("body").fadeIn(200);
        }
    };

    scheduleNextUpdate(ts);
    message.empty();
}

function update(event) {
    // if this was an uncheck of a checkbox, handle it locally
    if (event) {
        var target = $(event.target);
        if (target.is("input:checkbox") && !target.is("input:checked")) {
            // remove existing plot
            $("#" + target.attr("value") + ":.time-plot").parent().remove();
            return true;
        }
    }

    if (timer) {
        window.clearTimeout(timer);
    }

    if (spinner && spinner.length) {
        spinner.fadeIn(32);
    }

    // parameterize with duration, tags, filters
    var serviceUrl = 'data-service.xqy?' + parameters.serialize();
    message.text(serviceUrl);
    $.ajax({
            url: serviceUrl,
                method: 'GET',
                dataType: 'json',
                success: dataReceived,
                error:
            function(req, status, thrown) {
                message.text(status);
                message.append(req.responseText);
            }
        });
}

function selectAll(event) {
    var off = $(event.target).parent().find("input:checkbox:not(:checked)");
    if (0 == off.length) {
      return false;
    }
    // this seems to be buggy
    //off.attr('checked', 'checked');
    // so we do it the old-fashioned way
    off.each(function() { this.checked = true; });
    update(event);
    return false;
}

function selectNone(event) {
    var on = $(event.target).parent().find("input:checkbox:checked");
    // this seems to be buggy
    //on.removeAttr('checked');
    // so we do it the old-fashioned way
    on.each(function() { this.checked = false; });
    // remove all existing plots
    $(".time-plot").parent().remove();
    return false;
}

$(document).ready(function() {
        parent = $(kDashboardId);

        if (!parent) {
            return;
        }

        message = $('#message');
        message.text("Loading data...");

        spinner = $("#dashboard-spinner");

        // set up event handlers
        parameters = $(kParametersId);
        parameters.change(update);
        $(".select-all").click(selectAll);
        $(".select-none").click(selectNone);

        update();
    });

// TODO - non-ajax mode, data comes from dictionary node - for support

/* dashboard.js */
