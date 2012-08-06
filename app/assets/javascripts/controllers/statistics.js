OpenBlight.statistics = {
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
      // graph("maintenance_programs",BlightStats.data.maintenances.program_names,"Maintenance by Program");
    }

}
