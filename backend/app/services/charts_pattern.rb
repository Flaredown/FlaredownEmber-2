class ChartsPattern
  attr_accessor :start_at, :end_at, :pattern, :user

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
    @start_at, @end_at = options[:start_at], options[:end_at]
    @pattern, @user = options[:pattern], options[:user]
  end

  def includes
    @includes ||=
      pattern_includes
        .map { |hash| hash.slice(:category, :id) }
        .group_by { |hash| hash[:category] }
        .each_with_object({}) { |obj, memo| memo[obj[0]] = obj[1].group_by {|i| i[:id] }.keys }
  end

  def checkins
    @checkins ||= user.checkins.by_date(start_at.to_date, end_at.to_date).map do |checkin|
      checkin.includes = includes

      checkin
    end
  end

  def chart_data
    @data ||=
      {
        pattern_id: pattern.id,
        pattern_name: pattern.name,

        series: pattern_includes.map do |chart|
          category = chart[:category]
          type = TYPE_CHART.select { |key, value| value.include?(category) }.keys&.first
          {
            type: type,
            subtype: SUBTYPE.select { |key, value| value.include? type }.keys&.first,
            label: chart[:label],
            category: category,
            color_id: self.get_color_id(chart),
            data: self.data(chart)
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
    category_name = category.singularize
    model_name = category_name.camelize

   res =
    if %w(conditions symptoms treatments).include? category
      trackables =
        "Checkin::#{model_name}".constantize.where(
          checkin_id: { '$in': self.checkins.map(&:id) },
          "#{category_name}_id": id
        )

      trackables.map {|tr|  { x: tr.checkin.date, y: tr.value || 0 } }

    elsif %w(foods tags).include? category
      checkins.select { |checkin| checkin.send("#{category_name}_ids").include? id }
              .map { |checkin| { x: checkin.date } }

    elsif %w(weathersMeasures).include? category
      checkins.select { |checkin| checkin.weather }
              .map { |checkin| { x: checkin.date, y: checkin.weather.send(chart[:id]) } }

    else
      checkins.select { |checkin| checkin.harvey_bradshaw_index }
              .map { |checkin| { x: checkin.date, y: checkin.harvey_bradshaw_index.score } }
    end

    res.sort { |x,y| x[:x].to_time.to_i <=> y[:x].to_time.to_i }
  end

  def get_color_id(chart)
    model_name = chart[:category].singularize.camelize

    Tracking.where(user_id: user.id, trackable_type: model_name, trackable_id: chart[:id])
     .active_in_range(start_at.to_date, end_at.to_date).map(&:color_id).compact.last
  end
end
