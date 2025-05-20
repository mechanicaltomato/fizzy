class AddParentColumnToCommands < ActiveRecord::Migration[8.1]
  def change
    add_reference :commands, :parent, null: true, foreign_key: { to_table: :commands }
    add_index :commands, %i[ user_id parent_id created_at ]
  end
end
