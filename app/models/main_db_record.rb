class MainDbRecord < ActiveRecord::Base
	self.abstract_class = true
	establish_connection :main_db

end
