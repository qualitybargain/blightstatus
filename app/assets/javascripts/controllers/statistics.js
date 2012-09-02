OpenBlight.statistics = {
    init: function(){

      OpenBlight.statistics.layergroup = [];


    },


    //controller method
    maps: function(){

      $(":checkbox").attr("autocomplete", "off");
      OpenBlight.statistics.createStatsMap()
      OpenBlight.statistics.toggleCheckboxes();


      var date = new Date();
      var year_to_date = [];
      var monthNames = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];

      for(i = 12; i > 0; i--){
        month = new Date(date.setMonth(date.getMonth() - 1));
        year_to_date[i] = monthNames[month.getMonth()];
      }
      
      $('#timeline-range').val(date.getDOY() - date.getMonth() - 1 + ";" + date.getDOY())
      $("#timeline-range").slider({ from: 1, to: 1020, step: 12, dimension: '', scale: year_to_date, limits: false });


    },

    //controller method
    graphs: function(){

      var i;
      var keys = []
      var values = [];
      //var values = [];

      OpenBlight.statistics.createChart("inspection_types",BlightStats.data.inspections.types,"Inspection by Type");
      OpenBlight.statistics.createChart("inspection_results",BlightStats.data.inspections.results,"Inspection Results");
      OpenBlight.statistics.createChart("hearing_status",BlightStats.data.hearings.status,"Hearing Status");
      OpenBlight.statistics.createChart("judgement_status",BlightStats.data.judgements.status,"Judgement Status");
      //OpenBlight.statistics.graph("maintenance_programs",BlightStats.data.maintenances.program_names,"Maintenance by Program");
    },







    //Local Methods
    toggleCheckboxes: function(){
      $('.filter-checkbox').live('change', function(index){
        if($(this).prop('checked')){
          OpenBlight.statistics.populateMap($(this).val());
        }
        else{
          var this_layer = OpenBlight.statistics.layergroup[$(this).val()];
          OpenBlight.statistics.map.removeLayer(this_layer);
        }
      });
    },

    createStatsMap: function(){
      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
        var y = 29.96;
        var x = -90.08;
        var zoom = 12;

        OpenBlight.statistics.map = new L.Map('stats-map', {
          zoomControl: false,
          touchZoom: false,
          scrollWheelZoom: false,
          boxZoom: false
        });

        OpenBlight.statistics.map.addLayer(new wax.leaf.connector(tilejson))
        OpenBlight.statistics.map.setView(new L.LatLng(y , x), zoom);
      });
    },

    populateMap: function(type){
      var markers = [];
      jQuery.getJSON('/cases.json?type=' + type, function(data) {
        if(data.length){
          jQuery.each(data, function(key, val) {
            a = data[key].substr(7, 35).split(' ');

            markers.push( L.circle([a[1], a[0]] , 100, 
                                      { clickable: false,
                                        stroke: false,
                                        fillColor: '#f03',
                                        fillOpacity: 0.5
                                      }));
            });
        }

        OpenBlight.statistics.layergroup[type] = new L.layerGroup(markers);
        OpenBlight.statistics.layergroup[type].addTo(OpenBlight.statistics.map);

      });


    },


    createChart: function(id, data,title){
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

}
