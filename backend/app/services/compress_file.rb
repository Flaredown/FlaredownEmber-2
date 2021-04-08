# frozen_string_literal: true

require 'rubygems'
require 'zip'

class CompressFile
  def initialize(file_path = nil)
    @file_path = file_path || Dir[Rails.root.join('export.csv')].first
    @tmp_zip ||= Tempfile.new("export.zip", Rails.root)
  end

  def self.call(file_path = nil)
    new(file_path).call
  end

  def call
    filename = file_path.split('/').last
    return unless filename

    Zip::File.open(tmp_zip.path, Zip::File::CREATE) do |zipfile|
      zipfile.add(filename, file_path)
    end

  ensure
    tmp_zip.close
    tmp_zip
  end

  private

  attr_accessor :file_path, :tmp_zip
end
