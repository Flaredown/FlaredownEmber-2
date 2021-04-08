class AdminMailer < ApplicationMailer
  layout 'mailer_layout'

  def call(email:, file_path:, file_name: 'export.zip')
    return unless email || file_path

    attachments.inline[file_name] = File.read(file_path)

    mail(to: email, subject: 'Admin data')
  end
end
