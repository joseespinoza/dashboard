//<!--
var m = [20, 170, 20, 170],
    w = 1580 - m[1] - m[3],
    h = 800 - m[0] - m[2],
    i = 0,
    root;

var tree = d3.layout.tree().size([h, w]);

//connects nodes using a diagonal line-projected with x and y coordinates
var diagonal = d3.svg.diagonal().projection(function(d) { return [d.y, d.x]; });

var vis = d3.select("body").append("svg:svg")
    .attr("width", w + m[1] + m[3])
    .attr("height", h + m[0] + m[2])
  .append("svg:g")
    .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

d3.json("modules/getjson.xqy", function(json) {
  root = json;
  root.x0 = h / 2;
  root.y0 = 0;

  function toggleAll(d) {
    if (d.children) {
      d.children.forEach(toggleAll);
      toggle(d);
    }
  }

  //Initialize the display to show a few nodes.
  root.children.forEach(toggleAll);

  update(root);
});


function update(source) {
  var duration = d3.event && d3.event.altKey ? 5000 : 500;

  // Compute the new tree layout.
  var nodes = tree.nodes(root).reverse();

  // Normalize for fixed-depth.
  nodes.forEach(function(d) { d.y = d.depth * 180; });

  // Update the nodes…
  var node = vis.selectAll("g.node")
      .data(nodes, function(d) { return d.id || (d.id = ++i); });



  // Enter any new nodes at the parent's previous position.
  var nodeEnter = node.enter().append("svg:g")
      .attr("class", "node")
      .attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; })
      .on("click", function(d) { toggle(d); update(d); });



///////////TOOLTIP/////////////////////////////

//creates div element to hold tooltip
d3.select("body").append("div").attr("id","tooltip").attr("class","hidden").append("p").attr("id","value");


//event listeners for tooltip
vis.selectAll("g.node").on("mouseover", function(){
	
	//gets coordinates for the tooltip
	var xPosition = d3.event.pageX;
	var yPosition = d3.event.pageY;
	
	//creates url for HTTP request
	var name = d3.select(this).select("text").html();
	var type = d3.select(this).select("text").attr("type");
	var url = "/modules/getproperties.xqy?nodename=" + name + "&type=" + type;

	d3.select("#tooltip")
  		.style("left", xPosition + "px")
  		.style("top", yPosition + "px")
  		.select("#value")

	//sends a HTTP request to getproperties.xml, sends the header(nodename=<name of node>&type=<type of node>)
	d3.xhr(url, function(data){return d3.select("#tooltip").select("#value").html(data.response);});
		
	d3.select("#tooltip").classed("hidden", false);
	
      });
nodeEnter.on("mouseout", function(){

	d3.select("#tooltip").classed("hidden", true);
});



  nodeEnter.append("svg:circle")
      .attr("r", 1e-6)
      .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

  nodeEnter.append("svg:text")
      .attr("x", function(d) { return d.children || d._children ? -10 : 10; })
      .attr("dy", ".35em")
      .attr("text-anchor", function(d) { return d.children || d._children ? "end" : "start"; })
      .attr("type",function(d){return d.type.trim();})//trims off whitespace
      .text(function(d) { return d.name.trim(); })//trims off whitespace
      .style("fill-opacity", 1e-6);



  // Transition nodes to their new position.
  var nodeUpdate = node.transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; });

  nodeUpdate.select("circle")
      .attr("r", 4.5)
      .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

  nodeUpdate.select("text")
      .style("fill-opacity", 1);

  // Transition exiting nodes to the parent's new position.
  var nodeExit = node.exit().transition()
      .duration(duration)
      .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
      .remove();

  nodeExit.select("circle")
      .attr("r", 1e-6);

  nodeExit.select("text")
      .style("fill-opacity", 1e-6);

  // Update the links…
  var link = vis.selectAll("path.link")
      .data(tree.links(nodes), function(d) { return d.target.id; });

  // Enter any new links at the parent's previous position.
  link.enter().insert("svg:path", "g")
      .attr("class", "link")
      .attr("d", function(d) {
        var o = {x: source.x0, y: source.y0};
        return diagonal({source: o, target: o});
      })
    .transition()
      .duration(duration)
      .attr("d", diagonal);

  // Transition links to their new position.
  link.transition()
      .duration(duration)
      .attr("d", diagonal);

  // Transition exiting nodes to the parent's new position.
  link.exit().transition()
      .duration(duration)
      .attr("d", function(d) {
        var o = {x: source.x, y: source.y};
        return diagonal({source: o, target: o});
      })
      .remove();

  // Stash the old positions for transition.
  nodes.forEach(function(d) {
    d.x0 = d.x;
    d.y0 = d.y;
  });
}

// Toggle children.
function toggle(d) {
  if (d.children) {
    d._children = d.children;
    d.children = null;
  } else {
    d.children = d._children;
    d._children = null;
  }
}

//-->