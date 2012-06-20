OpenBlight.accounts = {
  init: function(){
  },

  map: function(){
    console.log('accounts map');
    wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
	    var y = 29.95;
	    var x = -90.08;
	    var zoom = 14

      map = new L.Map('map')
        .addLayer(new wax.leaf.connector(tilejson))
        .setView(new L.LatLng(y , x), zoom);

      drawControl = new L.Control.Draw();
      map.addControl(drawControl);
      map.draw.enable();      
      map.on('drawend', function(e) {
        console.log('drawend');
        console.log(e);
        //jQuery.post()
      });

    });
  },
}