require 'bcrypt'
require 'sqlite3'

module Model

# Connects to database and tells it to return results as hashes
#
# @param [String] path path to the database file
#
# @return [SQLite3::Database] the database object
def database(path)
	db = SQLite3::Database.new(path)
	db.results_as_hash = true
	return db
end

# Returns the user information for a given user ID
# Checks session if id is nil
#
# @param [Integer] id the ID of the user
#
# @return [Hash] the user information
#
# @see Model#database
def db_user_info(id)
	id = session[:user_id] if id.nil?

  db = database("db/database.db")
	@user_info = db.execute("SELECT * FROM users WHERE ID = ?", id).first
end

# Returns the user information for a given username
#
# @param [String] username the username of the user
#
# @return [Hash] the user information
#
# @see Model#database
def db_user_info_username(username)
	db = database("db/database.db")
	@user_info = db.execute("SELECT * FROM users WHERE username = ?", username).first
end

# Checks if the password is correct for a given username
# Returns true if the passwords match, false if the user doesn't exist or the passwords don't match
#
# @param [String] username the username of the user
# @param [String] password the password of the user
#
# @return [Boolean] true if the password is correct, false otherwise
#
# @see Model#database
def password_verification(username, password)
  db = database("db/database.db")

	user = db.execute("SELECT * FROM users WHERE username = ?", username).first

	if user.nil?
		return false
	end

	return (BCrypt::Password.new(user["password"]) == password)
end

# Checks if the email is valid
# Returns true if the email is valid, false otherwise
#
# @param [String] email the email to check
#
# @return [Boolean] true if the email is valid, false otherwise
def email_verification(email)
	list = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "elev.ga.ntig.se", "telia.se", "telia.com", "comhem.se", "bredband2.com", "bredbandsbolaget.se", "bahnhof.se", "tele2.se", "telenor.se", "3.se", "hallon.se", "halebop.se", "vimla.se", "comviq.se", "tele2.se", "telenor.se", "tre.se", "hallon.se", "halebop.se", "vimla.se", "comviq.se"]
	host = email.split("@").last

	list.include?(host)
end

# Encrypts the password using BCrypt
#
# @param [String] password the password to encrypt
#
# @return [String] the encrypted password
def password_create(password)
	BCrypt::Password.create(password)
end

# Creates a new user in the database
#
# @param [String] username the username of the user
# @param [String] email the email of the user
# @param [String] password the password of the user
# @param [Array] groups_id the groups the user is in
#
# @see Model#database
def db_create_user(username, email, password, groups_id)
	db = database("db/database.db")
	db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", [username, email, password_create(password)])
	user_id = db_user_info_username(username)["id"]

	groups_id.each do |group_id|
		db.execute("INSERT INTO User_Groups (user_id, group_id) VALUES (?, ?)", [user_id, group_id])
	end
end

# Finds the group ID for a given group name
#
# @param [String] group_name the name of the group
#
# @return [Integer] the group ID
#
# @see Model#database
def db_group_id(group_name)
	db = database("db/database.db")
	db.execute("SELECT ID FROM groups WHERE name = ?", group_name).first#["ID"]
end

# Finds the groups a user is in
#
# @params [Integer] user_id the ID of the user
#
# @return [Array] the group IDs the user is in
#
# @see Model#database
def db_user_groups(user_id)
	db = database("db/database.db")
	arr1 = db.execute("SELECT * FROM User_Groups WHERE user_id = ?", user_id)
	arr2 = []
	arr1.each do |hash|
		arr2 << hash["group_id"]
	end

	return arr2
end

# Finds all the groups in the database
#
# @return [Array] all the groups in the database
#
# @see Model#database
def db_all_groups()
	db = database("db/database.db")
	db.execute("SELECT * FROM groups")
end

# Returns the entire User_Groups table
# This is used to check if a user is in a group or not
#
# @return [Array] all the user-group pairs in the database
#
# @see Model#database
def db_all_user_groups()
	db = database("db/database.db")
	db.execute("SELECT * FROM User_Groups")
end

# Returns the group information for a given group ID
#
# @param [Integer] id the ID of the group
#
# @return [Hash] the group information
#
# @see Model#database
def db_group_info(ids)
	db = database("db/database.db")
	groups = []
	ids.each do |id|
		groups << db.execute("SELECT * FROM groups WHERE ID = ?", id).first
	end
	return groups
end

# Returns all the user information in the database
#
# @return [Array] all the users in the database
#
# @see Model#database
def db_all_users()
	db = database("db/database.db")
	db.execute("SELECT * FROM users")
end

# Returns all the events in the database
#
# @return [Array] all the events in the database
#
# @see Model#database
def db_all_events()
	db = database("db/database.db")
	db.execute("SELECT * FROM events")
end

# Creates a new event
#
# @param [String] name the name of the event
# @param [String] time the time of the event
# @param [String] place the place of the event
# @param [Integer] group_id the ID of the group the event belongs to
#
# @see Model#database
def db_create_event(name, time, place, group_id)
	db = database("db/database.db")
	db.execute("INSERT INTO events (name, time, place, group_id) VALUES (?, ?, ?, ?)", [name, time, place, group_id])
end

# Returns the event information for a given event ID
#
# @params [Integer] id the ID of the event
#
# @return [Hash] the event information
#
# @see Model#database
def db_event_info(id)
	db = database("db/database.db")
	db.execute("SELECT * FROM events WHERE ID = ?", id).first
end

# Returns the attendance information for a given event ID
#
# @params [Integer] id the ID of the event
#
# @return [Array] the attendance information
#
# @see Model#database
def db_event_attendance(id)
	db = database("db/database.db")
	db.execute("SELECT * FROM attendance WHERE event_id = ?", id)
end

# Adds a new attendance record for a given event ID and array of user IDs
#
# @params [Integer] event_id the ID of the event
# @params [Array] users the IDs of the users who attended the event
#
# @see Model#database
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

# Updates an event in the database
#
# @params [Integer] id the ID of the event
# @params [String] name the new name of the event
# @params [String] time the new time of the event
# @params [String] place the new place of the event
#
# @see Model#database
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

# Deletes an event from the database
#
# @params [Integer] id the ID of the event
#
# @see Model#database
def db_delete_event(id)
	db = database("db/database.db")
	db.execute("DELETE FROM attendance WHERE event_id = ?", id)
	db.execute("DELETE FROM events WHERE ID = ?", id)
end

# Updates a user's access level in the database
#
# @params [Integer] id the ID of the user
# @params [String] accesslvl the new access level of the user
#
# # @see Model#database
def db_user_access_level(id, accesslvl)
	db = database("db/database.db")
	db.execute("UPDATE users SET accesslvl = ? WHERE ID = ?", [accesslvl, id])
end

# Deletes a user from the database
#
# @params [Integer] id the ID of the user
#
# @see Model#database
def db_delete_user(id)
	db = database("db/database.db")
	db.execute("DELETE FROM attendance WHERE user_id = ?", id)
	db.execute("DELETE FROM users WHERE ID = ?", id)
end
