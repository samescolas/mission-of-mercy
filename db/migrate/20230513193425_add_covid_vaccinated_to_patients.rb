class AddCovidVaccinatedToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :covid_vaccinated, :bool
  end
end
