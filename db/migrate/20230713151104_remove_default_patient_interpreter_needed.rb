class RemoveDefaultPatientInterpreterNeeded < ActiveRecord::Migration
  def change
	change_column(:patients, :interpreter_needed, :null => true)
  end
end
