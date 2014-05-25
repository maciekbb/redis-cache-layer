require 'spec_helper'

describe Car, :type => :model do
  before(:all) do
    colors = ["red", "green", "blue"]
    names = ["toyota", "vw", "opel"]
    1000.times do
      Car.create!(color: colors.sample, name: names.sample, speed: rand(1000))
    end
  end

  after(:all) do
    Car.destroy_all
  end

  it "top" do
    benchmark("top") do
      Car.order("speed" => :desc).limit(500).length
    end
  end

  it "rtop" do
    benchmark("rtop") do
      Car.rtop("speed", 500).length
    end
  end
end


def benchmark(desc, &block)
  # block.call
  time = Benchmark.realtime do
    1.times do
      block.call
    end
  end
  puts "#{desc} time: #{time}"
end
