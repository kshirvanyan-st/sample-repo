module ApplicationHelper
  INPUT_CLASSES = "block shadow-sm rounded-md border border-gray-400 focus:outline-pink-600 px-3 py-2 mt-2 w-full".freeze
  PRIMARY_BUTTON_CLASSES = "rounded-md px-3.5 py-2.5 bg-pink-600 hover:bg-pink-500 text-white font-medium cursor-pointer".freeze
  SECONDARY_BUTTON_CLASSES = "rounded-md px-3.5 py-2.5 bg-gray-200 hover:bg-gray-300 font-medium cursor-pointer".freeze

  def input_classes = INPUT_CLASSES
  def primary_button_classes = PRIMARY_BUTTON_CLASSES
  def secondary_button_classes = SECONDARY_BUTTON_CLASSES

  def liked_me_count
    Like.positive.where(likee: Current.user)
      .where.not(liker_id: Current.user.likes_given.select(:likee_id))
      .where.not(liker_id: Current.user.blocked_user_ids)
      .where(liker_id: User.active.select(:id))
      .count
  end

  def unread_chats_count
    Message.unread_for(Current.user).count
  end

  def distance_label(profile)
    return unless profile.respond_to?(:distance_km) && profile.distance_km

    km = profile.distance_km.to_f
    km < 1 ? "less than 1 km away" : "#{km.round} km away"
  end
end
