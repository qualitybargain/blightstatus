OpenBlight.accounts = {
  init: function(){
  },

  map: function(){
    console.log('accounts map');
    

    var savePolygon = function (e){
      var features = new Array();

      if (L.Marker && (e.marker instanceof L.Marker)){
        var type = 'marker';
        var latlngs = e.marker._latlng;
      } else {
        if (L.Polygon && (e.poly instanceof L.Polygon)){
          var type = 'polygon';
        } else {
          var type = 'polyline';
        }
        var latlngs = new Array();
        $.each(e.poly._latlngs, function(i) {
          latlngs.push(e.poly._latlngs[i]);
        });
      }
      
      features.push({'type':type, 'latlngs':latlngs});

      jQuery.post( '/subscriptions', { polygon: features }, function(data) {
        console.log(data);
      }, 'json');


      // return features

      console.log(features);    
    };
    

    
    var loadPolygon = function (map){
      var features; //get ajax
      if (features){
        $.each(features, function(i, feature) {
          if (feature.type == 'marker'){
            var geometry = new L.Marker(feature.latlngs);
          } else {
            if (this._type == 'polygon' || 'rectangle'){
              var geometry = new L.Polygon([]);
            } else {
              var geometry = new L.Polyline([]);
            }
            $.each(feature.latlngs, function(i, latlng) {
              geometry.addLatLng(new L.LatLng(latlng.lat, latlng.lng));
            });
          }
          map.addLayer(geometry);
        });
      }
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
        
        map.on('drawend', function(e) {
          var popupContent = '<p>Hello world!<br />This is a nice popup.</p>',
              popup = new L.Popup();

          //popup.setContent(popupContent);
          savePolygon(e);
          //e.target.openPopup(popup);

        });
  

    });
  },
}