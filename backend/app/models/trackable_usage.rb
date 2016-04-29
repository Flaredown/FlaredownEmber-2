class TrackableUsage < ActiveRecord::Base

  #
  # Associations
  #

  belongs_to :user
  belongs_to :trackable, polymorphic: true, counter_cache: true


  #
  # Validations
  #
  validates :count, numericality: { greater_than: 0 }


  #
  # Class Methods
  #

  class << self

    def create_or_update_by(user: nil, trackable: nil)
      trackable_usage = self.find_by(user: user, trackable: trackable)
      if trackable_usage.present?
        trackable_usage.increment! :count
        trackable_usage
      else
        self.create!(user: user, trackable: trackable)
      end
    end

  end

end
