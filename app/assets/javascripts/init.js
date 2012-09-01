OpenBlight = {
  common: {
    init: function() {
      // console.log('init');
      // application-wide code
      OpenBlight.common.show_disclaimer();
      OpenBlight.common.handle_auto_complete_address();
      


      $('.dropdown-toggle').dropdown()

    },


    goToByScroll: function(id){
      $('html,body').animate({scrollTop: $("#"+id).offset().top},'fast');
    },

    handle_auto_complete_address: function(){
      // console.log('handle_auto_complete_address');
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


    show_accounts_popover: function(){

      // $('.top-account').popover(options)

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
  }
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
