module MainDb
  class Channel < MainDbRecord
    has_many :posts, dependent: :destroy
    
    def self.opens
      where(by_telethon_parse: false, inner: false, is_blocked: false).where('subscribers >= 2000')
    end

    def link

    end
  
  end
end