Raphael.fn.pieChart = function (cx, cy, r, values, labels, stroke) {
    var paper = this,
        rad = Math.PI / 180,
        chart = this.set();
    function sector(cx, cy, r, startAngle, endAngle, params) {
        var x1 = cx + r * Math.cos(-startAngle * rad),
            x2 = cx + r * Math.cos(-endAngle * rad),
            y1 = cy + r * Math.sin(-startAngle * rad),
            y2 = cy + r * Math.sin(-endAngle * rad);
        return paper.path(["M", cx, cy, "L", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
    }
    var angle = 0,
        total = 0,
        start = 0,
        process = function (j) {
            var value = values[j],
                angleplus = 360 * value / total,
                popangle = angle + (angleplus / 2),
                color = Raphael.hsb(start, .75, 1),
                ms = 500,
                delta = 30,
                bcolor = Raphael.hsb(start, 1, 1),
                p = sector(cx, cy, r, angle, angle + angleplus, {fill: "90-" + bcolor + "-" + color, stroke: stroke, "stroke-width": 3}),
                txt = paper.text(cx + (r + delta + 55) * Math.cos(-popangle * rad), cy + (r + delta + 25) * Math.sin(-popangle * rad), labels[j]).attr({fill: bcolor, stroke: "none", opacity: 0, "font-size": 20});
            p.mouseover(function () {
                p.stop().animate({transform: "s1.1 1.1 " + cx + " " + cy}, ms, "elastic");
                txt.stop().animate({opacity: 1}, ms, "elastic");
            }).mouseout(function () {
                p.stop().animate({transform: ""}, ms, "elastic");
                txt.stop().animate({opacity: 0}, ms);
            });
            angle += angleplus;
            chart.push(p);
            chart.push(txt);
            start += .1;
        };
    for (var i = 0, ii = values.length; i < ii; i++) {
        total += values[i];
    }
    for (i = 0; i < ii; i++) {
        process(i);
    }
    return chart;
};

OpenBlight = {
  common: {
    init: function() {
      // application-wide code
		  OpenBlight.common.show_disclaimer();
		  OpenBlight.common.handle_auto_complete_address();
    },
    
    handle_auto_complete_address: function(){      
  	  $('#main-search-field').keyup(function(key){
    		  var first_char = $(this).val().substr(0, 1);
		      // rationale explained in addresses_controller
    		  if(isNaN(first_char)){
    		      $("#main-search-field").autocomplete({
    		        source: "/streets/autocomplete_street_full_name"
    		      });
    		  }
    		  else{		  	
    		      $("#main-search-field").autocomplete({
    		        source: "/addresses/autocomplete_address_address_long"
    		      });			
    		  }		
  	    });	  
    },
    
    show_disclaimer: function(){
      $('#legal-disclaimer').modal('show');

      $('#legal-disclaimer .btn-primary').click(function(){
        $.cookie('agree_to_legal_disclaimer', true);			
      })
    }    
  },
  
  home: {
    init: function() {    
    }
  },
    
  statistics: {
    init: function(){
      console.log("SHOW ALL THE THINGS!");
    },
    graphs: function(){
      console.log(BlightStats.data)
      console.log("SHOW ALL THE GRAPHS!");
       var values = [10,20,30,40],
        labels = ["red","blue","green","purple"];
      
      Raphael("tag", 700, 700).pieChart(350, 350, 200, values, labels, "#fff");
    }
  },

  addresses: {
    init: function(){
    },
    search: function(){

      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',
        function(tilejson) {
          // this shoud be moved into a function
          var json_path = window.location.toString().replace(/search\?/i, 'search.json\?');

          jQuery.getJSON( json_path, function(data) {
            
            if(data.length){
            
              var map = new L.Map('map').addLayer(new wax.leaf.connector(tilejson));
              var popup = new L.Popup();

              var y = 29.95;
              var x = -90.05;
              var zoom = 12

              for ( i = 0; i < data.length; i++ ){
                var point = data[i].point.substring(7, data[i].point.length -1).split(' ');
                var y = point[1];
                var x= point[0];                				
                var popupContent = '<h3><a href="/addresses/'+ data[i].id +'">'+ data[i].address_long + '</a></h3><h4>'+ data[i].most_recent_status_preview.type + ' on ' + data[i].most_recent_status_preview.date + '</h4>' 
                map.addLayer(new L.Marker(new L.LatLng(point[1] , point[0])).bindPopup(popupContent));
        zoom = 14
              }
              // we center the map on the last position
              map.setView(new L.LatLng(y, x), zoom);
            }
          });
      });
    },
    show: function(){
      $(".property-status").popover({placement: 'bottom'});
		
      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',
        function(tilejson) {

          // this should not be hard coded. do json request?
        var x = $("#address").attr("data-x");
        var y = $("#address").attr("data-y");
        
        var map = new L.Map('map')
          .addLayer(new wax.leaf.connector(tilejson))
          .addLayer(new L.Marker(new L.LatLng(y , x)))
          .setView(new L.LatLng(y , x), 17);
      });
    }
  }
};

UTIL = {
  exec: function( controller, action ) {
    var ns = OpenBlight,
        action = ( action === undefined ) ? "init" : action;

    if ( controller !== "" && ns[controller] && typeof ns[controller][action] == "function" ) {ns[controller][action]();}
  },


  init: function() {
    var body = document.body,
        controller = body.getAttribute( "data-controller" ),
        action = body.getAttribute( "data-action" );

    UTIL.exec( "common" );
    UTIL.exec( controller );
    UTIL.exec( controller, action );
  }
};



$(document).ready( UTIL.init );
