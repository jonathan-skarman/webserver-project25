require 'bcrypt'
require 'sqlite3'


def database(path)
	db = SQLite3::Database.new(path)
	db.results_as_hash = true
	return db
end

def db_user_info
  db = database("db/database.db")
	@user_info = db.execute("SELECT * FROM users WHERE ID = ?", session[:user_id]).first
end

def password_verification(username, password)
  db = database("db/database.db")
	user = db.execute("SELECT * FROM users WHERE username = ?", params[:username]).first

  return BCrypt::Password.new(user["password"]) == params[:password]
end
