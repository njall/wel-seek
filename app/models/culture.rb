class Culture < ActiveRecord::Base

  has_one :organism
  belongs_to :protocol

end
