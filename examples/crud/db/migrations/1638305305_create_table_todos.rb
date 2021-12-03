Radical::Database.migration do
  change do
    create_table :todos do |t|
      t.string :name
      t.integer :done_at

      t.timestamps
    end
  end
end
