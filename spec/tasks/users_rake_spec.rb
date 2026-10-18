require "rails_helper"
require "rake"

RSpec.describe "users:grant" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }
  after { Rake::Task["users:grant"].reenable }

  it "makes a user an admin" do
    user = create(:user)
    expect { Rake::Task["users:grant"].invoke(user.email_address, "admin") }.to output(/is now admin/).to_stdout
    expect(user.reload).to be_admin
  end
end
