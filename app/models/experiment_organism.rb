class ExperimentOrganism < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :organism
  belongs_to :culture_growth_type
  belongs_to :strain

  validates_presence_of :experiment
  validates_presence_of :organism
end
