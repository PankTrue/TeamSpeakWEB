class HomeController < ApplicationController
  def index
    @ts=Tsserver.new
  end

  def about
  end
end
