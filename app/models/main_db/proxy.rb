require 'socksify/http'

module MainDb
  class Proxy < MainDbRecord
    
    def self.https(group)
      proxies = Redis0.get("proxies_https_#{group}")
      return JSON.parse(proxies) if proxies.present?
      proxies = Proxy.all.where(active: true, socks5: false, group: group)
      Redis0.set("proxies_https_#{group}", proxies.to_json)
      Redis0.expire("proxies_https_#{group}", 600)
      Redis0.set("count_proxies:#{group}", proxies.length)
    end

    def self.all_count_active(group)
      Redis0.get("count_proxies:#{group}").to_i
    end

    def self.http(url, proxy_enable: false, type: :https, group: 1)
      uri   = URI.parse(url)
      proxy = nil

      if proxy_enable
        proxy = Proxy.send(type, group).to_a[rand(0..Proxy.all_count_active(group))] rescue nil
        if proxy.present?
          proxy_display_name = "#{proxy['ip']}:#{proxy['port']}:'https':#{proxy['group']}"
          sleep 2 if Redis0.get("#{proxy_display_name}:busy")
          http = Net::HTTP.new(uri.hostname, uri.port, proxy['ip'], proxy['port'])
          Redis0.set("#{proxy_display_name}:busy", '1')
          Redis0.expire("#{proxy_display_name}:busy", 2)
        end
      end

      http = Net::HTTP.new(uri.host, uri.port) unless proxy.present?

      http.use_ssl = uri.port == 443
      http.open_timeout = 8
      http.read_timeout = 8
      http
    end
  end
end