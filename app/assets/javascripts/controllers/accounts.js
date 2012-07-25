OpenBlight.accounts = {
  init: function(){
  },

  map: function(){
    console.log('accounts map');
    

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