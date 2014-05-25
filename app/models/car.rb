class Car < ActiveRecord::Base
  include RCL

  belongs_to :owner

end
