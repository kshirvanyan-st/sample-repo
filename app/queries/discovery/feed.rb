module Discovery
  # Profiles to show in a viewer's swipe deck: compatible in both directions,
  # within their age and distance preferences, not yet rated and not blocked.
  class Feed
    POINT = "ll_to_earth(profiles.latitude::float8, profiles.longitude::float8)".freeze

    def initialize(viewer)
      @viewer = viewer
      @profile = viewer.profile
    end

    def next_profile
      candidates.first
    end

    def candidates
      scope = Profile.visible
        .where.not(user_id: @viewer.id)
        .where.not(user_id: @viewer.likes_given.select(:likee_id))
        .where.not(user_id: @viewer.blocked_user_ids)
        .where(gender: @profile.sought_genders)
        .where(looking_for: seeking_viewer_gender)
        .where(birthdate: birthdate_range)
        .where(Photo.approved.where("photos.profile_id = profiles.id").arel.exists)
        .includes(:user, photos: { image_attachment: :blob })

      within_distance(scope)
    end

    private
      def seeking_viewer_gender
        Profile::SEEKS.select { |_, genders| genders.include?(@profile.gender) }.keys
      end

      # Someone aged N was born between (N+1).years.ago (exclusive) and N.years.ago.
      def birthdate_range
        today = Date.current
        (today - (@profile.age_max + 1).years + 1.day)..(today - @profile.age_min.years)
      end

      def within_distance(scope)
        return scope.order(onboarded_at: :desc, id: :desc).select("profiles.*, NULL AS distance_km") unless @profile.located?

        origin = { lat: @profile.latitude.to_f, lng: @profile.longitude.to_f }
        scope = scope.where.not(latitude: nil).where.not(longitude: nil)

        if @profile.max_distance_km
          meters = @profile.max_distance_km * 1000
          # earth_box uses the GiST index; earth_distance trims the box's corners.
          scope = scope
            .where("earth_box(ll_to_earth(:lat, :lng), :meters) @> #{POINT}", **origin, meters: meters)
            .where("earth_distance(ll_to_earth(:lat, :lng), #{POINT}) <= :meters", **origin, meters: meters)
        end

        scope
          .select(Profile.sanitize_sql_array([ "profiles.*, earth_distance(ll_to_earth(:lat, :lng), #{POINT}) / 1000.0 AS distance_km", origin ]))
          .order(Arel.sql("distance_km ASC, profiles.onboarded_at DESC"))
      end
  end
end
