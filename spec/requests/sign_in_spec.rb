require "rails_helper"

RSpec.describe "Phone sign-in", type: :request do
  let(:phone) { "+37491123456" }

  it "signs up a new number in two steps and asks for a name" do
    post session_path, params: { phone: "091 123456" }
    expect(response).to redirect_to(new_verification_path)
    expect(SmsSender::TestAdapter.deliveries.last.to).to eq(phone)

    expect {
      post verification_path, params: { code: last_sms_code }
    }.to change(User, :count).by(1).and change(Session, :count).by(1)
    expect(response).to redirect_to(edit_profile_path)
    expect(User.last).to have_attributes(phone: phone, role: "rider", locale: "hy")
  end

  it "signs in a known number and goes back to the page it came from" do
    user = create(:user, phone: phone)
    get saved_places_path
    expect(response).to redirect_to(new_session_path)

    expect { sign_in_as(user) }.not_to change(User, :count)
    expect(response).to redirect_to(saved_places_url)
  end

  it "answers the same for new and known numbers" do
    create(:user, phone: phone)
    post session_path, params: { phone: phone }
    known = [ response.status, response.location, flash[:notice] ]

    post session_path, params: { phone: "+37477123456" }
    expect([ response.status, response.location, flash[:notice] ]).to eq(known)
  end

  it "sends the SMS in the visitor's language" do
    post session_path(locale: "ru"), params: { phone: phone }
    expect(SmsSender::TestAdapter.deliveries.last.body).to start_with("Код Taxi AM")
  end

  it "rejects an invalid number without sending anything" do
    post session_path, params: { phone: "+374 10 123456" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(SmsSender::TestAdapter.deliveries).to be_empty
  end

  it "rejects a wrong code" do
    post session_path, params: { phone: phone }
    post verification_path, params: { code: last_sms_code == "000000" ? "111111" : "000000" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(cookies[:session_id]).to be_blank
  end

  it "rejects an expired code" do
    post session_path, params: { phone: phone }
    travel 6.minutes do
      post verification_path, params: { code: last_sms_code }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "needs the phone step first" do
    get new_verification_path
    expect(response).to redirect_to(new_session_path)
  end

  it "makes a resend within the cooldown wait instead of sending another SMS" do
    post session_path, params: { phone: phone }
    post session_path, params: { phone: phone }
    expect(response).to redirect_to(new_verification_path)
    expect(SmsSender::TestAdapter.deliveries.size).to eq(1)
  end

  it "limits codes per number" do
    3.times do |i|
      travel_to (i * 31).seconds.from_now do
        post session_path, params: { phone: phone }
      end
    end
    travel_to 2.minutes.from_now do
      post session_path, params: { phone: phone }
    end
    expect(response).to redirect_to(new_session_path)
    expect(SmsSender::TestAdapter.deliveries.size).to eq(3)
  end

  it "limits codes per IP across numbers" do
    10.times { |i| post session_path, params: { phone: "+3749100000#{i}" } }
    post session_path, params: { phone: "+37491000010" }
    expect(response).to redirect_to(new_session_path)
    expect(SmsSender::TestAdapter.deliveries.size).to eq(10)
  end

  it "says so when the SMS can't be sent" do
    allow(SmsSender).to receive(:deliver).and_raise(SmsSender::DeliveryError, "down")
    post session_path, params: { phone: phone }
    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to be_present
  end

  it "refuses a banned user after the code is checked" do
    user = create(:user, :banned, phone: phone)
    sign_in_as(user)
    expect(response).to redirect_to(new_session_path)
    expect(user.sessions).to be_empty
  end

  it "signs out" do
    sign_in_as(create(:user))
    delete session_path
    expect(response).to redirect_to(root_path)
    get saved_places_path
    expect(response).to redirect_to(new_session_path)
  end
end
