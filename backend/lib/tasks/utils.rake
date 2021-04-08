require 'csv'
require 'ruby-progressbar'

namespace :utils do
  task csv_export: :environment do
    headers = %w(
      user_id age sex country checkin_date
      trackable_id trackable_type trackable_name trackable_value
    )

    progress_bar = ProgressBar.create(
      title: 'Checkins',
      total: Checkin.count,
      format: '%t: |%B| %a / %E'
    )

    CSV.open('export.csv', 'wb') do |csv|
      csv << headers

      User.includes(:profile).find_each do |user|
        age = user.profile.age
        sex = user.profile.sex_id
        country = user.profile.country_id

        user.checkins.each do |checkin|
          progress_bar.increment

          user_id = SymmetricEncryption.encrypt(user.id)
          checkin_date = checkin.date.strftime('%Y-%m-%d')

          %w( condition symptom treatment ).each do |trackable_type|
            trackable_type_plural = trackable_type.pluralize
            trackable_type_capital = trackable_type.capitalize
            trackable_translation_class = "#{trackable_type_capital}::Translation".constantize
            checkin_trackables = checkin.send(trackable_type_plural)

            checkin_trackables.each do |checkin_trackable|
              next if checkin_trackable.value.nil?

              trackable_id = checkin_trackable.send("#{trackable_type}_id")
              trackable_translation = trackable_translation_class.find_by(id: trackable_id)
              next if trackable_translation.blank?

              csv << [
                user_id, age, sex, country, checkin_date,
                trackable_id, trackable_type_capital,
                trackable_translation.name, checkin_trackable.value
              ]
            end
          end

          checkin.tag_ids.each do |tag_id|
            tag = Tag::Translation.find_by(tag_id: tag_id)

            csv << [
              user_id, age, sex, country, checkin_date,
              tag_id, 'Tag', tag.name, nil
            ]
          end

          checkin.food_ids.each do |food_id|
            food = Food::Translation.find_by(food_id: food_id)

            csv << [
              user_id, age, sex, country, checkin_date,
              food_id, 'Food', food.long_desc, nil
            ]
          end

          harvey_bradshaw_index = checkin.harvey_bradshaw_index
          if harvey_bradshaw_index.present?
            csv << [
              user_id, age, sex, country, checkin_date,
              harvey_bradshaw_index.id, 'HBI', 'HBI', harvey_bradshaw_index.score
            ]
          end

          weather_id = checkin.weather_id

          next if weather_id.blank?

          weather = Weather.find(weather_id)

          %w(icon temperature_min temperature_max precip_intensity pressure humidity).each do |measure|
            csv << [
              user_id, age, sex, country, checkin_date,
              weather_id, 'Weather', measure, weather[measure]
            ]
          end
        end
      end
    end

    progress_bar.finish

    puts 'All done.'
  end
end
