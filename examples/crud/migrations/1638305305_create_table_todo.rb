# frozen_string_literal: true

class CreateTableTodo < Radical::Migration
  change do
    create_table :todo do |t|
      t.string :name
      t.integer :done_at

      t.timestamps
    end
  end
end
