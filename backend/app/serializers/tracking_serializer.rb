# == Schema Information
#
# Table name: trackings
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  trackable_id   :integer
#  trackable_type :string
#  start_at       :date
#  end_at         :date
#  color_id       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class TrackingSerializer < ApplicationSerializer
  attributes :id, :user_id, :trackable_id, :trackable_type, :start_at, :end_at
end
