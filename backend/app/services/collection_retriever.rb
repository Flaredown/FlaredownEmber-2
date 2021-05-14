class CollectionRetriever
  attr_reader :occurrences

  def initialize(model, scope, current_user = nil)
    # FIXME
    # rubocop:disable Style/SignalException
    fail ArgumentError unless [:most_popular, :most_recent].include?(scope)
    # rubocop:enable Style/SignalException

    @model = model
    @scope = scope
    @ids_key = "#{model.name.underscore}_ids"
    @ids_field = "$#{@ids_key}"
    @current_user = current_user
  end

  def retrieve
    send @scope
  end

  private

  def most_popular
    @occurrences = Checkin.collection.aggregate(
      [
        # Step 1: have one entry per object id
        {"$unwind" => @ids_field},
        # Step 2: group by object id and count occurrences
        {"$group" => {_id: @ids_field, count: {"$sum" => 1}}},
        # Step 3: sort by occurrences, descending
        {"$sort" => {count: -1}},
        # Step 4: limit to 10 results
        {"$limit" => 10}
      ]
    )

    @model.where(id: occurrences.map { |o| o["_id"] }, global: true)
  end

  def most_recent
    checkin_relations = Checkin.collection.aggregate(
      [
        # Step 1: filter by user
        {"$match" => {encrypted_user_id: @current_user.encrypted_id}},
        # Step 2: have one entry per object id
        {"$unwind" => @ids_field},
        # Step 3: sort by checkin date, descending
        {"$sort" => {date: -1}},
        # Step 4: limit to 10 results
        {"$limit" => 10}
      ]
    )

    @model.accessible_by(current_ability).where(id: checkin_relations.map { |o| o[@ids_key] })
  end

  def current_ability
    Ability.new(@current_user)
  end
end
