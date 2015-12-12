/*
 * Account System
 * by Jamie Sage
 *
*/

/* -------------------------- ACCOUNT SYSTEM CONFIGURATION -------------------------- */

// Create the config variable
local aConfig = { };

/*
	Database Information
	- The information of the database you would like to connect to
	- database_host     - The host name or IP address
	- database_username - The username of the MySQL account
	- database_password - The password of the MySQL account
	- database_name     - The name of the database to use
*/
local dConfig = { };
dConfig.database_host			<- "localhost";
dConfig.database_username		<- "root";
dConfig.database_password		<- "";
dConfig.database_name			<- "m2_accounts";

/*
	Salt Length
	- The length of the salt to combind with a password while hashing
*/
aConfig.salt_length 			<- 16;

/*
	Serials Must Match
	- Should the serial tied to the account match the one trying to login to the account
	- If set to 0, then any client using any serial can login to any account (obviously, they must also know the password)
*/
aConfig.serials_must_match 	 	<- 1; 

/*
	Kick On Wrong Password
	- Should the server kick the client when they enter an incorrect password?
*/
aConfig.kick_on_wrong_password  <- 1;

/*
	Spawn At Last Position
	- Should the server spawnt the client at the last position they were standing when they previously left?
*/
aConfig.spawn_at_last_pos  		<- 1;

/*
	Log Prefix
	- The log prefix which will be shown next to all console logs in connection with the account system
*/
aConfig.LOG_PREFIX  <- "[accounts] ";

/*
	Account Data
	- These are the variables used when storing information about a specific player
*/

// -- Account Data - Can be referenced in any part of your script -- //
local accountData = { };

addEventHandler("onPlayerConnect",
	function(playerid, name, ip, serial)
	{
		accountData[playerid] 			 <- { };
		accountData[playerid].isLoggedIn <- 0;
		accountData[playerid].posX 		 <- 0.0;
		accountData[playerid].posY 		 <- 0.0;
		accountData[playerid].posZ 		 <- 0.0;
		// Example: accountData[playerid].score <- 0;
	}
);

/*
	Account System Internal Variables
*/

// -- MySQL Handler - Can be referenced in any part of your script -- //
local mysql_handler;

addEventHandler("onScriptInit",
	function()
	{
		// Initialise the account system
		local accountSys = AccountSystem();
		accountSys.init();
	}
);

addEventHandler("onScriptExit",
	function()
	{
		// Close the MySQL connection properly
	 	mysql_close(mysql_handler);
	}
);

function fnc_fadeScreenIn(playerid)
{
	// Trigger the screen fadeIn
    triggerClientEvent(playerid, "fadeScreenIn");
}

addEventHandler("onPlayerSpawn",
	function(playerid)
	{
		// Initialise the account system
	 	local accountSys = AccountSystem();

	 	// Only execute if the client hasn't logged in yet
		if(accountData[playerid].isLoggedIn == 0)
		{
			// Freeze the player so that they cannot move
			togglePlayerControls(playerid, true);

			// Show the mouse (screen doesn't fade as the player just connected)
			triggerClientEvent(playerid, "fadeScreenIn");

			// Schedule the screen to fade after the client has loaded properly
			timer(fnc_fadeScreenIn, 1500, 1, playerid);

			// Lets check if the account exists or not
			if(accountSys.doesUsernameExist(getPlayerName(playerid)))
			{
				// If the account exists, prompt them to login
				accountSys.print(getPlayerName(playerid) + " has an account.");
				sendPlayerMessage(playerid, "An account exists with the username '" + getPlayerName(playerid) + "'!", 255, 0, 0);
				sendPlayerMessage(playerid, "Please login using the /login [password] command.", 255, 0, 0);

				// Set the GUI text
				triggerClientEvent(playerid, "loginAccount");
			}
			else
			{
				// If the account doesn't exist, prompt them to register
				accountSys.print(getPlayerName(playerid) + " doesn't have an account.");
				sendPlayerMessage(playerid, "An account doesn't exist with the username '" + getPlayerName(playerid) + "'!", 255, 0, 0);
				sendPlayerMessage(playerid, "Please register using the /register [password] command.", 255, 0, 0);

				// Set the GUI text
				triggerClientEvent(playerid, "registerAccount");
			}
		}
	}
);

addEventHandler("onPlayerDisconnect",
	function(playerid, reason)
	{
		// Initialise the account system
	 	local accountSys = AccountSystem();

		// Remove the GUI for the client
		triggerClientEvent(playerid, "removeLoginGUI");

		// Store the players last position
		local position = getPlayerPosition(playerid);

		accountData[playerid].posX = position[0];
		accountData[playerid].posY = position[1];
		accountData[playerid].posZ = position[2];

		// Save the account
		accountSys.saveAccount(playerid, getPlayerName(playerid));

		// Remove the clients account data so that data doesn't mix
		delete accountData[playerid];
	}
);

addCommandHandler( "register",
    function(playerid, password)
    {
    	// Check to see if the account is logged in or not
        if(!accountData[playerid].isLoggedIn)
        {
        	// Call the register event
			callEvent("registerEvent", playerid, password);
		}
    }
);

addCommandHandler("login",
    function(playerid, password)
    {
    	// Check to see if the client is logged in or not
        if(!accountData[playerid].isLoggedIn)
        {
        	// Call the login event
        	callEvent("loginEvent", playerid, password);
        }
        return 1;
    }
);

function fnc_checkLogin(playerid, password)
{
	// Initialise the account system
	local accountSys = AccountSystem();

	// Check to see if the account is logged in or not
	if(accountSys.doesUsernameExist(getPlayerName(playerid)))
	{
		// Call the login event
		callEvent("loginEvent", playerid, password);
	}
	else
	{
		// Call the register event
		callEvent("registerEvent", playerid, password);
	}
}
addEventHandler("checkLogin", fnc_checkLogin);

function fnc_registerEvent(playerid, password)
{
	// Check to see if the users passwords length is bigger than FOUR (4)
	if(password.len() < 4)
	{
		sendPlayerMessage(playerid, "Your password must be longer than 4 characters!");
	}
	else
	{
		// Initialise the account system
		local accountSys = AccountSystem();

		// Create the account using the password; also generate a new salt and retrieve the players serial
		local result     = accountSys.createAccount(getPlayerName(playerid), password, accountSys.generateSalt(), getPlayerSerial(playerid));

		// Check to see if the account was successfully created
		if(result)
		{
			sendPlayerMessage(playerid, "You have successfully registered your account!");

			// Set the client as logged in
			accountData[playerid].isLoggedIn = 1;

			// Unfreeze the client
			togglePlayerControls(playerid, false);

			// Set the clients screen to fade back out
			triggerClientEvent(playerid, "fadeScreenOut");

			// Remove the clients login GUI
			triggerClientEvent(playerid, "removeLoginGUI");

			// Print to the console
			accountSys.print(getPlayerName(playerid) + " registered an account");
		}
		else
		{
			sendPlayerMessage(playerid, "An error occurred while registering your account, please try again.");
			
			// Print to the console
			accountSys.print(getPlayerName(playerid) + " failed to register an account (an error occurred).");
		}
	}
}
addEventHandler("registerEvent", fnc_registerEvent);

function fnc_loginEvent(playerid, password)
{
	// Check to see if the passwords length is bigger than FOUR (4)
	if(password.len() < 4)
	{
		sendPlayerMessage(playerid, "Your password must be longer than 4 characters!");
	}
	else
	{
		// Initialise the account system
		local accountSys = AccountSystem();

		// Check the password against our records
		local result     = accountSys.checkPassword(getPlayerName(playerid), password, getPlayerSerial(playerid));

		// Check to see if the password was correct
		if(result)
		{
			sendPlayerMessage(playerid, "You have successfully logged in!");

			// Set the client as logged in
			accountData[playerid].isLoggedIn = 1;

			// Unfreeze the client
			togglePlayerControls(playerid, false);

			// Set the clients screen to fade out
			triggerClientEvent(playerid, "fadeScreenOut");

			// Remove the clients GUI
			triggerClientEvent(playerid, "removeLoginGUI");

			// Print to the console
			accountSys.print(getPlayerName(playerid) + " logged in successfully.");

			// Check to see if the players serial is to be reset
			if(accountSys.getAccountSerial(getPlayerName(playerid)) == "SERIAL_RESET")
			{
				// Update the clients serial
				accountSys.updateSerial(getPlayerName(playerid), getPlayerSerial(playerid));
			}

			// Load the accounts data
			accountSys.loadAccount(playerid, getPlayerName(playerid));

			// Spawn the player at their last position
			if(aConfig.spawn_at_last_pos) setPlayerPosition(playerid, accountData[playerid].posX.tofloat(), accountData[playerid].posY.tofloat(), accountData[playerid].posZ.tofloat());
		}
		else
		{
			// Check to see if the serials should match
			if(aConfig.serials_must_match)
			{
				// If the serials should match, we compare the clients one to the one we have on record
				if(!accountSys.compareSerial(getPlayerName(playerid), getPlayerSerial(playerid)))
				{
					sendPlayerMessage(playerid, "You cannot login to this account as your serial doesn't match.");

					// Print to the console
					accountSys.print(getPlayerName(playerid) + " cannot login as their serial does not match.");
					return 1;
				}
			}
			
			sendPlayerMessage(playerid, "You entered an incorrect password, please try again.");

			// Print to the console
			accountSys.print(getPlayerName(playerid) + " entered a wrong password while logging in.");
			
			// Kick the client if set in the config
			if(aConfig.kick_on_wrong_password) kickPlayer(playerid);
		}
	}
}
addEventHandler("loginEvent", fnc_loginEvent);

addEventHandler("onConsoleInput",
	function(command, params)
	{
		// Initialise the account system
		local accountSys = AccountSystem();

		// 'createpass' console command
		if(command == "createpass")
		{
			// Check to see if any params are given
			if(params.len() > 0)
			{
				// Generate a new salt
				local salt = accountSys.generateSalt();

				// Print to the console
				accountSys.print("Hashed Password: " + accountSys.hashPassword(params, salt));

				// Print to the console
				accountSys.print("Password Salt: " + salt);
			}
			else
			{
				// Print to the console
				accountSys.print("Usage: createpass [password]");
			}
		}

		// 'resetserial' console command
		if(command == "resetserial")
		{
			// Check to see if any params are given
			if(params.len() > 0)
			{
				// Set the account to have their serial reset
				local result = accountSys.resetSerial(params);

				// Check to see if the operation was successful
				if(result)
				{
					// Print to the console
					accountSys.print("Serial reset for account '" + params + "'.");
				}
				else
				{
					// Print to the console
					accountSys.print("Failed to reset serial for account '" + params + "'.");
				}
			}
			else
			{
				// Print to the console
				accountSys.print("Usage: resetserial [username]");
			}
		}
	}
);

// Account System Class
class AccountSystem 
{
	/**
	 * AccountSystem.init
	 * - Initialises the account system, this function must be ran before using the account system
	 */
	function init()
	{
		// Attempt to connect to the MySQL database
		mysql_handler = mysql_connect(dConfig.database_host, dConfig.database_username, dConfig.database_password, dConfig.database_name);

		// Check to see if the connection was successful
		if(mysql_ping(mysql_handler))
		{
			// Print to the console
			log(aConfig.LOG_PREFIX + "Account System successfully loaded!");
		}
		else
		{
			// Print to the console
			log(aConfig.LOG_PREFIX + "Failed to load the Account System!");
		}
	}

	/**
	 * AccountSystem.doesUsernameExist
	 * - This function checks if a username exists in the MySQL database
	 * @param  string | The username to check
	 * @return bool   | True if the username exists
	 */
	function doesUsernameExist(username)
	{
		// Escape the string
		local username = mysql_escape_string(mysql_handler, username);

		//
 		// Build the MySQL query
 		mysql_query(mysql_handler, "SELECT `username` FROM `accounts` WHERE `username` = '" + username + "';");

 		// Return the result
    	return (mysql_affected_rows(mysql_handler) == 0 ? 0 : 1);
	}

	/**
	 * AccountSystem.createAccount
	 * - This function creates a new account in the MySQL database
	 * @param  string | The username of the new account
	 * @param  string | The password of the new account
	 * @param  string | The salt of the new account (see AccountSystem.generateSalt)
	 * @param  string | The serial of the new account (getPlayerSerial())
	 * @return bool   | True if the account was created
	 */
	function createAccount(username, password, salt, serial)
	{
		// Initialise the account system
		local accountSys = AccountSystem();

		// Check to see if the username exists
		if(!accountSys.doesUsernameExist(username))
		{
			// Escape the strings
			username = mysql_escape_string(mysql_handler, username);
			serial   = mysql_escape_string(mysql_handler, serial);
			password = mysql_escape_string(mysql_handler, accountSys.hashPassword(password, accountSys.generateSalt()));

			// Build the MySQL query
			mysql_query(mysql_handler, "INSERT INTO `accounts` (`username`, `password`, `salt`, `serial`) VALUES ('" + username + "', '" + password + "', '" + salt + "', '" + serial + "');");
			return 1;
		}
		return 0;
	}

	/**
	 * AccountSystem.checkPassword
	 * - This function checks if a given password and username matches the data in the MySQL database
	 * @param  string | The username of the account
	 * @param  string | The password to compare
	 * @param  string | (Optional) The serial to compare
	 * @param  string | (Optional) Should the serial match the one in the MySQL database
	 * @return bool   | True if the passwords match
	 */
	function checkPassword(username, password, serial = 0, match_serial = 1)
	{
		// Initialise the account system
		local accountSys = AccountSystem();

		// Check to see if the username exists
		if(accountSys.doesUsernameExist(username))
		{
			// Escape the strings
			username = mysql_escape_string(mysql_handler, username);
			password = mysql_escape_string(mysql_handler, password);
			password = accountSys.hashPassword(password, accountSys.getAccountSalt(username));

			// Check to see if we should match the serials (if not use the configuration option)
			if((match_serial == 0 ? 0 : aConfig.serials_must_match)) 
			{
				// Check to see if the account has had their serial reset or not
				if(accountSys.getAccountSerial(username) != "SERIAL_RESET")
				{
					// Build the MySQL query
					mysql_query(mysql_handler, "SELECT `id` FROM `accounts` WHERE `username` = '" + username + "' AND `password` = '" + password + "' AND `serial` = '" + serial + "';");
				}
				else
				{
					// Build the MySQL query
					mysql_query(mysql_handler, "SELECT `id` FROM `accounts` WHERE `username` = '" + username + "' AND `password` = '" + password + "';");
				}
			}
			else
			{
				// Build the MySQL query
				mysql_query(mysql_handler, "SELECT `id` FROM `accounts` WHERE `username` = '" + username + "' AND `password` = '" + password + "';");
			}

			// Return the result
			return (mysql_affected_rows(mysql_handler) <= 0 ? 0 : 1);
		}
		return 0;
	}

	/**
	 * AccountSystem.compareSerial
	 * - This function compares a given serial to an accounts saved serial
	 * @param  string | The username of the account
	 * @param  string | The serial to compare
	 * @return bool   | True if the serials match
	 */
	function compareSerial(username, serial)
	{
		// Escape the strings
		username = mysql_escape_string(mysql_handler, username);
		serial = mysql_escape_string(mysql_handler, serial);

		// Build the MySQL query
		mysql_query(mysql_handler, "SELECT `serial` FROM `accounts` WHERE `username` = '" + username + "' AND `serial` = '" + serial + "';");
		
		// Return the result
		return mysql_affected_rows(mysql_handler);
	}

	/**
	 * AccountSystem.resetSerial
	 * - This function resets an accounts serial so that the user can login using a different serial.
	 * - The users serial will update to the new serial once they have logged in.
	 * @param  string | The username of the account
	 * @return bool   | True if the serial was successfully reset
	 */
	function resetSerial(username)
	{
		// Escape the string
		username = mysql_escape_string(mysql_handler, username);

		// Return the result
		return mysql_query(mysql_handler, "UPDATE `accounts` SET `serial` = 'SERIAL_RESET' WHERE `username` = '" + username + "';");
	}

	/**
	 * AccountSystem.updateSerial
	 * - This function updates an accounts serial to a new serial
	 * @param  string | The username of the account
	 * @return bool   | True if the serial was successfully updated
	 */
	function updateSerial(username, new_serial)
	{
		// Escape the strings
		username   = mysql_escape_string(mysql_handler, username);
		new_serial = mysql_escape_string(mysql_handler, new_serial);

		// Return the result
		return mysql_query(mysql_handler, "UPDATE `accounts` SET `serial` = '" + new_serial + "' WHERE `username` = '" + username + "';");
	}

	/**
	 * AccountSystem.getAccountSerial
	 * - This function returns an accounts serial
	 * @param  string | The accounts username
	 * @return string | The serial of the account
	 */
	function getAccountSerial(username)
	{
		// Escape the string
		username = mysql_escape_string(mysql_handler, username);
		
		// Build the query
		local query = mysql_query(mysql_handler, "SELECT `serial` FROM `accounts` WHERE `username` = '" + username + "';");

		// Return the result
		return mysql_fetch_assoc(query).serial;
	}

	/**
	 * AccountSystem.getAccountSalt
	 * - This function returns an accoutns salt (account must exist as this function doesnt check (see AccountSystem.doesUsernameExist()))
	 * @param  string | The accounts username
	 * @return string | The accounts salt
	 */
	function getAccountSalt(username)
	{
		// Escape the string
		username = mysql_escape_string(mysql_handler, username);
		
		// Build the query
		local query = mysql_query(mysql_handler, "SELECT `salt` FROM `accounts` WHERE `username` = '" + username + "';");

		// Return the result
		return mysql_fetch_assoc(query).salt;
	}

	/**
	 * AccountSystem.loadAccount
	 * - This function loads an account from the MySQL database
	 * @param  int    | The playerid	 
	 * @param  string | The accounts username
	 */
	function loadAccount(playerid, username)
	{
		// Only load the account if they are logged in
		if(accountData[playerid].isLoggedIn == 1)
		{
			// Escape the string
			username = mysql_escape_string(mysql_handler, username);

			// Build the query
			local query  = mysql_query(mysql_handler, "SELECT * FROM `accounts` WHERE `username` = '" + username + "';");
	     	local result = mysql_fetch_assoc(query);

			// Check to see if we have a variable ready to be set (See 'Account Data' config at the top)
			foreach(ida, aData in result)
			{
				if(ida in accountData[playerid])
				{
					accountData[playerid][ida] = aData;
				}
			}

		    // Free the results
		    mysql_free_result( query );
	    }
	}

	/**
	 * AccountSystem.saveAccount
	 * - This function saves an account (using the data in accountData)
	 * @param  int    | The playerid
	 * @param  string | The accounts username
	 */
	function saveAccount(playerid, username)
	{
		// Only save the account if they are logged in
		if(accountData[playerid].isLoggedIn == 1)
		{
			// Print to the console
			log(aConfig.LOG_PREFIX + "Saving " + username + "'s account...");

			// Escape the string
			username = mysql_escape_string(mysql_handler, username);
			
			// Loop through all the data in accountData
			foreach(idx, val in accountData[playerid])
			{
				// Skip the variables which we don't want to save
	    		if(idx == "isLoggedIn") continue;

		   		// Escape the string
	    		local idx = mysql_escape_string(mysql_handler, idx);

	    		// Build the query
	    		local query = mysql_query(mysql_handler, "SHOW COLUMNS FROM `accounts` LIKE '" + idx + "';");

	    		// Check to see if the column exists (to prevent errors)
	    		if(mysql_affected_rows(mysql_handler))
	    		{
	    			// Build the query
	    			mysql_query(mysql_handler, "UPDATE `accounts` SET `" + idx + "` = '" + val + "' WHERE `username` = '" + username + "';");
	    		}
	    		else
	    		{
	    			// Print to the console
	    			log(aConfig.LOG_PREFIX + "Failed to save data `" + idx + "` with value '" + val + "' as the column doesn't exist in the database table.");
	    		}

	    		// Free the MySQL results
	    		mysql_free_result(query);
			}

			// Print to the console
			log(aConfig.LOG_PREFIX + "Successfully saved " + username + "'s account.");
		}
	}

	/**
	 * AccountSystem.hashPassword
	 * - This function hashes a password and a salt
	 * @param  string | The password to hash
	 * @param  string | The salt to hash (see AccountSystem.generateSalt())
	 * @return string | The hashed password
	 */
	function hashPassword(password, salt)
	{
		// Generate the password hash
		return md5(md5(password) + md5(salt));
	}

	/**
	 * AccountSystem.generateSalt
	 * - This function generates a random salt
	 * @return string | The random salt
	 */
	function generateSalt()
	{
		// Generate the salt with the length specified in the config
		return str_rand(aConfig.salt_length);
	}

	/**
	 * AccountSystem.print
	 * - This function logs a comment to the console
	 * @param string | The comment to print
	 */
	function print(comment)
	{
		// Log (print) to the console
		return log(aConfig.LOG_PREFIX + comment);
	}
};