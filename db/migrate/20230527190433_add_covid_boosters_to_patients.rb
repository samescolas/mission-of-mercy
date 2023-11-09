class AddCovidBoostersToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :covid_boosters, :int
  end
end
