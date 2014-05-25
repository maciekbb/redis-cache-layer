require 'spec_helper'

describe Car, :type => :model do
  before(:all) do
    colors = ["red", "green", "blue"]
    names = ["toyota", "vw", "opel"]
    speeds = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    5000.times do
      Car.create!(color: colors.sample, name: names.sample, speed: speeds.sample)
    end

    $redis.flushall
  end

  after(:all) do
    Car.destroy_all
  end

  describe "correctness" do
    it "fetches all cars" do
      expect(Car.rall.length).to eq Car.count
    end

    describe "where" do
      it "one condition" do
        expect(Car.rwhere(color: "red").length).to eq Car.where(color: "red").count
      end

      it "two conditions" do
        expect(Car.rwhere(color: "red", name: "toyota").length).to eq Car.where(color: "red", name: "toyota").count
      end
    end

    it "generates top list" do
      expect(Car.rtop("speed", 20).last["speed"].to_i).to eq Car.order(speed: :desc).limit(20)[-1]["speed"]
    end

  end

  describe "performance" do


    it "top" do
      benchmark("top") do
        Car.order("speed" => :desc).limit(50).length
      end
    end

    it "rtop" do
      benchmark("rtop") do
        Car.rtop("speed", 50).length
      end
    end

    it "where" do
      benchmark("where") do
        Car.where(color: "red", name: "toyota", speed: 30).length
      end
    end

    it "rwhere" do
      benchmark("rwhere") do
        Car.rwhere(color: "red", name: "toyota", speed: 30).length
      end
    end
  end
end


def benchmark(desc, &block)
  block.call
  time = Benchmark.realtime do
    200.times do
      block.call
    end
  end
  puts "#{desc} time: #{time}"
end
