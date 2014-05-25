class CarController < ApplicationController
  def index
    @cars = Car.all
    render :index
  end

  def rindex
    @cars = Car.rall
    render :index
  end

  def top
    @cars = Car.order(speed: :desc).limit(params[:n])
    render :index
  end

  def rtop
    @cars = Car.rtop("speed", params[:n])
    render :index
  end

  def where
    @cars = Car.where(color: "red")
    render :index
  end

  def rwhere
    @cars = Car.rwhere(color: "red")
    render :index
  end
end
