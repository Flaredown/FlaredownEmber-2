require 'rails_helper'

RSpec.describe Checkin::Creator do
  let!(:user) { create(:user) }
  let!(:condition) { create(:tracking, :for_condition, user: user).trackable }
  let!(:symptom) { create(:tracking, :for_symptom, user: user).trackable }
  let!(:treatment) { create(:tracking, :for_treatment, user: user).trackable }
  let!(:date) { Date.today }

  subject { Checkin::Creator.new(user.id, date).create! }

  describe 'create' do
    it 'returns a new checkin prefilled with active trackables' do
      expect(subject.id).to be_present
      expect(subject.user_id).to eq user.id
      expect(subject.date).to eq date
      expect(subject.conditions[0].condition_id).to eq condition.id
      expect(subject.symptoms[0].symptom_id).to eq symptom.id
      expect(subject.treatments[0].treatment_id).to eq treatment.id
    end
    context "when recent dose exists for treatment in user's profile" do
      before do
        user.profile.set_most_recent_dose(treatment.id, '20 mg')
        user.profile.save!
      end
      it 'sets dose from profile on the new checkin' do
        checkin_treatment = subject.treatments[0]
        expect(checkin_treatment.treatment_id).to eq treatment.id
        saved_dose = user.profile.most_recent_dose_for(treatment.id)
        expect(checkin_treatment.value).to eq saved_dose
      end
    end
    context "when trackables never used before" do
      it "creates new usage records" do
        # For Condition
        expect(subject.conditions).to be_present
        condition_usage = TrackableUsage.find_by(user: user, trackable: condition)
        expect(condition_usage).to be_present
        expect(condition_usage.count).to eq 1
        # For Symptom
        expect(subject.symptoms).to be_present
        symptom_usage = TrackableUsage.find_by(user: user, trackable: symptom)
        expect(symptom_usage).to be_present
        expect(symptom_usage.count).to eq 1
        # For Treatment
        expect(subject.treatments).to be_present
        treatment_usage = TrackableUsage.find_by(user: user, trackable: treatment)
        expect(treatment_usage).to be_present
        expect(treatment_usage.count).to eq 1
      end
    end
    context "when trackables already used before" do
      let!(:condition_usage) { TrackableUsage.create!(user: user, trackable: condition) }
      let!(:condition_usage_count) { condition_usage.count }
      let!(:symptom_usage) { TrackableUsage.create!(user: user, trackable: symptom) }
      let!(:symptom_usage_count) { symptom_usage.count }
      let!(:treatment_usage) { TrackableUsage.create!(user: user, trackable: treatment) }
      let!(:treatment_usage_count) { treatment_usage.count }
      it "increments count on usage records" do
        # For Condition
        expect(subject.conditions).to be_present
        expect(condition_usage.reload.count).to eq condition_usage_count+1
        # For Symptom
        expect(subject.symptoms).to be_present
        expect(symptom_usage.reload.count).to eq symptom_usage_count+1
        # For Treatment
        expect(subject.treatments).to be_present
        expect(treatment_usage.reload.count).to eq treatment_usage_count+1
      end
    end
  end
end
