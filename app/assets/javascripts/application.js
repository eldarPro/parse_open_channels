//= require jquery

$(document).ready(function(){

  $('.select2').select2();

	$(document).on('change', '.set_theme', function(){
		var data = { theme_id: $(this).val(), channel_id: $(this).data('channel_id') }

		if($(this).val().length) {
			$(this).parent('.select_block').addClass('border-[1px] border-green-500 rounded-[5px]')
		} else {
			$(this).parent('.select_block').removeClass('border-[1px] border-green-500 rounded-[5px]')
		}

		$.get('/freelancers/set_theme', data, function(data) {
			if(data.success) $('.comp_row').text(data.count_complete)
			else alert('Произошла неизвестная ошибка! Повторите еще раз!')
		})
	})

	$(document).on('click', '.update_list_btn', function(){
		$(this).addClass('pointer-events-none')
	})
})