class ChartsPattern
  attr_accessor :start_at, :end_at, :pattern, :user, :checkins_with_wather
  attr_reader :used_color_ids

  COLOR_IDS = Flaredown::Colorable::IDS

  TYPE_CHART = {
    line: %w(conditions symptoms),
    marker: %w(treatments tags foods),
    hbi: %w(harveyBradshawIndices),
    weather: %w(weathersMeasures)
  }.freeze

  SUBTYPE = {
    static: %i(line marker),
    dynamic: %i(hbi weather)
  }.freeze

  def initialize(options)
    @start_at = options[:start_at]
    @end_at   = options[:end_at]
    @pattern  = options[:pattern]
    @user     = options[:user]
    @used_color_ids = []
    @checkins_with_wather = checkins.where(:weather_id.ne => nil)
  end

  def checkins
    @checkins ||= user.checkins.order(date: :asc)
  end

  def scoped_checkins
    @scoped_checkins ||= checkins.by_date(start_at.to_date, end_at.to_date)
  end

  def chart_data
    @data ||=
      {
        pattern_id: pattern.id,
        pattern_name: pattern.name,

        series: pattern_includes.map do |chart|
          category = chart[:category]
          type = TYPE_CHART.select { |_, value| value.include?(category) }.keys&.first
          {
            type: type,
            subtype: SUBTYPE.select { |_, value| value.include? type }.keys&.first,
            label: chart[:label],
            category: category,
            color_id: get_color_id(chart),
            data: data(chart)
          }
        end
      }
  end

  def pattern_includes
    @pattern_includes ||= pattern.includes
  end

  def data(chart)
    category = chart[:category]
    id = chart[:id]

    if %w(conditions symptoms treatments).include? category
      static_trackables_coordinates(category, scoped_checkins.map(&:id), id)
    else
      health_factors_trackables_coordinate(category, scoped_checkins, id)
    end
  end

  def static_trackables_coordinates(category, checkin_ids, id)
    trackables =
      find_coordinates_by_checkin(category, checkin_ids, id)
        .sort! { |x, y| x[:x].to_time.to_i <=> y[:x].to_time.to_i }

    return trackables if category == 'treatments'

    form_averaged_values(trackables, category, id)
  end

  def find_coordinates_by_checkin(category, checkin_ids, id)
    category_name = category.singularize

    "Checkin::#{category_name.camelize}".constantize.where(
      checkin_id: { '$in': checkin_ids },
      "#{category_name}_id": id
    ).map { |tr| { x: tr.checkin.date, y: tr.value } }.uniq
  end

  def health_factors_trackables_coordinate(category, selected_checkins, id)
    is_weather = %w(weathersMeasures).include? category

    trackables =
      if %w(foods tags).include? category
        selected_checkins.select { |checkin| checkin.send("#{category.singularize}_ids").include? id }
          .map { |checkin| { x: checkin.date } }.uniq
      elsif is_weather
        selected_checkins.select(&:weather).map { |checkin| { x: checkin.date, y: checkin.weather.send(id) } }
      else
        selected_checkins.select(&:harvey_bradshaw_index)
          .map { |checkin| { x: checkin.date, y: checkin.harvey_bradshaw_index.score } }
      end

    trackables.sort! { |x, y| x[:x].to_time.to_i <=> y[:x].to_time.to_i }
    return trackables unless is_weather

    form_averaged_values(trackables, category, id)
  end

  # rubocop:disable Metrics/AbcSize
  def form_averaged_values(coordinates_hash, category, id)
    if coordinates_hash.empty?
      start_coord = first_valid_coordinate(category, id)
      end_coord = last_valid_coordinate(category, id)
      step_coord = (end_coord[:y] - start_coord[:y]).to_f / 4

      coordinates_hash.unshift(x: start_at.to_date, y: start_coord[:y] + step_coord, average: true)
      coordinates_hash << { x: end_at.to_date, y: end_coord[:y] - step_coord, average: true }
    end

    unless coordinates_hash.first[:x].to_s == start_at && coordinates_hash.first[:y].present?
      coordinates_hash.unshift(x: start_at.to_date,
                               y: (coordinates_hash.select { |c| c[:y].present? }.first[:y] + first_valid_coordinate(category, id)[:y].to_i).to_f / 2,
                               average: true)
    end

    coordinates_hash_last = coordinates_hash.last
    unless coordinates_hash_last[:x].to_s == end_at && coordinates_hash_last[:y].present?
      last_valid = last_valid_coordinate(category, id)

      return coordinates_hash unless last_valid

      yValue = last_valid ? (last_valid[:y].to_i + coordinates_hash_last[:y].to_i) / 2 : coordinates_hash_last[:y].to_i

      coordinates_hash << { x: end_at.to_date, y: yValue, average: true }
    end

    coordinates_hash
  end
  # rubocop:enable Metrics/AbcSize

  def first_valid_coordinate(category, id)
    start_date = start_at.to_date
    category_name = category.singularize

    yValue =
      if category == "weathersMeasures"
        checkin = checkins_with_wather.where(:date.lt => start_date).first || checkins_with_wather.first
        checkin.weather.send(id) if checkin
      else
        checkin = checkins.ids_by_category_attrs(category_name, id).where(:date.lt => start_date).last
        checkin.send(category.to_s).find_by("#{category_name}_id": id).value if checkin
      end

    return { x: start_date, y: nil } unless checkin

    { x: checkin.date, y: yValue }
  end

  def last_valid_coordinate(category, id)
    end_date = end_at.to_date
    category_name = category.singularize

    yValue =
      if category == "weathersMeasures"
        checkin = checkins_with_wather.where(:date.gt => end_date).first || checkins_with_wather.last
        checkin.weather.send(id) if checkin
      else
        checkin = checkins.ids_by_category_attrs(category_name, id).where(:date.gt => end_date).first
        checkin.send(category.to_s).find_by("#{category_name}_id": id).value if checkin
      end

    return unless checkin

    { x: checkin.date, y: yValue }
  end

  def get_color_id(chart)
    model_name = chart[:category].singularize.camelize

    if Tracking::TYPES.include? model_name
      color_id = Tracking.where(user_id: user.id, trackable_type: model_name, trackable_id: chart[:id])
        .active_in_range(start_at.to_date, end_at.to_date).map(&:color_id).compact.last
    end

    if color_id
      used_color_ids << color_id

      return color_id
    end

    color_id = (COLOR_IDS - used_color_ids).shift
    used_color_ids << color_id

    color_id
  end
end
