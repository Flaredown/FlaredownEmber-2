# frozen_string_literal: true

class SendCompressedFile
  def initialize(email)
    @email = email
  end

  def self.call(email)
    new(email).call
  end

  def call
    return unless email

    `rake utils:csv_export`
    file = CompressFile.call

    AdminMailer.call(email: email, file_path: file.zipfile).deliver_now

    File.delete file.zipfile
  end

  private

  attr_accessor :email
end
