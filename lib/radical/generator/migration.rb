<<~RB
  # frozen_string_literal: true

  class CreateTable#{camel_case} < Radical::Migration
    change do
      create_table :#{snake_case} do |t|
        #{columns(leading: 8)}

        t.timestamps
      end
    end
  end
RB
