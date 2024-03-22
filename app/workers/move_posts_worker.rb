class MovePostsWorker
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 0

  def perform
    return if ActiveWorkers.new(self.class.to_s).is_active?

    last_move_post_id = Redis0.get('last_move_post_id').to_i

    Post.where(campaign: true).where('id > ?', last_move_post_id).find_in_batches(batch_size: 1000) do |old_posts|
      old_posts.each do |p|

        next if p.channel_id.blank? || p.tg_id.blank?

        new_post_values << "(#{[ActiveRecord::Base.connection.quote(p.channel_id),
          ActiveRecord::Base.connection.quote(p.order_channel_id),     
         ActiveRecord::Base.connection.quote(p.tg_id),
         ActiveRecord::Base.connection.quote(p.link),
         ActiveRecord::Base.connection.quote(p.kind),
         ActiveRecord::Base.connection.quote(p.views),
         ActiveRecord::Base.connection.quote(p.has_photo),
         ActiveRecord::Base.connection.quote(p.has_video),
         ActiveRecord::Base.connection.quote(p.top_hours),
         ActiveRecord::Base.connection.quote(p.feed_hours),
         ActiveRecord::Base.connection.quote(p.published_at),
         ActiveRecord::Base.connection.quote(p.deleted_at),
         ActiveRecord::Base.connection.quote(p.next_post_at),
         ActiveRecord::Base.connection.quote(p.skip_screen),
         ActiveRecord::Base.connection.quote(p.has_external_links),
         ActiveRecord::Base.connection.quote(p.is_repost),
         ActiveRecord::Base.connection.quote(p.last_parsed_at),
         ActiveRecord::Base.connection.quote(p.is_checked_clicks),
         ActiveRecord::Base.connection.quote(p.campaign),
         ActiveRecord::Base.connection.quote(p.created_at),
         ActiveRecord::Base.connection.quote(p.updated_at)].join(', ')})"
      end
        
      posts_data = ActiveRecord::Base.connection.execute("INSERT INTO channel_posts
        (channel_id, order_channel_id, tg_id, link, kind, views, has_photo, has_video, top_hours, feed_hours, published_at, deleted_at, next_post_at, skip_screen, has_external_links, is_repost, 
        last_parsed_at, is_checked_clicks, campaign, created_at, updated_at)
        VALUES #{new_post_values.join(', ')} ON CONFLICT DO NOTHING RETURNING id, tg_id, channel_id")

      Redis0.set('last_move_post_id', old_posts.last.id)
      Redis0.set('move_posts_count', (Redis0.get('move_posts_count').to_i + 1000)) 

      create_post_infos_values = []
      create_post_stats_values = []

      old_posts.each do |p|
        channel_post_id = posts_data.as_json.find{ _1['tg_id'] == p.tg_id && _1['channel_id'] == p.channel_id }['id'] rescue nil
        next if channel_post_id.blank?

        Redis0.rpush('screens_data', [channel_post_id, p.screenshot.to_s].to_json) if p.screenshot.to_s.present?

        links_column = ChannelPostInfo.columns[5]

        views = 0
        p.statistic.each do |s|
          next if s[:views].to_i <= 0
          views += s[:views].to_i
          create_post_stats_values << "(#{[channel_post_id, ActiveRecord::Base.connection.quote(views),
                                          ActiveRecord::Base.connection.quote(p.created_at)].join(', ')})" 
        end 

        if p.text.length > 0
          create_post_infos_values << "(#{[channel_post_id, ActiveRecord::Base.connection.quote(p.text), p.text.length,
                                           ActiveRecord::Base.connection.quote_default_expression(p.links, links_column)].join(', ')}, NOW())"   
        end
      end

      ActiveRecord::Base.connection.execute("INSERT INTO channel_post_stats (channel_post_id, views, created_at) 
        VALUES #{create_post_stats_values.join(', ')} ON CONFLICT (channel_post_id, views) DO NOTHING;") if create_post_stats_values.present?

      ActiveRecord::Base.connection.execute("INSERT INTO channel_post_infos (channel_post_id, text, text_length, links, created_at) 
        VALUES #{create_post_infos_values.join(', ')} ON CONFLICT (channel_post_id, text_length) DO NOTHING;") if create_post_infos_values.present?

    end

  end
end