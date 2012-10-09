OpenBlight.accounts = {
  init: function(){
    OpenBlight.accounts.layergroup = {};
    OpenBlight.accounts.map = {};
    OpenBlight.accounts.markers = [];
  },

  /**
   * Controller methods
   */
  index: function(){
    OpenBlight.accounts.account_page = true;
    OpenBlight.accounts.subscriptionButton()
    OpenBlight.accounts.createAccountsMap();
    OpenBlight.accounts.bindDeliveryToggle();
    OpenBlight.accounts.showAccountGuide();

  },

  map: function(){
    OpenBlight.accounts.createSubscriptionMap();
  },

  /**
   * Local methods
   */

  bindDeliveryToggle: function(){
    $("input#account_send_notifications").click(function(e){
      data = $(this).parent('form').serialize();
      $.post("/accounts/notify", data, function(data){
        if(data.saved == false){
          //do something if it fails
        }
      });
    });
  },

  showAccountGuide: function(){

    if($('#no-subscriptions-found').length){

      if($('.subscription').length > 0){
        console.log('is 0')
        $('#no-subscriptions-found').hide();
        $('#subscriptions-information').show();
      }
      else{
        console.log('is greater 0');
        $('#no-subscriptions-found').show();
        $('#subscriptions-information').hide();
      }

    }

  },


  subscriptionButton: function(){
    $(".subscribe-button").bind("ajax:success",
       function(evt, data, status, xhr){

        if($(this).data('method') == 'delete'){
          if(OpenBlight.accounts.account_page){
            $(this).parentsUntil('.subscription').parent().fadeOut('slow');
            // $(this).parentsUntil('.subscription').parent().remove();
          }
          else{
            $(this).html('Add to Watchlist');
            $(this).data('method', 'put');

          }
        }
        else{
          $(this).html('Watching');
          $(this).data('method', 'delete')
        }

        OpenBlight.accounts.showAccountGuide();

      }).bind("ajax:error", function(evt, data, status, xhr){
        //do something with the error here
        // console.log(data);
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
      var icon = OpenBlight.addresses.getCustomIcon('dotmarker');

      for(i = 0; i < data.length; i++){
        features.push(data[i].point);
      }

      var current_feature_id = 0;
      L.geoJson(features, {
        pointToLayer: function (feature, latlng) {
          OpenBlight.accounts.markers.push( latlng );          
          return L.marker(latlng, {icon: new icon() });
        },

        onEachFeature: function(feature, layer) {
           $(layer).on('click', function(){

            console.log(data[current_feature_id].id);
            var select_subcription = "subscription-" + data[current_feature_id].id;
            OpenBlight.common.goToByScroll(select_subcription, 'slow', '150');
            current_feature_id = current_feature_id +1;

            console.log(select_subcription);
            $('#' + select_subcription).animate({ backgroundColor: "#FFFFE0" }, 'slow').animate({ backgroundColor: "white" }, 'fast');
          });
        }

      }).addTo(OpenBlight.accounts.map);

      OpenBlight.accounts.map.fitBounds(OpenBlight.accounts.markers);
    });
  },

  savePolygon: function (e){
    // console.log(e);
    var latlngs = new Array();

    $.each(e.poly._latlngs, function(i, item) {        
        latlngs[i] = { lat : item.lat, lng : item.lng };
    });

    jQuery.post( '/subscriptions', { polygon: latlngs }, function(data) {
      // console.log(data);
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
