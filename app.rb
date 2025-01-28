require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

get ('/') do
	if session[:user_id] == nil
		redirect('/users/login')
	else
		slim(:home)
	end
end

get ('/home') do
	slim(:home)
end

get ('/users/login') do
	slim(:"users/login")
end

post ('/users/login') do
	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	result = db.execute("SELECT * FROM users WHERE username = ?", params[:username]).first
	if result
		if BCrypt::Password.new(result["password"]) == params[:password]
			session[:user_id] = result["ID"]
			redirect('/home')
		else
			redirect('/users/login')
		end
	else
		redirect('/users/login')
	end
end

get ('/users/signup') do
	slim(:"users/signup")
end

post ('/users/signup') do
	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	username = params[:username]
	email = params[:email]
	password = params[:password]
	db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", [username, email, BCrypt::Password.create(password)])
	redirect('/users/login')
end

get ('/users/users') do
	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	@users = db.execute("SELECT * FROM users")
	slim(:"users/users")
end

get ('/users/logout') do
	session.destroy
	redirect('/')
end

get ('/events/events') do
	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	@events = db.execute("SELECT * FROM events")
	slim(:"events/events")
end

get ('/events/create') do
	slim(:"events/create")
end

post ('/events/new') do
	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	name = params[:name]
	time = params[:time]
	place = params[:place]

	db.execute("INSERT INTO events (name, time, place) VALUES (?, ?, ?)", [name, time, place])
	redirect('/events/events')
end
