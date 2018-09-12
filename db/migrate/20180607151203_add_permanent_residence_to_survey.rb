class AddPermanentResidenceToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :has_permanent_residence, :boolean
  end
end
