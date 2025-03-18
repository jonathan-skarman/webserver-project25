require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require 'sinatra/flash'
require_relative 'model.rb'

enable :sessions

before ('/protected/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	end
end

before ('/protected2/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	elsif session[:access_lvl] < 2
		redirect('/protected/home')
	end
end

before ('/protected3/*') do
	if session[:user_id] == nil
		redirect('/users/login')
	elsif session[:access_lvl] < 3
		redirect('/protected/home')
	end
end

get ('/') do
	if session[:user_id] == nil
		redirect('/users/login')
	else
		redirect('/protected/home')
	end
end

get ('/protected/home') do
	@user_info = db_user_info(session[:user_id])
	slim(:home)
end

get ('/users/login') do
	if session[:signup] != nil
		@username, @email, @password = session[:signup]
		session[:signup] = nil
	end

	slim(:"users/login")
end

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

get ('/users/signup') do
	@username, @email, @password = session[:signup]
	session[:signup] = nil
	slim(:"users/signup")
end

post ('/users/signup') do
	@username = params[:username]
	@email = params[:email]
	@password = params[:password]
	session[:signup] = [@username, @email, @password]

	if @username == "" || @email == "" || @password == ""
		flash[:error] = "Alla fält måste fyllas i"
		redirect('/users/signup')
	elsif !email_verification(@email)
		flash[:error] = "Ogiltig e-postadress"
		redirect('/users/signup')
	elsif !(db_user_info_username(@username).nil?)
		flash[:error] = "Användarnamnet är upptaget"
		redirect('/users/signup')
	else
		db_create_user(@username, @email, @password)
		redirect('/users/login')
	end
end

get ('/protected2/users/users') do
	@users = db_all_users()
	slim(:"users/users")
end

get ('/users/logout') do
	session.destroy
	redirect('/')
end

get ('/protected/events/events') do
	@events = db_all_events()
	slim(:"events/events")
end

get ('/protected3/events/create') do
	slim(:"events/create")
end

post ('/events/new') do
	name = params[:name]
	time = params[:time]
	place = params[:place]

	if name == "" || time == "" || place == ""
		flash[:error] = "Alla fält måste fyllas i"
	else
		db_create_event(name, time, place)
		flash[:notice] = "Eventet har skapats"
	end
	redirect('/protected/events/events')
end

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

post ('/events/:id/attendance/new') do
	attended_user_ids = params[:attended] || []
	event_id = params[:event_id]

	db_take_attendance(event_id, attended_user_ids)

	flash[:notice] = "Närvaron har uppdaterats"
	redirect('/protected/events/events')
end

get ('/protected3/events/:id/edit') do
	@event = db_event_info(params[:id])
	@name = @event["name"]
	@time = @event["time"]
	@place = @event["place"]
	@id = params[:id]
	slim(:"events/edit")
end

post ('/events/update') do
	name = params[:name]
	time = params[:time]
	place = params[:place]

	db_update_event(params[:id], name, time, place)

	flash[:notice] = "Eventet har uppdaterats"
	redirect('/protected/events/events')
end

get('/protected3/events/:id/delete') do
	db_delete_event(params[:id])
	flash[:notice] = "Eventet har raderats"
	redirect('/protected/events/events')
end

get ('/protected3/users/:id/promote') do
	@id = params[:id]
	@user = db_user_info(@id)
	slim(:"users/promote")
end

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

get ('/protected3/users/:id/delete') do
	db_delete_user(params[:id])
	flash[:notice] = "Användaren har raderats"
	redirect('/protected2/users/users')
end
