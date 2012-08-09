OpenBlight.addresses = {
  init: function(){
    OpenBlight.addresses.subscribeButton();
  },

  search: function(){
    var map = new L.Map('map');
    var group = new L.LayerGroup();

    $("#map").css("height", "600px");
    wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',
      function(tilejson) {
        // this shoud be moved into a function
        var json_path = window.location.toString().replace(/search\?/i, 'search.json\?');
        map.addLayer(new wax.leaf.connector(tilejson));

        jQuery.getJSON(json_path, function(data) {
          if(data.length){
            var popup = new L.Popup();

            OpenBlight.addresses.populateMap(map, group, data);
            map.fitBounds(OpenBlight.map_points) ;
            OpenBlight.addresses.associateMarkers();

            map.on('dragend', function(e){
              if($('#map-search-mode').attr('checked')){
                OpenBlight.addresses.mapSearch(map, group);
              }
            });
          }
        });
    });

    $('.pagination.dynamic a').live('click', function(e){
        e.preventDefault();
        page = $(this).attr('data-page');
        bounds = $(this).attr('data-bounds');
        OpenBlight.addresses.mapSearch(map, group, page, bounds);
    });
  },

  show: function(){
    $(".property-status").popover({placement: 'bottom'});

    wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
      var x, y, map, CustomIcon, dotIcon;

        // this should not be hard coded. do json request?
      x = $("#address").attr("data-x");
      y = $("#address").attr("data-y");

      CustomIcon = L.DivIcon.extend({
        options: {
          iconSize: new L.Point(10, 40),
          className: "dotmarker"
        }
      });

      dotIcon = new CustomIcon({iconUrl: '/assets/dotmarker.png'});

      map = new L.Map('map')
        .addLayer(new wax.leaf.connector(tilejson))
        .addLayer(new L.Marker(new L.LatLng(y , x), {icon: dotIcon} ))
        .setView(new L.LatLng(y , x), 17);


    });
  },


  subscribeButton: function(){

    jQuery(".subscribe-button").click(function(){
      var that = this;
        jQuery.post( '/subscriptions', { id: $('#address').attr('internal_address_id') }, function(data) {
          jQuery(that).html('Unsubscribe');
        }, 'json');
    });   
  },  
 
  associateMarkers: function(){
    for(var i = 0; i < OpenBlight.markers.length; i++){
      var m = OpenBlight.markers[i];
      //console.log(m.marker['_icon'])
      $(m.marker['_icon']).attr("id", "marker-" + m.id);
      $(m.marker['_icon']).html(i+1);
      if(i > 9){
        $(m.marker['_icon']).addClass('two_digits');
      }
    }

    $('li.result').each(function(){
      var $this = $(this), $marker = $("#marker-" + $this.attr('data-id'));

      // console.log($marker);
      $this.hover(function(){
        $marker.addClass('marked');
        $this.addClass('marked');
        }, function(){
        $marker.removeClass('marked');
        $this.removeClass('marked');
      });

      $marker.hover(function(){
        $marker.addClass('marked');
        $this.addClass('marked');
      }, function(){
        $marker.removeClass('marked');
        $this.removeClass('marked');
      });

    });
  },

  mapSearch: function(map, group, page, pag_bounds){
    var bounds;

    $('ul.nav').addClass('loading');
    $('#loading').show();
    if(pag_bounds){
      bounds = JSON.parse(pag_bounds);
    } else {
      bounds = map.getBounds();
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
    }
    if(page){
      bounds.page = page;
    }

    $.get('/addresses/map_search', bounds, function(data, status){
      group.clearLayers();
      var $ul = $('.search-results ul.nav');
      $ul.html('');

      var stats = data[1], data = $.parseJSON(data[0]);

      if(data.length){
        OpenBlight.addresses.paginate(data, stats, bounds);
        OpenBlight.addresses.populateMap(map, group, data);
        OpenBlight.addresses.associateMarkers();
      }else{
        $ul.append('<li>No properties found</li>');
      }
      $('ul.nav').removeClass('loading');
      $('#loading').hide();
    }, 'json');
  },

  paginate: function(data, stats, bounds){
    var $pag = $('.pagination');
    if($pag.length == 0){
      $('.btn-group').append('<nav class="pagination"></nav>');
      $pag = $('.pagination');
    } else {
      $pag.html('');
    }
    $pag.addClass('dynamic');
    if(stats.page_count > 1){
      var pagination = "";
      var query_string = "northEast%5Blat%5D=" + bounds.northEast.lat + "&northEast%5Blng%5D=" + bounds.northEast.lng + "&southWest%5Blat%5D=" + bounds.southWest.lat + "&southWest%5Blng%5D=" + bounds.southWest.lng;
      var json_bounds = JSON.stringify(bounds);
      if(stats.page !== 1){
        pagination = pagination + "<span class='first'><a data-bounds='"+ json_bounds + "' data-page='1' href='" + query_string + "&page=1'>« First</a></span> <span class='prev'><a href='"+ query_string + "&page=" + (stats.page - 1) + "'> ‹ Prev </a></span>";
        if(stats.page > 2){
          pagination = pagination + "<span class='page'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page - 2) +"' href='" + query_string + "&page="+ (stats.page - 2) +"'>"+ (stats.page - 2) +"</a></span>";
        }
        pagination = pagination + "<span class='page'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page - 1) +"' href='" + query_string + "&page="+ (stats.page - 1 ) +"'>"+ (stats.page - 1) +"</a></span>";
      }
      pagination = pagination + "<span class='page current'>"+ stats.page +"</span>";
      if(stats.page !== stats.page_count) {
        pagination = pagination + "<span class='page'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page + 1) +"' href='" + query_string + "&page="+ (stats.page + 1)+"'>"+ (stats.page + 1) +"</a></span>";
        if(stats.page_count - stats.page > 1){
          pagination = pagination + "<span class='page'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page + 2) +"' href='" + query_string + "&page="+ (stats.page + 2)+"'>"+ (stats.page + 2) +"</a></span>";
        }
        pagination = pagination + "<span class='next'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page + 1) +"' href='" + query_string + "&page="+ (stats.page + 1)+"'>Next ›</a></span><span class='last'><a data-bounds='"+ json_bounds + "' data-page='"+ (stats.page_count) +"' href='"+ query_string + "&page="+ stats.page_count +"'>Last »</a></span>";
      }
      $pag.append(pagination);
    }
  },

  populateMap: function(map, group, data){
    OpenBlight.markers = [];
    OpenBlight.map_points = [];

    for ( i = 0; i < data.length; i++ ){
      var point = data[i].point.substring(7, data[i].point.length -1).split(' ');
      var y = point[1], x= point[0];
      var link = '/addresses/'+ data[i].id;
      var popupContent = '<h3><a href="' + link + '">' + data[i].address_long + '</a></h3>' +
      '<img src="http://maps.googleapis.com/maps/api/streetview?location='+y+','+x+'&size=200x100&sensor=true" >' +
      '<p>'+ data[i].most_recent_status_preview.type + ' on ' + data[i].most_recent_status_preview.date + '</p>';
      var map_point;
      var marker;

      var CustomIcon = L.DivIcon.extend({
        options: {
          iconSize: new L.Point(22, 37),
          iconAnchor: new L.Point(11, 37),
          className: "marker"
        }
      });

      var blankIcon = new CustomIcon();

      map_point = new L.LatLng(point[1] , point[0]);
      group.addLayer(marker = new L.Marker(map_point, {icon: blankIcon} ).bindPopup(popupContent));
      marker.on('dblclick', function(){ window.location.href = link });

      var pos = i+1;

      li = '<li class="address result '+ ((pos > 9) ? "two_digits": "") +'" data-id="'+ data[i].id +'"> <span class="maps-marker">'+pos+'</span><span class="search-address"><a href="/addresses/'+ data[i].id +'">'+ data[i].address_long +'</a></span></li>';
      $('.search-results ul.list').append(li);

      OpenBlight.markers.push({id: data[i].id, marker: marker});
      OpenBlight.map_points.push(map_point);

    }
    zoom = 14
    map.addLayer(group);
  }

}
