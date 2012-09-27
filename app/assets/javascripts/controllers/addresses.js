OpenBlight.addresses = {
  init: function(){
    OpenBlight.addresses.layergroup = {};
    OpenBlight.addresses.map = {};
    OpenBlight.addresses.markers = [];
  },

  search: function(){
    var json_path = window.location.toString().replace(/search\?/i, 'search.json\?');

    OpenBlight.addresses.createSearchResultsMap();
    OpenBlight.addresses.populateMap(json_path, {},  function(){
      OpenBlight.addresses.fitPointersOnMap();
    });
  },

  show: function(){
    $(".property-status").popover({placement: 'bottom'});

<<<<<<< HEAD
    OpenBlight.addresses.highlightCaseHistory();
    OpenBlight.addresses.mapAddresses();
    OpenBlight.accounts.subscriptionButton();
  },


  /**
   * Local methods
   */
  createSearchResultsMap: function(){
    wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
      var y = 29.96;
      var x = -90.08;

      OpenBlight.addresses.map = new L.Map('map', {
        touchZoom: false,
        scrollWheelZoom: false,
        boxZoom: false,
        minZoom: 13
      });

      OpenBlight.addresses.map.addLayer(new wax.leaf.connector(tilejson))
      OpenBlight.addresses.map.setView(new L.LatLng(y , x));

      OpenBlight.addresses.map.on('dragend', function(e){
        if($('#map-search-mode').attr('checked')){
          OpenBlight.addresses.mapSearchByBounds();
=======
      var x, y, map, CustomIcon, dotIcon;

        // this should not be hard coded. do json request?
      x = $("#address").attr("data-x");
      y = $("#address").attr("data-y");

      CustomIcon = L.DivIcon.extend({
        options: {
          iconSize: [ 22, 37 ],
          iconAnchor: [ 0, 0 ],
          popupAnchor: [ 11, 0 ],
          className: "dotmarker"
>>>>>>> ea08a42a78036a24d7693a45b610fab418b130c7
        }
      });
    });
  },


  populateMap: function(json_path, params, callbacks){
    jQuery.getJSON(json_path, params, function(data) {
      OpenBlight.addresses.markers = [];

      var features = [];
      for(i = 0; i < data.length -1; i++){
        features.push(data[i].point);
      }

      var $ul = $('.search-results ul.nav');
      $ul.html('');

      var current_feature = 0;
      var icon = OpenBlight.addresses.getCustomIcon();

<<<<<<< HEAD
      OpenBlight.addresses.layergroup = L.geoJson(features, {
        pointToLayer: function (feature, latlng) {
          return L.marker(latlng, {icon: new icon() });
        },
=======
      map = new L.Map('map')
        .addLayer(new L.TileLayer.WMS("http://http://gis.nola.gov/ArcGIS/rest/services/basemapcache_wgs/MapServer",{
          layers: '0,1,2,3,4',
          format: 'image/png'
        }))
        .addLayer(new L.Marker(new L.LatLng(y , x), {icon: dotIcon} ))
        .setView(new L.LatLng(y , x), 17);
>>>>>>> ea08a42a78036a24d7693a45b610fab418b130c7

        onEachFeature: function(feature, layer) {
          var point = feature.coordinates;
          var y = point[1], x= point[0];
          var link = '/addresses/'+ data[current_feature].id;
          var popupContent = '<h3><a href="' + link + '">' + data[current_feature].address_long + '</a></h3>' + 
          '<img src="http://maps.googleapis.com/maps/api/streetview?location='+y+','+x+'&size=200x100&sensor=false" >';
          '<p>'+ data[current_feature].most_recent_status_preview.type + ' on ' + data[current_feature].most_recent_status_preview.date + '</p>';
          layer.id = data[current_feature].id;
          OpenBlight.addresses.markers.push( layer );

          var pos = current_feature+1;
          li = '<li class="address result '+ ((pos > 9) ? " two-digits": "") + ((pos > 99) ? " three-digits": "") +'" data-id="'+ data[current_feature].id +'"> <span class="maps-marker">'+pos+'</span><span class="search-address"><a href="/addresses/'+ data[current_feature].id +'">'+ data[current_feature].address_long +'</a></span></li>';
          $('.search-results ul.list').append(li);

          layer.on('dblclick', function(){ window.location.href = link });
          layer.on('click', function(){ 
            OpenBlight.addresses.map.panTo( this.getLatLng() );
            L.popup().setLatLng(layer.getLatLng()).setContent(popupContent).openOn(OpenBlight.addresses.map);
          });
          current_feature = current_feature + 1;
        }
      }).addTo(OpenBlight.addresses.map);

<<<<<<< HEAD
      $('ul.nav').removeClass('loading');
      $('#loading').hide();
      if (typeof callbacks  === 'function') {
        callbacks();
      }
      OpenBlight.addresses.associateMarkers();
    });
=======
>>>>>>> ea08a42a78036a24d7693a45b610fab418b130c7
  },

  highlightCaseHistory: function(){
    $(".progress-arrow").hover(function(){
      // console.log('.case-history-' + $(this).attr('class').split(' ')[1]);
      $('.case-history-' + $(this).attr('class').split(' ')[1]).css('background-color', '#eee')
    }, function(){
      $('.case-history-' + $(this).attr('class').split(' ')[1]).css('background-color', 'transparent')
    })
  },

  mapAddresses: function(){
    $(".map-address").each(function(index, address){
      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
        var x, y, map;
        var icon = OpenBlight.addresses.getCustomIcon();

        x = $(address).attr("data-x");
        y = $(address).attr("data-y");

        map = new L.Map($(address).attr('map-id'),{
            zoomControl: false,
            touchZoom: false,
            scrollWheelZoom: false,
            boxZoom: false
          })
          .addLayer(new wax.leaf.connector(tilejson))
          .addLayer(new L.Marker(new L.LatLng(y , x), {icon: new icon()} ))
          .setView(new L.LatLng(y , x), 15);
      });
    });
  },

  associateMarkers: function(){
    for(var i = 0; i < OpenBlight.addresses.markers.length; i++){

      var m = OpenBlight.addresses.markers[i];

      $(m['_icon']).attr("id", "marker-" + m.id);
      $(m['_icon']).html(i + 1);
      if(i > 9){
        $(m['_icon']).addClass('two-digits');
      }
      if(i > 99){
        $(m['_icon']).addClass('three-digits');
      }
    }

    $('li.result').each(function(){
      var $this = $(this), $marker = $("#marker-" + $this.attr('data-id'));

      $this.hover(function(){
          $marker.addClass('marked');
          $this.addClass('marked');
        }, 
        function(){
          $marker.removeClass('marked');
          $this.removeClass('marked');
        });

      $marker.hover(function(){
        $marker.addClass('marked');
        $this.addClass('marked');
        }, 
        function(){
          $marker.removeClass('marked');
          $this.removeClass('marked');
        });
    });
  },

  mapSearchByBounds: function(){
    var bounds;

    $('ul.nav').addClass('loading');
    $('#loading').show();
    bounds = OpenBlight.addresses.map.getBounds();
    bounds = {
      northEast: {
        lat: bounds._northEast.lat,
        lng: bounds._northEast.lng
      },
      southWest: {
        lat: bounds._southWest.lat,
        lng: bounds._southWest.lng
      }
    }

    OpenBlight.addresses.layergroup.clearLayers();
    OpenBlight.addresses.populateMap('/addresses/map_search', bounds);
  },

  getCustomIcon: function(){
    return L.DivIcon.extend({
      options: {
        iconSize: [ 22, 37 ],
        iconAnchor: [ 0, 0 ],
        popupAnchor: [ 11, 0 ],
        className: "marker"
      }
    });
  },

  fitPointersOnMap: function(){
    var markers = [];
    for(i = 0; i < OpenBlight.addresses.markers.length; i++){
      markers[i] = OpenBlight.addresses.markers[i].getLatLng();
    }
    OpenBlight.addresses.map.fitBounds(markers);
  },
}
