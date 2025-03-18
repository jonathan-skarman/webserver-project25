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

def db_user_info_username(username)
	db = database("db/database.db")
	@user_info = db.execute("SELECT * FROM users WHERE username = ?", username).first
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

def password_create(password)
	BCrypt::Password.create(password)
end

def db_create_user(username, email, password)
	db = database("db/database.db")
	db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", [username, email, password_create(password)])
end

def db_all_users()
	db = database("db/database.db")
	db.execute("SELECT * FROM users")
end

def db_all_events()
	db = database("db/database.db")
	db.execute("SELECT * FROM events")
end

def db_create_event(name, time, place)
	db = database("db/database.db")
	db.execute("INSERT INTO events (name, time, place) VALUES (?, ?, ?)", [name, time, place])
end

def db_event_info(id)
	db = database("db/database.db")
	db.execute("SELECT * FROM events WHERE ID = ?", id).first
end

def db_event_attendance(id)
	db = database("db/database.db")
	db.execute("SELECT * FROM attendance WHERE event_id = ?", id)
end

def db_take_attendance(event_id, users)
	db = database("db/database.db")
	all_users = db_all_users()

	users.each do |user_id|
		db.execute("INSERT INTO attendance (event_id, user_id) VALUES (?, ?)", [event_id, user_id])
	end

	all_users.each do |user|
		if !users.include?(user["id"].to_s) && db.execute("SELECT * FROM attendance WHERE event_id = ? AND user_id = ?", [event_id, user["id"]]).length > 0
			db.execute("DELETE FROM attendance WHERE event_id = ? AND user_id = ?", [event_id, user["id"]])
		end
	end
end

def db_update_event(id, name, time, place)
	db = database("db/database.db")

	if name != ""
		db.execute("UPDATE events SET name = ? WHERE ID = ?", [name, id])
	end
	if time != ""
		db.execute("UPDATE events SET time = ? WHERE ID = ?", [time, id])
	end
	if place != ""
		db.execute("UPDATE events SET place = ? WHERE ID = ?", [place, id])
	end

end

def db_delete_event(id)
	db = database("db/database.db")
	db.execute("DELETE FROM attendance WHERE event_id = ?", id)
	db.execute("DELETE FROM events WHERE ID = ?", id)
end

def db_user_access_level(id, accesslvl)
	db = database("db/database.db")
	db.execute("UPDATE users SET accesslvl = ? WHERE ID = ?", [accesslvl, id])
end

def db_delete_user(id)
	db = database("db/database.db")
	db.execute("DELETE FROM attendance WHERE user_id = ?", id)
	db.execute("DELETE FROM users WHERE ID = ?", id)
end
