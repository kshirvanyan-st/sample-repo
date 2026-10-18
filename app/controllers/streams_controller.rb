class StreamsController < ApplicationController
  before_action :set_own_stream, only: %i[ studio finish ]

  # Live now: people you follow first, then the biggest audiences.
  def index
    following_ids = Current.user.following.ids
    @streams = Stream.live.visible_to(Current.user)
      .includes(user: { profile: { photos: { image_attachment: :blob } } })
      .order(Arel.sql(Stream.sanitize_sql_array([ "CASE WHEN streams.user_id IN (?) THEN 0 ELSE 1 END", following_ids.presence || [ 0 ] ])))
      .order(viewers_count: :desc, started_at: :desc)
  end

  def new
    if Current.user.streaming_suspended?
      redirect_to streams_path, alert: "Your streaming has been suspended by a moderator."
    elsif (open = Current.user.open_stream)
      redirect_to studio_stream_path(open)
    else
      @stream = Current.user.streams.new(title: "#{Current.user.profile.display_name}'s live", category: :just_chatting)
    end
  end

  def create
    return redirect_to(streams_path, alert: "Your streaming has been suspended by a moderator.") if Current.user.streaming_suspended?

    @stream = Current.user.streams.new(stream_params)

    if @stream.save
      ahoy.track "stream_created", category: @stream.category
      redirect_to studio_stream_path(@stream)
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to studio_stream_path(Current.user.open_stream)
  end

  def show
    @stream = Stream.visible_to(Current.user).find(params[:id])
    @viewer_token = @stream.viewer_token_for(Current.user) unless @stream.ended?
    ahoy.track "stream_watched", stream_id: @stream.id, live: @stream.live? unless @stream.user == Current.user
  end

  # The broadcaster's control room: camera preview, OBS settings, chat moderation.
  def studio
    Current.user.streaming_credentials!
  end

  def finish
    MediaServer.new.kick_publisher(@stream.media_path) if @stream.live?
    @stream.end!
    redirect_to studio_stream_path(@stream), notice: "Your stream has ended.", status: :see_other
  end

  # Gives the broadcaster a new stream key (e.g. after sharing their screen with it visible).
  def reset_key
    Current.user.regenerate_stream_key
    redirect_back_or_to go_live_path, notice: "Your stream key was reset. Update it in OBS.", status: :see_other
  end

  private
    def set_own_stream
      @stream = Current.user.streams.find(params[:id])
    end

    def stream_params
      params.expect(stream: %i[ title category ])
    end
end
