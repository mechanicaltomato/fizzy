class DropSearchEmbeddings < ActiveRecord::Migration[8.1]
  def change
    drop_table :search_embeddings if table_exists?(:search_embeddings)
  end
end
