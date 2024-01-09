class Post < ApplicationRecord
  self.primary_key = 'id'

  def statistic
    res = StatisticViews.new(read_attribute(:statistic))
    write_attribute(:statistic, res)
    res
  end

end