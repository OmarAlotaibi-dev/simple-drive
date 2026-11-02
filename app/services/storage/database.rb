module Storage
  class Database
    def write(id, data)
      StoredBlob.create!(blob_id: id, data: data)
    end

    def read(id)
      StoredBlob.find_by!(blob_id: id).data
    end
  end
end