class AddNewColumnToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :veteran_status, :boolean
  end
end
