class SendAlertMessage

	BOT_ID = 111

	attr_accessor :type_message

	def initialize(type_message)
		@type_message = type_message
	end

	def call
		# ....
	end

end