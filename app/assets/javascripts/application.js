//= require jquery

$(document).ready(function(){
				
	$(document).on('click', '.set_theme', function(){
		var data = { theme_id: $(this).val(), channel_id: $(this).data('channel_id') }

		$.get('freelancers/set_theme', data, function(data) {
			if(data.success) $('.comp_row').text(data.count_complete)
			else alert('Произошла неизвестная ошибка! Повторите еще раз!')
		})
	})

})