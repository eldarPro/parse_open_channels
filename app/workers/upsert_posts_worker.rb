# # Планировщик добавления/обновления постов в БД
# class UpsertPostsWorker
#   include Sidekiq::Worker
#   sidekiq_options queue: :critical, retry: 0

#   def perform 
#     # Обновление по 10к штук
#     count_batch = (Redis0.llen('posts_data') / 1000.to_f).ceil

#     count_batch.times do
#       values = Redis0.lrange('posts_data', 0, 999)

#       break unless values.present?

#       values = values.map{ JSON.parse(_1) }.uniq{ _1[0] }

#       upsert_values = values.map do |val| 
#         "(#{[ActiveRecord::Base.connection.quote(val[0]),
#          ActiveRecord::Base.connection.quote(val[1]),
#          ActiveRecord::Base.connection.quote(val[2]),
#          "#{ActiveRecord::Base.connection.quote(val[3].to_json)}",
#          "#{ActiveRecord::Base.connection.quote([{views: val[2], updated_at: val[-1]}].to_json)}",
#          ActiveRecord::Base.connection.quote(val[4]),
#          ActiveRecord::Base.connection.quote(val[5]),
#          ActiveRecord::Base.connection.quote(val[6]),
#          ActiveRecord::Base.connection.quote(val[7]),
#          ActiveRecord::Base.connection.quote(val[8]),
#          ActiveRecord::Base.connection.quote(val[9]),
#          ActiveRecord::Base.connection.quote(val[10]),
#          ActiveRecord::Base.connection.quote('true'),
#          ActiveRecord::Base.connection.quote(val[11]),
#          ActiveRecord::Base.connection.quote(val[12]),
#          ActiveRecord::Base.connection.quote(val[13])].join(', ')}, 
#          NOW(),
#          NOW())"
#       end.join(', ')

#       MainDbRecord.connection.execute("INSERT INTO posts_2024_1 AS p
#         (link, tg_id, views, links, statistic, has_photo, has_video, published_at, next_post_at, html, is_repost, channel_id, skip_screen, feed_hours, top_hours, last_parsed_at, created_at, updated_at)
#         VALUES #{upsert_values} ON CONFLICT (link) DO UPDATE
#         SET views = EXCLUDED.views, 
#         links = EXCLUDED.links::jsonb,
#         has_photo = EXCLUDED.has_photo,
#         has_video = EXCLUDED.has_video,
#         next_post_at = CAST(EXCLUDED.next_post_at AS TIMESTAMP WITH TIME ZONE),
#         html = EXCLUDED.html,
#         is_repost = EXCLUDED.is_repost,
#         feed_hours = EXCLUDED.feed_hours,
#         top_hours = EXCLUDED.top_hours,
#         last_parsed_at = CAST(EXCLUDED.last_parsed_at AS TIMESTAMP WITH TIME ZONE),
#         statistic = jsonb_insert(p.statistic, '{-1}', jsonb_build_object('views', (EXCLUDED.views::int - COALESCE(p.views, 0)::int), 'updated_at', EXCLUDED.last_parsed_at), true)
#       ")

#       Redis0.ltrim('posts_data', 1000, -1)
#     end

#   end
# end