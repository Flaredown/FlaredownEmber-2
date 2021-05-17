namespace :app do
  desc "flaredown | encrypt user_id"
  task encrypt_user_id: :environment do
    puts "Updating #{Checkin.count} checkins:\n"

    Checkin.where(:user_id.exists => true).order_by(date: :desc).each_with_index do |c, i|
      c.user_id = c[:user_id]

      c.unset(:user_id)
      c.save

      puts i if i % 100 == 0
    end

    puts "\nDone."
  end
end
