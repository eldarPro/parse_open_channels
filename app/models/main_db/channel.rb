module MainDb
  class Channel < MainDbRecord
    has_many :posts, dependent: :destroy
    
    # apr - это метрика, которая вычисляется раз в сутки, она показывает прогнозное суточное значение количества просмотров
    # для различных форматов размещений поста в каналах. Форматы 1/24, 2/48, 3/72, без удаления. Формат 1/24 означает,
    # например, что пост висит 1 час в топе, и потом в ленте еще 24 часа до удаления. Т.е. получается 4 метрики apr:
    # apr_24, apr_48, apr_72, apr_eternal. Эти 4 метрики хранятся в истории 5 дней. Формат поля для каждой метрики:
    # [{val: 3400, date: '24.04.22'}, {val: 3356, date: '25.04.22'},...]
    def calculate_apr
      #Количество постов и суммарное количество их просмотров в канале за последние 72 часа
      # views_72 / count_72 - представляет собой среднее количество просмотров на пост за сутки. А почему за сутки?
      # Да потому что на текущий момент мы взяли посты за последние 3 дня и у старших постов уже набраны просмотры, а
      # у младших еще нет. Представим ситуацию, что в канале в сутки пост просматривают тысячу раз, просмотры набираются
      # равномерно. Тогда для трех постов вышедших сегодня, вчера и позавчера имеем на текущий момент просмотров:
      # 0, 1000, 2000. Т.е. 3000/3 = 1000 просмотров в день на пост по результатам трехдневной выборки
      # query = 'SELECT COUNT(id) as count, SUM(views) as views WHERE channel_id = ? AND published_at > ?'
      query = posts.select('COUNT(id) as count, SUM(views) as views').
                    where('published_at > ?', 72.hours.ago).
                    where("posts.created_at > '2023-01-01'").
                    where.not(views: nil).to_sql
      result = ActiveRecord::Base.connection.execute(query)
      count_72 = result[0]['count'].to_f
      views_72 = result[0]['views']

      query = posts.select('COUNT(id) as count, SUM(views) as views').
                    where('published_at > ?', 120.hours.ago).
                    where("posts.created_at > '2023-01-01'").
                    where.not(views: nil).to_sql
      result = ActiveRecord::Base.connection.execute(query)
      count_120 = result[0]['count'].to_f
      views_120 = result[0]['views']
      query = posts.select('COUNT(id) as count, SUM(views) as views').
                    where('published_at > ?', 168.hours.ago).
                    where("posts.created_at > '2023-01-01'").
                    where.not(views: nil).to_sql
      result = ActiveRecord::Base.connection.execute(query)
      count_168 = result[0]['count'].to_f
      views_168 = result[0]['views']
      query = posts.select('COUNT(id) as count, SUM(views) as views').
                    where('published_at > ?', 720.hours.ago).
                    where("posts.created_at > '2023-01-01'").
                    where.not(views: nil).to_sql
      result = ActiveRecord::Base.connection.execute(query)
      count_720 = result[0]['count'].to_f
      views_720 = result[0]['views']

      today = Time.now.strftime('%d.%m.%Y')
      record = { date:  today}
      apr24_1 = ( views_72  / count_72) rescue 0
      apr24_2 = ( views_120 / count_120 ) rescue 0
      record[:apr_24]      = ((apr24_1 + apr24_2) / 2).round(2) rescue 0
      record[:err_24]      = (100.0 * record[:apr_24] / subscribers).round(2) rescue 0
      record[:apr_48]      = (views_120 / count_120).round(2) rescue 0
      record[:err_48]      = (100.0 * record[:apr_48] / subscribers).round(2) rescue 0
      record[:apr_72]      = (views_168 / count_168).round(2) rescue 0
      record[:err_72]      = (100.0 * record[:apr_72] / subscribers).round(2) rescue 0
      record[:apr_eternal] = (views_720 / count_720).round(2) rescue 0
      record[:err_eternal] = (100.0 * record[:apr_eternal] / subscribers).round(2) rescue 0

      stat_today = stat.each_index.select{ |i| stat[i]['date'] == today }.first
      if stat_today.present?
        stat[stat_today] = record
      else
        self.stat << record
      end

      # add last's eternal apr and err for caching
      self.last_eternal_apr = record[:apr_eternal]
      self.last_eternal_err = record[:err_eternal]
      self.posts_per_day = count_720 / 30.0
      self.apr_calculated_at = Time.now
    end

  	def calc_average_views
      posts = self.posts&.last(10)
      post_count = posts.length
      result = nil
      result = posts&.pluck(:views)&.reject(&:nil?)&.inject(&:+)&.fdiv(post_count) if post_count != 0
      result.to_i
    end

  end
end