/* getCenterPos(element_width, element_height, result)
 * - This function returns the center position on the screen for an element
 * @params element_width  - The width of the element
 * @params element_height - The height of the element
 * @params result         - 1 returns array of X and Y, 2 returns X, 3 returns Y
 * @return int 			  - see @params result
 * @author Jamie S
*/
function getCenterPos(element_width, element_height, result = 1)
{
	local screenSize = getScreenSize();
	local x = (screenSize[0] - element_width) / 2;
	local y = (screenSize[1] - element_height) / 2;
	local array = [x, y];
	
	if(result == 2) return x;
	if(result == 3) return y;
	return array;
}

// Login GUI
local window = guiCreateElement(0, "Login/Register", getCenterPos(450, 150, 2), getCenterPos(450, 150, 3), 450.0, 125.0);
local label  = guiCreateElement(6, "Please login or register using the form below.", 8.0, 20.0, 450.0, 25.0, false, window);
local label2 = guiCreateElement(6, "Password: ", 8.0, 50.0, 450.0, 25.0, false, window);
local pass   = guiCreateElement(1, "", 70.0, 50.0, 365.0, 25.0, false, window);
local login  = guiCreateElement(2, "Login or Register", 8.0, 90.0, 430.0, 25.0, false, window);

addEventHandler("onGuiElementClick",
	function(element)
	{
		// Check to see if the login button was clicked
		if(element == login) 
		{
			// Get the text typed into the field
			local text = guiGetText(pass);

			// Pass the information onto the server to check
			triggerServerEvent("checkLogin", text);
		}
	}
);

addEventHandler("loginAccount", 
	function(playerid)
	{
		guiSetText(window, "Login");
		guiSetText(label,  "An account exists with your username, please login by typing your password into the form below.");
		guiSetText(login,  "Login");
	}
);

addEventHandler("registerAccount", 
	function(playerid)
	{
		guiSetText(window, "Register");
		guiSetText(label,  "Welcome! This account doesn't exist, please enter a password below to register.");
		guiSetText(login,  "Register");
	}
);

addEventHandler("onClientPlayerDisconnect", 
	function(playerid, nickname)
	{
		// Remove the login GUI
		callEvent("removeLoginGUI");
	}
);

addEventHandler("removeLoginGUI",
	function()
	{
		// Remove the login GUI
		guiSetVisible(window, false);
		guiSetVisible(label, false);
		guiSetVisible(pass, false);
		guiSetVisible(login, false);
		
		guiDestroyElement(window);
		guiDestroyElement(label);
		guiDestroyElement(pass);
		guiDestroyElement(login);
		
		// Hide the cursor
		showCursor(false);
	}
);

// TODO: Screen Fading
//       Its a little bit buggy, hopefully we can find a way to use it nicely ;)

addEventHandler("fadeScreenIn",
	function()
	{
		// Fade the players screen to black
		// fadeScreen(500, false);

		// Show the cursor
		showCursor(true);
	}
);

addEventHandler("fadeScreenOut", 
	function()
	{
		// Fade the players screen back in
		// fadeScreen(1000, true);

		// Hide the cursor
		showCursor(false);
	}
);