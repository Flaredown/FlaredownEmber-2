class PromotionRate
  include Mongoid::Document

  field :date,  type: Date
  field :score, type: Integer
  field :encrypted_user_id, type: String, encrypted: { type: :integer }

  belongs_to :checkin, index: true

  index(date: 1, encrypted_user_id: 1)

  validates :checkin, presence: true
  validates :checkin_id, uniqueness: true

  before_create :set_date_and_user_id

  protected

  def set_date_and_user_id
    self.date = checkin.date
    self.encrypted_user_id = checkin.encrypted_user_id
  end
end
