OpenBlight = {
  common: {
    init: function() {
      // application-wide code
      OpenBlight.common.show_disclaimer();
      OpenBlight.common.handle_auto_complete_address();
      OpenBlight.common.dropdownLoginForm();

      if(!Array.prototype.last) {
        Array.prototype.last = function() {
            return this[this.length - 1];
        }
      }
      if(!String.prototype.capitalize) {
        String.prototype.capitalize = function() {
            return this.charAt(0).toUpperCase() + this.slice(1);
        }
      }
    },

    dropdownLoginForm: function(){
      $('.dropdown-menu form').submit(function(e){
        e.preventDefault();
        var $this = $(this);
        var req = $.post("/accounts/sign_in", $this.serialize(), function(data){
          location.reload();
        });
        req.error(function(){
          if(req.status == 401){
            $this.children('.error').addClass('alert').html("Your email or password (or both) is incorrect.");
          }
        });
      });
    },

    goToByScroll: function(id, speed, offset_){

      speed = (typeof speed == 'string') ? speed : 'slow';
      offset_ = (typeof offset_ != 'undefined') ? offset_ : 0;

      $('html,body').animate({scrollTop: $("#"+id).offset().top - parseInt(offset_) }, speed);
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
