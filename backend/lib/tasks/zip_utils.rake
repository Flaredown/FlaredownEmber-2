# frozen_string_literal: true

# rake zip_utils:send_email\['a'\]
namespace :zip_utils do
  task :send_email, [:email] => :environment do |t, args|
    email = args[:email]
    abort('Email should be present') if email.blank?

    SendCompressedFile.call email
  end
end
