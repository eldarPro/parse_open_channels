module MainDb
  class Channel < MainDbRecord
    has_many :posts, dependent: :destroy
    
    def self.opens
      where(by_web_parse: [true, nil])
    end
  
  end
end