class Car < ActiveRecord::Base
  belongs_to :owner

  include RCL
end
