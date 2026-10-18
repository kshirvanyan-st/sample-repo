require "rails_helper"

RSpec.describe Moderation do
  let(:moderator) { create(:user, :onboarded, role: :moderator) }
  let(:admin) { create(:user, :onboarded, role: :admin) }
  let(:user) { create(:user, :onboarded) }
  let(:moderation) { described_class.new(moderator) }

  it "is only for staff" do
    expect { described_class.new(user) }.to raise_error(Moderation::NotAllowed)
  end

  describe "#ban!" do
    it "signs the user out, closes reports against them, ends their stream and logs it" do
      user.sessions.create!
      report = create(:report, reported: user)
      stream = create(:stream, :live, user: user)
      expect_any_instance_of(MediaServer).to receive(:kick_publisher).with(stream.media_path)

      moderation.ban!(user, reason: "Spam")

      expect(user.reload).to have_attributes(banned?: true, ban_reason: "Spam")
      expect(user.sessions).to be_empty
      expect(report.reload).to have_attributes(status: "resolved", resolution: "banned", resolved_by: moderator)
      expect(stream.reload).to be_ended
      expect(ModerationAction.last).to have_attributes(moderator: moderator, action: "ban", target: user, note: "Spam")
    end

    it "won't ban staff" do
      expect { moderation.ban!(admin, reason: "x") }.to raise_error(Moderation::NotAllowed)
    end

    it "is reversible" do
      moderation.ban!(user, reason: "Mistake")
      moderation.unban!(user)
      expect(user.reload).not_to be_banned
    end
  end

  it "ends a stream and can suspend the broadcaster" do
    stream = create(:stream, :live, user: user)
    allow_any_instance_of(MediaServer).to receive(:kick_publisher)

    moderation.end_stream!(stream, suspend: true, reason: "Nudity")

    expect(stream.reload).to be_ended
    expect(user.reload).to be_streaming_suspended
    expect(ModerationAction.last).to have_attributes(action: "end_stream_and_suspend", target: stream, note: "Nudity")

    moderation.restore_streaming!(user)
    expect(user.reload).not_to be_streaming_suspended
  end

  it "approves and rejects photos" do
    photo = create(:photo, profile: user.profile)
    moderation.reject_photo!(photo, reason: "Not a real photo")
    expect(photo.reload).to be_rejected
    moderation.approve_photo!(photo)
    expect(photo.reload).to be_approved
    expect(ModerationAction.pluck(:action)).to eq(%w[ reject_photo approve_photo ])
  end

  it "dismisses reports" do
    report = create(:report)
    moderation.dismiss_report!(report)
    expect(report.reload).to have_attributes(status: "resolved", resolution: "dismissed")
  end

  it "lets only admins change roles, and never their own" do
    expect { moderation.change_role!(user, :moderator) }.to raise_error(Moderation::NotAllowed)
    described_class.new(admin).change_role!(user, :moderator)
    expect(user.reload).to be_moderator
    expect { described_class.new(admin).change_role!(admin, :member) }.to raise_error(Moderation::NotAllowed)
  end
end
