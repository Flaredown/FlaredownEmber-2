class CommentSerializer < ApplicationSerializer
  attributes :post_id, :body, :user_name, :postable_id, :type

  def type
    'comment'
  end

  def postable_id
    :fake
  end
end
