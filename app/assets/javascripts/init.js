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
      if($.cookie('agree_to_legal_disclaimer') != 'true' && $.cookie('agree_to_legal_disclaimer') != true){
        $('#legal-disclaimer').modal('show');
      } else {
        $('#legal-disclaimer').modal('hide');
      }
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

    },
    graphs: function(){
      //var stats = BlightStats.data;
      //jQuery.each(obj, function(key, val) {
        //$("#" + i).append(document.createTextNode(" - " + val));
      //});

      //var results = BlightStats.data.judgements.result;
      //$.each(results, function(key, value) {
      //  Console.log(key + ' => ' + value);
      //});
      var i;
      var keys = []
      var values = [];
      //var values = [];
      var graph = function(id, data,title){
        i = 0;
        keys =[];
        values = [];
        $.each(data, function(key, value) {
          
          if(key === "")
            key = "undeclared";// : key;
          keys[i] = key + " - " + value + " (%%.%%)";
          values[i] = value;
          i++;
        });
        
        var r = Raphael(id), pie = r.piechart(320, 240, 100, values, { legend: keys, legendpos: "east", href: [".", "."]});

                r.text(320, 100, title).attr({ font: "20px sans-serif" });
                pie.hover(function () {
                    this.sector.stop();
                    this.sector.scale(1.1, 1.1, this.cx, this.cy);

                    if (this.label) {
                        this.label[0].stop();
                        this.label[0].attr({ r: 7.5 });
                        this.label[1].attr({ "font-weight": 800 });
                    }
                }, function () {
                    this.sector.animate({ transform: 's1 1 ' + this.cx + ' ' + this.cy }, 500, "bounce");

                    if (this.label) {
                        this.label[0].animate({ r: 5 }, 500, "bounce");
                        this.label[1].attr({ "font-weight": 400 });
                    }
                });

      }
      console.log("SHOW ALL THE GRAPHS!");
      console.log(BlightStats.data);
      
      graph("inspection_types",BlightStats.data.inspections.types,"Inspection by Type");
      graph("inspection_results",BlightStats.data.inspections.results,"Inspection Results");
      graph("hearing_status",BlightStats.data.hearings.status,"Hearing Status");
      graph("judgement_status",BlightStats.data.judgements.status,"Judgement Status");
      graph("maintenance_programs",BlightStats.data.maintenances.program_names,"Maintenance by Program");
      
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
