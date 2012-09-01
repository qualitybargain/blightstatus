OpenBlight.pages = {
  init: function(){

	  $("[data-scroll-to]").click(function(){
	    OpenBlight.common.goToByScroll($(this).data('scroll-to')); 
	  });
      
  },

  help: function(){
  }


}
