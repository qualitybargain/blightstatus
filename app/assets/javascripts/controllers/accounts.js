OpenBlight.accounts = {
  init: function(){
  },

  index: function(){
    OpenBlight.addresses.mapAddresses();
    OpenBlight.accounts.subscriptionButton()
    OpenBlight.accounts.account_page = true;  

  },


  subscriptionButton: function(){
    $(".subscribe-button").bind("ajax:success",
       function(evt, data, status, xhr){
        if($(this).data('method') == 'delete'){
          
          if(OpenBlight.accounts.account_page){
            $(this).parentsUntil('.subscription').parent().fadeOut('slow');
          }
          else{
            $(this).html('Receive Alerts');
            $(this).data('method', 'put')           
          }
        }
        else{
          $(this).html('Unsubscribe');
          $(this).data('method', 'delete')
        }
      }).bind("ajax:error", function(evt, data, status, xhr){
        //do something with the error here
        console.log(data);
        // $("div#errors p").text(data);
    });
  },


  map: function(){
    var savePolygon = function (e){
      console.log(e);
      var latlngs = new Array();

      $.each(e.poly._latlngs, function(i, item) {        
          latlngs[i] = { lat : item.lat, lng : item.lng };
      });

      jQuery.post( '/subscriptions', { polygon: latlngs }, function(data) {
        console.log(data);
      }, 'json');
    };
    
    var loadPolygon = function (map){
      $.getJSON('/accounts/map.json', function(geojsonFeature) {
        var geojsonLayer = new L.GeoJSON();
        geojsonLayer.addGeoJSON(geojsonFeature);
        map.addLayer(geojsonLayer);
      });
    };    

    wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
	    var y = 29.95;
	    var x = -90.08;
	    var zoom = 14

      map = new L.Map('map')
        .addLayer(new wax.leaf.connector(tilejson))
        .setView(new L.LatLng(y , x), zoom);

        drawControl = new L.Control.Draw({
          position: 'topleft',
          drawMarker: false,
          drawPolyline: false,
          drawPolygon: true,
          drawRectangle: false
        });

        map.addControl(drawControl);
        
        loadPolygon(map);

        map.on('drawend', function(e) {
          //popup.setContent(popupContent);
          savePolygon(e);
          //e.target.openPopup(popup);
        });
    });
  },
}