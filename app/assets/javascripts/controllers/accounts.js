OpenBlight.accounts = {
  init: function(){
    OpenBlight.accounts.layergroup = {};
    OpenBlight.accounts.map = {};
    OpenBlight.accounts.markers = [];
  },

  /**
   * Controller method
   */
  index: function(){
    OpenBlight.accounts.account_page = true;  

    
    OpenBlight.accounts.subscriptionButton()
    OpenBlight.accounts.createAccountsMap();




  },


  /**
   * Controller method
   */
  map: function(){
    OpenBlight.accounts.createSubscriptionMap();
  },





  /**
   * Local methods
   */
  subscriptionButton: function(){
    $(".subscribe-button").bind("ajax:success",
       function(evt, data, status, xhr){
        if($(this).data('method') == 'delete'){
          
          if(OpenBlight.accounts.account_page){
            $(this).parentsUntil('.subscription').parent().fadeOut('slow');
          }
          else{
            $(this).html('Add Watchlist');
            $(this).data('method', 'put')           
          }
        }
        else{
          $(this).html('Remove Watchlist');
          $(this).data('method', 'delete')
        }
      }).bind("ajax:error", function(evt, data, status, xhr){
        //do something with the error here
        console.log(data);
        // $("div#errors p").text(data);
    });
  },


  createSubscriptionMap: function(){
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
        

        OpenBlight.accounts.loadPolygon(map);

        

        map.on('drawend', function(e) {
          //popup.setContent(popupContent);
          OpenBlight.accounts.savePolygon(e);
          //e.target.openPopup(popup);
        });
    });
  },


  createAccountsMap: function(){


    var ready = wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
      var y = 29.96;
      var x = -90.08;
      var zoom = 13;

      OpenBlight.accounts.map = new L.Map('map', {
        touchZoom: false,
        scrollWheelZoom: false,
        boxZoom: false
      });

      OpenBlight.accounts.map.addLayer(new wax.leaf.connector(tilejson))
      OpenBlight.accounts.map.setView(new L.LatLng(y , x), zoom);

      var json_path = '/accounts.json'
      OpenBlight.accounts.populateMap(json_path);

    });

  },



  populateMap: function(json_path){

    jQuery.getJSON(json_path, {}, function(data) {
      OpenBlight.accounts.markers = [];

      var features = [];
      var icon = OpenBlight.addresses.getCustomIcon();

      for(i = 0; i < data.length -1; i++){
        features.push(data[i].point);
      }

      L.geoJson(features, {
        pointToLayer: function (feature, latlng) {
          OpenBlight.accounts.markers.push( latlng );          
          return L.marker(latlng, {icon: new icon() });
        }
      }).addTo(OpenBlight.accounts.map);


      OpenBlight.accounts.map.fitBounds(OpenBlight.accounts.markers);

    });

  },




  savePolygon: function (e){
    console.log(e);
    var latlngs = new Array();

    $.each(e.poly._latlngs, function(i, item) {        
        latlngs[i] = { lat : item.lat, lng : item.lng };
    });

    jQuery.post( '/subscriptions', { polygon: latlngs }, function(data) {
      console.log(data);
    }, 'json');
  },
  
  loadPolygon: function (map){
    $.getJSON('/accounts/map.json', function(geojsonFeature) {
      var geojsonLayer = new L.GeoJSON();
      geojsonLayer.addGeoJSON(geojsonFeature);
      map.addLayer(geojsonLayer);
    });
  }
}