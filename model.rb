require 'bcrypt'
require 'sqlite3'


def database(path)
	db = SQLite3::Database.new(path)
	db.results_as_hash = true
	return db
end

def db_user_info(id)
	id = session[:user_id] if id.nil?

  db = database("db/database.db")
	@user_info = db.execute("SELECT * FROM users WHERE ID = ?", id).first
end

def password_verification(username, password)
  db = database("db/database.db")

	user = db.execute("SELECT * FROM users WHERE username = ?", username).first

	if user.nil?
		return false
	end

	return (BCrypt::Password.new(user["password"]) == password)
end

def email_verification(email)
	list = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "elev.ga.ntig.se"]
	host = email.split("@").last

	list.include?(host)
end
