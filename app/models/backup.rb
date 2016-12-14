class Backup < ApplicationRecord
  belongs_to :tsserver
  validates :data, :tsserver_id, presence: true
end
