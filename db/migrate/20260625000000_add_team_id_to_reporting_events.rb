class AddTeamIdToReportingEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :reporting_events, :team_id, :bigint
    add_index :reporting_events, :team_id
  end
end
