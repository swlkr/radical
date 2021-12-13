<<~RB
  # frozen_string_literal: true

  class CreateTable#{plural_constant} < Radical::Migration
    change do
      create_table :#{plural} do |t|
        #{columns(leading: 8)}

        t.timestamps
      end
    end
  end
RB
