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
        }else{
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
      var map = new L.Map('map');
      var group = new L.LayerGroup();

      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',
        function(tilejson) {
          // this shoud be moved into a function
          var json_path = window.location.toString().replace(/search\?/i, 'search.json\?');
          map.addLayer(new wax.leaf.connector(tilejson));

          jQuery.getJSON(json_path, function(data) {
            if(data.length){
              var popup = new L.Popup();

              var y = 29.95;
              var x = -90.05;
              var zoom = 12

              OpenBlight.addresses.populateMap(map, group, data);

             // we center the map on the last position
              map.setView(new L.LatLng(y, x), zoom);
              OpenBlight.addresses.associateMarkers();

              map.on('dragend', function(e){
                OpenBlight.addresses.mapSearch(map, group);
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
        var x, y, map;

          // this should not be hard coded. do json request?
        x = $("#address").attr("data-x");
        y = $("#address").attr("data-y");

        map = new L.Map('map')
          .addLayer(new wax.leaf.connector(tilejson))
          .addLayer(new L.Marker(new L.LatLng(y , x)))
          .setView(new L.LatLng(y , x), 17);
      });
    },

    associateMarkers: function(){
      for(var i = 0; i < OpenBlight.markers.length; i++){
        var m = OpenBlight.markers[i];
        $(m.marker["_icon"]).attr("id", "marker-" + m.id);
      }

      $('li.result').each(function(){
        var $this = $(this), $marker = $("#marker-" + $this.attr('data-id'));

        $this.hover(function(){
          $marker.addClass('marked');
        }, function(){
          $marker.removeClass('marked');
        });

        $marker.hover(function(){
          $this.addClass('marked');
        }, function(){
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
      for ( i = 0; i < data.length; i++ ){
        var point = data[i].point.substring(7, data[i].point.length -1).split(' ');
        var y = point[1], x= point[0];
        var popupContent = '<h3><a href="/addresses/'+ data[i].id +'">'+ data[i].address_long + '</a></h3><h4>'+ data[i].most_recent_status_preview.type + ' on ' + data[i].most_recent_status_preview.date + '</h4>'
        var marker;

        group.addLayer(marker = new L.Marker(new L.LatLng(point[1] , point[0])).bindPopup(popupContent));

        li = '<li class="active address result" data-id="'+ data[i].id +'"> <a href="/addresses/'+ data[i].id +'"><img width="10px" src="/assets/marker.png">'+ data[i].address_long +'</a></li>';
        $('.search-results ul.list').append(li);

        OpenBlight.markers.push({id: data[i].id, marker: marker});
      }
      zoom = 14
      map.addLayer(group);
    }

  },

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
