class RelationshipType < ActiveRecord::Base
  has_many :experiment_assets
end
