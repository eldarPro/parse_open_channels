//= require jquery

$(document).ready(function(){
				
	$(document).on('change', '.set_theme', function(){
		var data = { theme_id: $(this).val(), channel_id: $(this).data('channel_id') }

		if($(this).val().length) {
			$(this).addClass('border-[2px] border-green-500')
		} else {
			$(this).removeClass('border-[2px] border-green-500')
		}
		

		$.get('freelancers/set_theme', data, function(data) {
			if(data.success) $('.comp_row').text(data.count_complete)
			else alert('Произошла неизвестная ошибка! Повторите еще раз!')
		})
	})

})