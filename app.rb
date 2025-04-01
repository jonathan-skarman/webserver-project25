require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'sinatra/flash'
require_relative 'model/model.rb'

enable :sessions

include Model

# Checks if the user is logged in
#
before ('/protected/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	end
end

# Checks if the user is logged in and has access level 2 or higher
#
before ('/protected2/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	elsif session[:access_lvl] < 2
		redirect('/protected/home')
	end
end

# Checks if the user is logged in and has access level 3 or higher
#
before ('/protected3/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	elsif session[:access_lvl] < 3
		redirect('/protected/home')
	end
end

# Redirect to home page if user is logged in
# Otherwise redirect to login page
#
get ('/') do
	if session[:user_id] == nil
		redirect('/users/login')
	else
		redirect('/protected/home')
	end
end

# Display home page
#
# @see Model#db_user_info
get ('/protected/home') do
	@user_info = db_user_info(session[:user_id])
	slim(:home)
end

# Display login page
# If the user has tried to sign up, pre-fill the form with the data
#
get ('/users/login') do
	if session[:signup] != nil
		@username, @email, @password = session[:signup]
		session[:signup] = nil
	end

	slim(:"users/login")
end

# Handle login form submission
# Check if the username and password are not empty
# Check if the username and password are correct
# If correct, set session variables and redirect to home page
# If incorrect, set flash message and redirect to login page
#
# If the user has just signed up, pre-fill the form with the data
#
# @param [String] :username the username of the user
# @param [String] :password the password of the user
#
# @see Model#password_verification
# @see Model#db_user_info_username
post ('/users/login') do
	if params[:username] == "" || params[:password] == ""
		flash[:error] = "Användarnamn och lösenord måste fyllas i"
		redirect('/users/login')
	elsif password_verification(params[:username], params[:password])

		user = db_user_info_username(params[:username])
		session[:user_id] = user["id"]
		session[:access_lvl] = user["accesslvl"]
		redirect('/protected/home')
	else
		flash[:error] = "Felaktigt användarnamn eller lösenord"
		redirect('/users/login')
	end
end

# Display signup page
# If the user has tried to sign up, pre-fill the form with the data
#
# @see Model#db_all_groups
get ('/users/signup') do
	@username, @email, @password, @groups = session[:signup]
	@groups = [] if @groups == nil
	@all_groups = db_all_groups()
	session[:signup] = nil
	slim(:"users/signup")
end

# Handle signup form submission
# Check if the username, email, password and groups are not empty
# Check if the email is valid
# Check if the username is not already taken
# If all checks pass, create the user and redirect to login page
# If any check fails, set flash message and redirect to signup page
#
# @param [String] username, the username of the user
# @param [String] email, the email of the user
# @param [String] password, the password of the user
# @param [Array] group, the groups the user selected
#
# @see Model#email_verification
# @see Model#db_user_info_username
# @see Model#db_create_user
post ('/users/signup') do
	@username = params[:username]
	@email = params[:email]
	@password = params[:password]
	@groups = params[:group] || []
	session[:signup] = [@username, @email, @password, @groups]

	if @username == "" || @email == "" || @password == "" || @groups == ""
		flash[:error] = "Alla fält måste fyllas i"
		redirect('/users/signup')
	elsif !email_verification(@email)
		flash[:error] = "Ogiltig e-postadress"
		redirect('/users/signup')
	elsif !(db_user_info_username(@username).nil?)
		flash[:error] = "Användarnamnet är upptaget"
		redirect('/users/signup')
	else
		db_create_user(@username, @email, @password, @groups)
		redirect('/users/login')
	end
end

# Display the list of all users in the same group as the logged in user
#
# @see Model#db_user_groups
get ('/protected2/users/users') do
	@users = db_all_users()
	@user_groups = db_all_user_groups()
	@group_names = db_all_groups()
	@groups = db_user_groups(session[:user_id])

	slim(:"users/users")
end

# Log out the user by destroying the session and redirecting to home page
#
get ('/users/logout') do
	session.destroy
	redirect('/')
end

# Display the list of all events in the same group as the logged in user
# Has additional options for users with higher access levels
#
# @see Model#db_all_events
# @see Model#db_user_groups
get ('/protected/events/events') do
	@events = db_all_events()
	@user_groups = db_user_groups(session[:user_id])
	slim(:"events/events")
end

# Display the event creation page
#
# @see Model#db_group_info
# @see Model#db_user_groups
get ('/protected3/events/create') do
	@groups = db_group_info(db_user_groups(session[:user_id]))
	@groups = [] if @groups == nil
	@name, @time, @place, @group_id = session[:event]
	session[:event] = nil

	slim(:"events/create")
end

# Handle event creation form submission
# Check if the name, time, place and group are not empty
# If any check fails, set flash message and redirect to event creation page
# If all checks pass, create the event and redirect to events page
#
# @param [String] :name, the name of the event
# @param [String] :time, the time of the event
# @param [String] :place, the place of the event
# @param [Integer] :group_id, the ID of the group the event belongs to
#
# @see Model#db_create_event
post ('/events/new') do
	@name = params[:name]
	@time = params[:time]
	@place = params[:place]
	@group_id = params[:group_id]

	if @name == "" || @time == "" || @place == "" || @group_id == ""
		session[:event] = [@name, @time, @place, @group_id]
		flash[:error] = "Alla fält måste fyllas i"
		redirect('/protected3/events/create')
	else
		db_create_event(@name, @time, @place, @group_id)
		flash[:notice] = "Eventet har skapats"
		redirect('/protected/events/events')
	end

end

# Display the event (specific) attendance page
# Pre-fill the form with data from the database
#
# @param [Integer] :id, the ID of the event
#
# @see Model#db_event_info
# @see Model#db_event_attendance
# @see Model#db_all_users
get ('/protected2/events/:id/attendance') do
	@event = db_event_info(params[:id])
	@attendance = db_event_attendance(params[:id])
	@users = db_all_users()

	@attendance_ids = []
	@attendance.each do |attendance|
		@attendance_ids << attendance["user_id"]
	end

	slim(:"events/attendance")
end

# Handle event attendance form submission
# Check if the event id is not empty
# If any check fails, set flash message and redirect to event attendance page
# If all checks pass, update the attendance and redirect to events page
#
# @param [Integer] :id, the ID of the event
# @param [Array] :attended, the IDs of the users who attended the event
#
# @see Model#db_take_attendance
post ('/events/:id/attendance/new') do
	attended_user_ids = params[:attended] || []
	event_id = params[:event_id]

	db_take_attendance(event_id, attended_user_ids)

	flash[:notice] = "Närvaron har uppdaterats"
	redirect('/protected/events/events')
end

# Display the event (specific) edit page
# Pre-fill the form with the current data
#
# @param [Integer] :id, the ID of the event
#
# @see Model#db_event_info
get ('/protected3/events/:id/edit') do
	@event = db_event_info(params[:id])
	@name = @event["name"]
	@time = @event["time"]
	@place = @event["place"]
	@id = params[:id]
	slim(:"events/edit")
end

# Handle event edit form submission
# Check if the name, time, place and id are not empty
# If any check fails, set flash message and redirect to event edit page
# If all checks pass, update the event and redirect to events page
#
# @see Model#db_update_event
post ('/events/update') do
	name = params[:name]
	time = params[:time]
	place = params[:place]

	db_update_event(params[:id], name, time, place)

	flash[:notice] = "Eventet har uppdaterats"
	redirect('/protected/events/events')
end

# Handle event deletion
#
# @param [Integer] :id, the ID of the event
#
# # @see Model#db_delete_event
get('/protected3/events/:id/delete') do
	db_delete_event(params[:id])
	flash[:notice] = "Eventet har raderats"
	redirect('/protected/events/events')
end

# Display the user (specific) access level edit page
# Only available for users with access level 3
#
# @param [Integer] :id, the ID of the user
#
# @see Model#db_user_info
get ('/protected3/users/:id/promote') do
	@id = params[:id]
	@user = db_user_info(@id)
	slim(:"users/promote")
end

# Handle user access level edit form submission
# Check if the access level is not empty and is valid (1-3)
# If any check fails, set flash message and redirect to user access level edit page
# If all checks pass, update the access level and redirect to users page
#
# @param [Integer] :id, the ID of the user
# @param [Integer] :accesslvl, the new access level of the user
#
# @see Model#db_user_access_level
post ('/users/promote') do
	accesslvl = params[:accesslvl]
	id = params[:id]

	if accesslvl == ""
		flash[:error] = "Välj en accessnivå"
	elsif accesslvl.to_i < 1 || accesslvl.to_i > 3
		p accesslvl
		flash[:error] = "Ogiltig accessnivå"
	else
		db_user_access_level(id, accesslvl)
	end

	redirect('/protected2/users/users')
end

# Handle user deletion
# Delete the user from the database and all related data (attendance)
#
# @param [Integer] :id, the ID of the user
#
# @see Model#db_delete_user
get ('/protected3/users/:id/delete') do
	db_delete_user(params[:id])
	flash[:notice] = "Användaren har raderats"
	redirect('/protected2/users/users')
end
