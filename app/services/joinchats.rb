class Joinchats < Array
  def has_available?
    self.any?{ _1[1] == true }
  end

  def first_available
    self.select{ _1[1] == true }.first&.[](0)
  end
end