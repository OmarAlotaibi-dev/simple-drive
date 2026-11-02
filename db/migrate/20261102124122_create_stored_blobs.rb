class CreateStoredBlobs < ActiveRecord::Migration[8.1]
  def change
    create_table :stored_blobs do |t|
      t.string :blob_id, null: false
      t.binary :data, null: false

      t.timestamps
    end

    add_index :stored_blobs, :blob_id, unique: true
  end
end
