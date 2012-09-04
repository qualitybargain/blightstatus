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
      date.setMonth(date.getMonth() + 1);

      var year_to_date = [];
      var monthNames = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];

      for(i = 11; i >= 0; i--){
        month = new Date(date.setMonth(date.getMonth() - 1));
        year_to_date[i] = monthNames[month.getMonth()];
      }
      

      // $('#timeline-range').val( "335;365")

      $('#timeline-range').val( "80;109")
      

      $("#timeline-range").slider({ from: 1, to: 365, step: 1, dimension: '', scale: year_to_date, limits: false,
        calculate: function( value ){
          var tl = OpenBlight.statistics.dayRangeToDate(value);
          return  monthNames[tl.getMonth()] + ' '+ tl.getDate();
        },
        callback: function( value ){

          //clear current layers
          $('.filter-checkbox').each(function(){

            if($(this).is(':checked')){
              var this_layer = OpenBlight.statistics.layergroup[$(this).val()];
              var timeline_date = OpenBlight.statistics.getTimelineDate();

              OpenBlight.statistics.map.removeLayer(this_layer);
              OpenBlight.statistics.populateMap( $(this).val(), 
                                                  timeline_date.start_date, 
                                                  timeline_date.end_date
                                                );
            }
          });
        }
      });


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
          var timeline_date = OpenBlight.statistics.getTimelineDate();

          OpenBlight.statistics.populateMap($(this).val(), timeline_date.start_date, timeline_date.end_date);
        }
        else{
          var this_layer = OpenBlight.statistics.layergroup[$(this).val()];
          OpenBlight.statistics.map.removeLayer(this_layer);
        }
      });
    },


    getTimelineDate: function(){
      var day_range = jQuery('#timeline-range').val().split(';');
      var start_date = OpenBlight.statistics.dayRangeToDate(day_range[0]);
      var end_date = OpenBlight.statistics.dayRangeToDate(day_range[1]);

      return {start_date: start_date, end_date: end_date}
    },



    dayRangeToDate: function(value){
      timeline_date = new Date();

      timeline_date.setFullYear(timeline_date.getFullYear() - 1);   

      //lets start at the begining of the month
      timeline_date.setDate( timeline_date.getDate() - timeline_date.getDate()  );

      //now shift by number of days in timeline
      timeline_date.setDate(timeline_date.getDate() + parseInt(value));          

      return timeline_date;
    },

    createStatsMap: function(){
      wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
        var y = 29.96;
        var x = -90.08;
        var zoom = 12;

        OpenBlight.statistics.map = new L.Map('stats-map', {
          touchZoom: false,
          scrollWheelZoom: false,
          boxZoom: false
        });

        OpenBlight.statistics.map.addLayer(new wax.leaf.connector(tilejson))
        OpenBlight.statistics.map.setView(new L.LatLng(y , x), zoom);
      });
    },

    populateMap: function(type, start_date, end_date){
      var markers = [];


      // # TODO: we should be returning GeoJSON instead. This is how:
      // Check cases_controller for more info about how to do this

  
      $("input.filter-checkbox").attr("disabled", true);

      jQuery.getJSON('/cases.json', {  
          type: type, 
          start_date: start_date.toDateString(), 
          end_date: end_date.toDateString(), 
        }, 
        function(data) {

          if(data.length){
            jQuery.each(data, function(key, val) {
              a = data[key].substr(7, 35).split(' ');
                markers.push( L.circle([a[1], a[0]] , 100, { 
                  stroke: false,
                  fillColor: $('#checkbox-' + type + ' + label').css('background-color'),
                  fillOpacity: 0.5
                }));
              });
          }
          OpenBlight.statistics.layergroup[type] = new L.layerGroup(markers);
          OpenBlight.statistics.layergroup[type].addTo(OpenBlight.statistics.map);
          $("input.filter-checkbox").removeAttr("disabled");


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
