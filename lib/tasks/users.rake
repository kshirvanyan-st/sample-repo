namespace :users do
  desc "Give a user a staff role: bin/rails 'users:grant[email@example.com,admin]' (role: moderator or admin)"
  task :grant, %i[ email role ] => :environment do |_, args|
    role = args.fetch(:role, "admin")
    abort "Role must be moderator or admin" unless role.in?(%w[ moderator admin ])

    user = User.find_by!(email_address: args.fetch(:email))
    user.update!(role: role)
    puts "#{user.email_address} is now #{role}."
  end
end
