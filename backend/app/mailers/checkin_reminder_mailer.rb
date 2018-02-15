class CheckinReminderMailer < ApplicationMailer
  layout 'mailer_layout'

  def remind(notification_hash)
    @email = notification_hash[:email]
    return unless valid_email?(@email)

    user = User.find_by(email: @email)
    notify_token = user&.notify_token

    return unless notify_token
    return if user&.rejected_type.present? # Rejected via AWS SES

    @click_here_link = Rails.application.secrets.base_url
    @unsubscribe_link =
      Rails.application.secrets.base_url + "/unsubscribe/#{User.find_by(email: @email).notify_token}?stop_remind"
    attachments.inline['optional_email_img.png'] = File.read('public/images/optional_email_img.png')

    mail(to: @email, subject: I18n.t('checkin_reminder_mailer.subject'))
  end
end
