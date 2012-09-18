OpenBlight.statistics = {
    /**
     * Initilize Controller
     */
    init: function(){
      OpenBlight.statistics.layergroup = {};
    },


    /**
     * Controller method
     */
    browse: function(){
      // don't cache the selection. otherwise on reload the trigger event below won't fire
      $(":radio").attr("autocomplete", "off");


      $.when(
        OpenBlight.statistics.createStatsMap()
       ).then(function () {
        OpenBlight.statistics.bindRadioFilters();
        // OpenBlight.statistics.initilizeTimeline();
        $('#checkbox-inspections').trigger('click');


        
       });


    },

    /**
     * Controller method
     */
    // graphs: function(){
    //   var i;
    //   var keys = []
    //   var values = [];

    //   OpenBlight.statistics.createChart("inspection_types",BlightStats.data.inspections.types,"Inspection by Type");
    //   OpenBlight.statistics.createChart("inspection_results",BlightStats.data.inspections.results,"Inspection Results");
    //   OpenBlight.statistics.createChart("hearing_status",BlightStats.data.hearings.status,"Hearing Status");
    //   OpenBlight.statistics.createChart("judgement_status",BlightStats.data.judgements.status,"Judgement Status");
    //   //OpenBlight.statistics.graph("maintenance_programs",BlightStats.data.maintenances.program_names,"Maintenance by Program");
    // },







    /**
     * Local Methods
     */
    bindRadioFilters: function(){

      $('.nav-header select').on('change', function(index){

        console.log($(this).val());
        // var type = $(this).val() ;
        // if($(this).prop('checked')){
        //   var timeline_date = OpenBlight.statistics.getTimelineDate();
        //   OpenBlight.statistics.populateMap($(this).val(), timeline_date.start_date, timeline_date.end_date);
        //   OpenBlight.statistics.regenerateCharts();



        // }
        // else{
        //   $('#checkbox-'+type+' + .btn').html( type )
        // }

      });
    },


    getTimelineDate: function(){
      var day_range = jQuery('#timeline-range').val().split(';');
      var start_date = OpenBlight.statistics.dayRangeToDate(day_range[0]);
      var end_date = OpenBlight.statistics.dayRangeToDate(day_range[1]);

      return {start_date: start_date, end_date: end_date}
    },



    initilizeTimeline: function(){

      var date = new Date();
      date.setMonth(date.getMonth() + 1);

      var year_to_date = [];
      var monthNames = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];

      for(i = 11; i >= 0; i--){
        month = new Date(date.setMonth(date.getMonth() - 1));
        year_to_date[i] = monthNames[month.getMonth()];
      }
      

      // by default start today, and remove 30 days. 
      // TODO: don't hard code 30 days. Determine length of month
      $('#timeline-range').val( "2;365")      

      $("#timeline-range").slider({ from: 1, to: 365, step: 1, dimension: '', scale: year_to_date, limits: false,
        calculate: function( value ){
          var tl = OpenBlight.statistics.dayRangeToDate(value);
          return  monthNames[tl.getMonth()] + ' '+ tl.getDate();
        },
        callback: function( data ){

          OpenBlight.statistics.regenerateMap();
          OpenBlight.statistics.regenerateCharts();

        }
      });

    },


    regenerateCharts: function(){

      $('.filter-checkbox').each(function(){

        if($(this).is(':checked')){

          var label = $(this).val();

          var timeline_date = OpenBlight.statistics.getTimelineDate();
          jQuery.getJSON('/stats/stats.json', {  
              type: label, 
              start_date: timeline_date.start_date.toDateString(), 
              end_date: timeline_date.end_date.toDateString()
            }, 
            function(data) {
              // console.log(data);
              $('#stats-chart').html(' ');

              OpenBlight.statistics.createChart("stats-chart",data.result, label);
            });          
        }

      });
    },


    regenerateMap: function(){

      //clear current layers
      $('.filter-checkbox').each(function(){

        if($(this).is(':checked')){
          var removethis = OpenBlight.statistics.layergroup[$(this).val()];
          OpenBlight.statistics.map.removeLayer(removethis);

          var timeline_date = OpenBlight.statistics.getTimelineDate();
          OpenBlight.statistics.populateMap( $(this).val(), 
                                              timeline_date.start_date, 
                                              timeline_date.end_date
                                            );
        }
      });
    },

    dayRangeToDate: function(value){
      timeline_date = new Date();

      //we're starting a year from today
      timeline_date.setFullYear(timeline_date.getFullYear() - 1);   

      //lets start at the begining of the month
      timeline_date.setDate( timeline_date.getDate() - timeline_date.getDate()  );

      //now lets add the number of days in timeline selected in timeline
      timeline_date.setDate(timeline_date.getDate() + parseInt(value));          

      return timeline_date;
    },


    createStatsMap: function(){
      
      var deferred = jQuery.Deferred();

      var ready = wax.tilejson('http://a.tiles.mapbox.com/v3/cfaneworleans.NewOrleansPostGIS.jsonp',function(tilejson) {
        var y = 29.96;
        var x = -90.08;
        var zoom = 13;

        OpenBlight.statistics.map = new L.Map('stats-map', {
          touchZoom: false,
          scrollWheelZoom: false,
          boxZoom: false
        });

        OpenBlight.statistics.map.addLayer(new wax.leaf.connector(tilejson))
        OpenBlight.statistics.map.setView(new L.LatLng(y , x), zoom);

        deferred.resolve();

      });

      return deferred;
    },

    populateMap: function(type, start_date, end_date){


      $("input.filter-checkbox").attr("disabled", true);

      jQuery.getJSON('/addresses/addresses_with_case.json', {  
          type: type, 
          start_date: start_date.toDateString(), 
          end_date: end_date.toDateString()
        }, 
        function(data) {

          var geojsonMarkerOptions = {
              radius: 3,
              fillColor: $('#checkbox-' + type + ' + label').css('background-color'),
              color: "#ccc",
              weight: 1,
              opacity: 1,
              fillOpacity: 0.8
          };

          $.each(OpenBlight.statistics.layergroup, function(index, value) { 
            OpenBlight.statistics.map.removeLayer(OpenBlight.statistics.layergroup[index]);
          });

          OpenBlight.statistics.layergroup[type] = L.geoJson(data, {
            pointToLayer: function (feature, latlng) {
                return L.circleMarker(latlng, geojsonMarkerOptions);
            },

            onEachFeature: function(feature, layer) {
              layer.on('click', function() { window.location = '/addresses/redirect_latlong?x=' + feature.coordinates[0]  + '&y=' + feature.coordinates[1] })

            }
          }).addTo(OpenBlight.statistics.map);

          $('.total').html( 'total ' + type + ':');
          $('#total_number').html( Object.keys(data).length );
          $("input.filter-checkbox").removeAttr("disabled");
        }
      );
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
