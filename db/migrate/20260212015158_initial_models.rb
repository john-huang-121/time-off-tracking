class InitialModels < ActiveRecord::Migration[8.0]
  def change
    create_table :departments do |t|
      t.string :name, null: false

      t.timestamps null: false

      t.index :name, unique: true
    end

    create_table :profiles do |t|
      t.string :first_name
      t.string :last_name
      t.date :birth_date
      t.string :phone_number

      t.timestamps

      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :department, null: false, foreign_key: true
      t.references :manager, null: true, foreign_key: { to_table: :users }
    end

    create_table :time_off_requests do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :time_off_type, null: false, default: 0 # 0 = vacation, 1 = sick leave, 2 = personal day
      t.integer :status, null: false, default: 0 # 0 = pending, 1 = approved, 2 = denied, 3 = canceled
      t.text :reason
      t.integer :lock_version, null: false, default: 0

      t.timestamps null: false

      t.references :user, null: false, foreign_key: true

      t.index [ :user_id, :start_date, :end_date ]
      t.index :status
      t.check_constraint "time_off_type IN (0,1,2)", name: "chk_time_off_requests_time_off_type"
      t.check_constraint "status IN (0,1,2,3)", name: "chk_time_off_requests_status"
      t.check_constraint "start_date <= end_date", name: "chk_time_off_requests_date_range"
    end

    create_table :approvals do |t|
      t.integer :decision, null: false # 0 = approved, 1 = denied, 2 = canceled
      t.text :comment

      t.timestamps null: false

      t.references :time_off_request, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }

      t.index [ :time_off_request_id, :created_at ]
      t.check_constraint "decision IN (0,1,2)", name: "chk_approvals_decision"
    end
  end
end
