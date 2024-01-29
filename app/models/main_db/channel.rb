module MainDb
  class Channel < MainDbRecord
    has_many :posts, dependent: :destroy
    
    def self.opens
      where.not(by_web_parse: false)
    end
  
  end
end