require 'sinatra'
require 'slim'
require 'sinatra/reloader'
require_relative 'model.rb'

enable :sessions

before ('/protected/*') do #later
	if session[:user_id] == nil
		redirect('/')
	end
end

get ('/') do
	if session[:user_id] == nil
		redirect('/users/login')
	else
		slim(:home)
	end
end

get ('/home') do
	@user_info = db_user_info
	slim(:home)
end

get ('/users/login') do
	slim(:"users/login")
end

post ('/users/login') do
	if password_verification(params[:username], params[:password])
		db = database("db/database.db")
		user = db.execute("SELECT * FROM users WHERE username = ?", params[:username]).first
		session[:user_id] = user["id"]
		session[:access_lvl] = user["accesslvl"]
		redirect('/home')
	else
		redirect('/users/login')
	end
end

get ('/users/signup') do
	slim(:"users/signup")
end

post ('/users/signup') do
	db = database("db/database.db")
	username = params[:username]
	email = params[:email]
	password = params[:password]
	db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", [username, email, BCrypt::Password.create(password)])
	redirect('/users/login')
end

get ('/users/users') do
	db = database("db/database.db")
	@users = db.execute("SELECT * FROM users")
	slim(:"users/users")
end

get ('/users/logout') do
	session.destroy
	redirect('/')
end

get ('/events/events') do
	db = database("db/database.db")
	@events = db.execute("SELECT * FROM events")
	slim(:"events/events")
end

get ('/events/create') do
	slim(:"events/create")
end

post ('/events/new') do
	db = database("db/database.db")
	name = params[:name]
	time = params[:time]
	place = params[:place]

	db.execute("INSERT INTO events (name, time, place) VALUES (?, ?, ?)", [name, time, place])
	redirect('/events/events')
end

get ('/events/:id/attendance') do
	db = database("db/database.db")
	@event = db.execute("SELECT * FROM events WHERE ID = ?", params[:id]).first
	@attendance = db.execute("SELECT * FROM attendance WHERE event_id = ?", params[:id])
	@users = db.execute("SELECT * FROM users")

	@attendance_ids = []
	@attendance.each do |attendance|
		@attendance_ids << attendance["user_id"]
	end

	slim(:"events/attendance")
end

post ('/events/:id/attendance/new') do
	db = database("db/database.db")

	all_users = db.execute("SELECT * FROM users")

	attended_user_ids = params[:attended] || []
	event_id = params[:event_id]

	attended_user_ids.each do |user_id|
		db.execute("INSERT INTO attendance (event_id, user_id) VALUES (?, ?)", [event_id, user_id])
	end

	all_users.each do |user|
		if !attended_user_ids.include?(user["id"].to_s) && db.execute("SELECT * FROM attendance WHERE event_id = ? AND user_id = ?", [event_id, user["id"]]).length > 0
			db.execute("DELETE FROM attendance WHERE event_id = ? AND user_id = ?", [event_id, user["id"]])
		end
	end

	redirect('/events/events')
end

get ('/events/:id/edit') do
	db = database("db/database.db")
	@event = db.execute("SELECT * FROM events WHERE ID = ?", params[:id]).first
	@name = @event["name"]
	@time = @event["time"]
	@place = @event["place"]
	@id = params[:id]
	slim(:"events/edit")
end

post ('/events/update') do
	db = database("db/database.db")
	name = params[:name]
	time = params[:time]
	place = params[:place]

	if name != ""
		db.execute("UPDATE events SET name = ? WHERE ID = ?", [name, params[:id]])
	end
	if time != ""
		db.execute("UPDATE events SET time = ? WHERE ID = ?", [time, params[:id]])
	end
	if place != ""
		db.execute("UPDATE events SET place = ? WHERE ID = ?", [place, params[:id]])
	end

	redirect('/events/events')
end

get('/events/:id/delete') do
	db = database("db/database.db")
	db.execute("DELETE FROM events WHERE ID = ?", params[:id])
	redirect('/events/events')
end

get ('/users/:id/promote') do
	db = database("db/database.db")
	@user = db.execute("SELECT * FROM users WHERE ID = ?", params[:id]).first
	@id = params[:id]
	slim(:"users/promote")
end

post ('/users/promote') do
	db = database("db/database.db")
	accesslvl = params[:access_lvl]
	id = params[:id]

	if ![1, 2, 3].include?(accesslvl.to_i)
		redirect('/users/users')
	end

	db.execute("UPDATE users SET accesslvl = ? WHERE ID = ?", [accesslvl, id])
	redirect('/users/users')
end

get ('/users/:id/delete') do
	db = database("db/database.db")
	db.execute("DELETE FROM users WHERE ID = ?", params[:id])
	redirect('/users/users')
end
