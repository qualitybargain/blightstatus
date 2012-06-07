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

    }
  },

  addresses: {
    init: function(){
      OpenBlight.addresses.setup_observers();
    },

    setup_observers: function(){

      OpenBlight.addresses.subscribe_button();

    },

    subscribe_button: function(){

      jQuery(".subscribe-button").click(function(){
        var that = this;
        jQuery.post( '/subscriptions', { id: $('#address').attr('internal_address_id') }, function(data) {
          jQuery(that).html('Thank You');
        }, 'json');
      });   

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
		  OpenBlight.addresses.init_address_map();
      
      $(".property-status").popover({placement: 'bottom'});
      
    },

    
    init_address_map: function(){

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
