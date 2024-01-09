class StatisticViews < Array
  def initialize(stat)
    super stat.map{_1.deep_symbolize_keys}
  end
  def gain
    integral_views = 0
    result = []
    self.each do |slice|
      new_slice = slice.dup
      new_slice[:views_gain] = new_slice.delete :views
      integral_views += new_slice[:views_gain]
      new_slice[:views] = integral_views
      result << new_slice
    end
    result
  rescue
    []
  end
end