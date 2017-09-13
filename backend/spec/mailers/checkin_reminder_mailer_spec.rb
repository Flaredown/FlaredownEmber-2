require "rails_helper"

RSpec.describe CheckinReminderMailer, type: :mailer do
  describe 'checkin reminder email' do
    let(:user_email) { create(:user).email }
    let(:mail) { CheckinReminderMailer.remind(email: user_email) }

    it 'renders the headers' do
      expect(mail.subject).to eq(I18n.t('checkin_reminder_mailer.subject'))
      expect(mail.to).to eq([user_email])
      expect(mail.from).to eq(['from@some.email'])
    end

    it 'renders the body' do
      body = I18n.t('checkin_reminder_mailer.body', base_url: Rails.application.secrets.base_url)
      expect(mail.body.encoded.strip.tr('\"', '')).to match(body)
    end
  end
end
