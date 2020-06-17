class PagesController < ApplicationController
  def home
    @owners = Owner.last(6)
  end

  def about
  end
end
