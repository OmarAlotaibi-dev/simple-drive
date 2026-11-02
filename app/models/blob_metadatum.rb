class BlobMetadatum < ApplicationRecord
      validates :blob_id, presence: true,
       # بتحقق من عدم تكرار  blob_id
       uniqueness: true
  validates :size_bytes,
  # يأتكد من وجود قيمة
  presence: true,
  # يتحقق ان الحجم رقم يساوي صفرا او أكبر
  numericality: { greater_than_or_equal_to: 0 }
  validates :storage_backend, presence: true
end
