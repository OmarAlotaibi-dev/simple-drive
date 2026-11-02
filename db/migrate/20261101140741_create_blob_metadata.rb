class CreateBlobMetadata < ActiveRecord::Migration[8.1]
  def change
    create_table :blob_metadata do |t|
      t.string :blob_id, 
      # dose not allow null values, as each blob must have a unique identifier
      null: false 
      t.integer :size_bytes,
      # dose not allow null values, as the size of the blob is essential information
       null: false
      t.string :storage_backend ,
      # dose not allow null values, as the storage backend is essential information
       null: false

       #add last updated and created time for it
      t.timestamps
    end
     # create an index on the blob_id column to improve query performance
      add_index :blob_metadata, :blob_id,
      # dose not allow duplicate values, as each blob must have a unique identifier
      unique: true
  end
end
