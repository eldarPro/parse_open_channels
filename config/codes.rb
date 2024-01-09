6 минут 10_000 штук 4 процесса 20 потоков

Channel.select(:id, :name).where(new_tg_id: nil, main_channel_id: nil, by_web_parse: [true, nil]).limit(1000).find_each do |channel|
      ParseChannelWorker.new.perform(channel.id, channel.name)
    end


Channel.select(:id, :name).where(new_tg_id: nil, main_channel_id: nil, by_web_parse: [true, nil]).limit(5000).find_each do |channel|
  ParseChannelWorker.perform_async(channel.id, channel.name)
  ParseChannelInfoWorker.perform_async(channel.id, channel.name)
end



2.20 = 10000 по 10 внутри
2.40 = 10000 по штучно



6 мин = 10000 штук при 4 процессе по 60 штук (2 284 MB)

... мин = 10000 штук при 4 процессе по 60 штук (2 284 MB)


code = Digest::MD5.hexdigest(Time.now.to_s)

ActiveRecord::Base.connection.execute("
CREATE TEMPORARY TABLE tmp_items_#{code} (
channel_id INT,
subscribers INT,
title CHARACTER VARYING,
description TEXT,
is_verify BOOLEAN,
avatar_url CHARACTER VARYING,
update_info_at TIMESTAMP,
parse_mode CHARACTER VARYING
)
")


values = Redis0.lrange('info_channels', 0, 1000)

ActiveRecord::Base.connection.execute("INSERT INTO tmp_items_#{code} VALUES #{values.map { |v| "(#{JSON.parse(v).map { |val| ActiveRecord::Base.connection.quote(val) }.join(', ')})" }.join(', ')}")

ActiveRecord::Base.connection.execute("UPDATE channels c
SET subscribers = t.subscribers, title = t.title, description = t.description,
is_verify = t.is_verify, parse_mode 
FROM tmp_items_#{code} t
WHERE c.id = t.channel_id")


update test as t set
    column_a = c.column_a,
    column_c = c.column_c
from (values
    ('123', 1, '---'),
    ('345', 2, '+++')  
) as c(column_b, column_a, column_c) 
where c.column_b = t.column_b;


values = Redis0.lrange('info_channels', 0, 9999)

Benchmark.realtime{
a = ActiveRecord::Base.connection.execute("UPDATE channel_tests AS c SET 
  subscribers = d.subscribers,
  title = d.title,
  description = d.description,
  is_verify = d.is_verify,
  update_info_at = d.update_info_at
FROM (VALUES #{values.map { |v| "(#{JSON.parse(v).map { |val| ActiveRecord::Base.connection.quote(val) }.join(', ')})" }.join(', ')}) AS 
d(id, subscribers, title, description, is_verify, avatar_url, update_info_at, parse_mode)
where c.id = d.id;")
}


values = Redis0.lrange('info_channels', 0, 999)

ActiveRecord::Base.connection.execute("INSERT INTO tmp_items_#{code} VALUES #{values.map { |v| "(#{JSON.parse(v).map { |val| ActiveRecord::Base.connection.quote(val) }.join(', ')})" }.join(', ')}")

ActiveRecord::Base.connection.execute("UPDATE channel_test c
SET subscribers = t.subscribers, title = t.title, description = t.description,
is_verify = t.is_verify, avatar_url = t.avatar_url 
FROM tmp_items_#{code} t
WHERE c.id = t.channel_id")