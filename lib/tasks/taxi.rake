namespace :taxi do
  desc "Make the user with PHONE an admin (creating the account if needed): bin/rails taxi:make_admin PHONE=+37491123456"
  task make_admin: :environment do
    phone = User.normalize_phone(ENV.fetch("PHONE")) or abort "PHONE is not a valid mobile number"
    user = User.find_or_create_by!(phone: phone)
    user.update!(role: :admin)
    puts "#{user.display_phone} is now an admin"
  end
end
