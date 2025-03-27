class RconWebApp extends WebApplication config(RconWebApp);

// Rcon web code by K6_Grimm for UT2004 remote control without using the old web interface
// This class enables server administration from modern HTTPS websites, bypassing the outdated UT2004 web admin interface.
// It supports commands like kicking, banning (ID or IP-based), unbanning, server info, player lists, map changes, and more.

// Admin password for authentication, stored in the config file (e.g., RconWebApp.ini)
var config string AdminPassword;

// Function to kick and ban a player by name, leveraging UT2004's built-in KickBan functionality
function bool KickBanPlayer(string PlayerName, out string ResponseText)
{
    local Controller C;         // Iterator for controller list (UT2004 uses Controllers instead of Pawns)
    local bool bActionTaken;    // Tracks if the kick/ban action was successful
    local string IP, PlayerID;  // Stores player's IP address and unique ID hash
    local int i;                // Index for string manipulation (IP parsing)

    bActionTaken = false;
    // Iterate through all controllers in the level
    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        // Check if the controller is a player with valid replication info
        if (C.bIsPlayer && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.PlayerName ~= PlayerName)
        {
            IP = PlayerController(C).GetPlayerNetworkAddress(); // Get player's IP:port
            PlayerID = PlayerController(C).GetPlayerIDHash();   // Get player's unique ID (UT2004 feature)
            i = InStr(IP, ":");                                 // Find port separator in IP string
            if (i != -1) IP = Left(IP, i);                      // Strip port, keep only IP
            Level.Game.KickBan(PlayerName);                     // Execute kick and ban via engine (handles both actions)
            Log("KickBan executed for " $ PlayerName $ " (ID: " $ PlayerID $ ", IP: " $ IP $ ")");
            bActionTaken = true;
            break;                                              // Exit loop after action is taken
        }
    }
    // Set response based on whether the action succeeded
    if (bActionTaken)
        ResponseText = "Player " $ PlayerName $ " kicked and banned";
    else
        ResponseText = "Error: Player " $ PlayerName $ " not found";
    return bActionTaken; // Return success status
}

// Function to unban a player by name (supports ID-based bans only; IP bans require manual config edits)
function bool UnbanPlayer(string PlayerName, out string ResponseText)
{
    local int i, j;             // Loop counters for array iteration and string parsing
    local bool bActionTaken;    // Tracks if the unban action was successful
    local string BanEntry, BanName; // Stores ban entry and extracted player name from ban list

    bActionTaken = false;
    // Check if server uses ID-based bans (UT2004 supports both ID and IP bans)
    if (Level.Game.AccessControl.bBanByID)
    {
        // Iterate through the BannedIDs array
        for (i = 0; i < Level.Game.AccessControl.BannedIDs.Length; i++)
        {
            BanEntry = Level.Game.AccessControl.BannedIDs[i];
            j = InStr(BanEntry, " ");                       // Find space separator between ID and name
            if (j != -1)
            {
                BanName = Mid(BanEntry, j + 1);             // Extract name after ID
                if (BanName ~= PlayerName)                  // Case-insensitive name match
                {
                    Log("Removing ban for ID: " $ BanEntry);
                    // Shift array elements to remove the ban entry
                    for (j = i; j < Level.Game.AccessControl.BannedIDs.Length - 1; j++)
                        Level.Game.AccessControl.BannedIDs[j] = Level.Game.AccessControl.BannedIDs[j + 1];
                    Level.Game.AccessControl.BannedIDs.Length = Level.Game.AccessControl.BannedIDs.Length - 1;
                    Level.Game.AccessControl.SaveConfig();  // Save updated ban list to config
                    bActionTaken = true;
                    break;
                }
            }
        }
    }
    else
    {
        // IP-based bans aren’t fully supported for unban by name in this function
        ResponseText = "Error: IP-based bans in use; unban by name not fully supported";
        return false;
    }
    // Set response based on success
    if (bActionTaken)
        ResponseText = "Player " $ PlayerName $ " unbanned";
    else
        ResponseText = "Error: No ban found for player " $ PlayerName;
    return bActionTaken; // Return success status
}

// Main query handler for web requests, processes all incoming commands
function Query(WebRequest Request, WebResponse Response)
{
    local string cmd, result, MapName;  // Command string, result text, and temporary name storage
    local Controller C;                 // Iterator for controller list (players in UT2004)
    local bool bActionTaken;            // Tracks if an action (e.g., kick) was successful
    local string IP, Param;             // Stores IP address and command parameter
    local int i;                        // Loop counter

    // Authentication check: ensures the provided password matches the configured AdminPassword (case-insensitive)
    if (AdminPassword == "" || Caps(Request.Password) != Caps(AdminPassword))
    {
        Response.FailAuthentication("UT2004 Rcon"); // Fails if password is empty or incorrect
        return;
    }

    cmd = Request.GetVariable("cmd", "");   // Retrieve the command from the web request
    while (Left(cmd, 1) == " ") cmd = Mid(cmd, 1);      // Trim leading spaces from command
    while (Right(cmd, 1) == " ") cmd = Left(cmd, Len(cmd) - 1); // Trim trailing spaces from command

    if (cmd != "")
    {
        // Server info command: returns basic server details
        if (cmd ~= "serverinfo" || cmd ~= "admin serverinfo")
        {
            result = "Server: " $ Level.Game.GameReplicationInfo.ServerName $
                     ", Map: " $ Level.Title $
                     ", Players: " $ string(Level.Game.NumPlayers) $ "/" $ string(Level.Game.MaxPlayers);
            Response.SendText(result); // Sends server name, map, and player count
        }
        // List all connected players with details
        else if (cmd ~= "admin players")
        {
            result = "Players:" $ chr(13) $ chr(10);    // Start with header and newline
            for (C = Level.ControllerList; C != None; C = C.NextController)
            {
                if (C.bIsPlayer && C.PlayerReplicationInfo != None)
                {
                    result $= C.PlayerReplicationInfo.PlayerName $ " (Ping: " $ C.PlayerReplicationInfo.Ping $ 
                              ", IP: " $ PlayerController(C).GetPlayerNetworkAddress() $ ")" $ chr(13) $ chr(10);
                }
            }
            if (Len(result) > 9)    // Check if any players were listed
                Response.SendText(result);
            else
                Response.SendText("No players connected");
        }
        // List all banned entries (ID or IP-based, depending on server settings)
        else if (cmd ~= "admin bans")
        {
            result = "Banned Entries:" $ chr(13) $ chr(10); // Use explicit newline characters
            if (Level.Game.AccessControl.bBanByID)
            {
                if (Level.Game.AccessControl.BannedIDs.Length > 0)
                {
                    for (i = 0; i < Level.Game.AccessControl.BannedIDs.Length; i++)
                        result $= Level.Game.AccessControl.BannedIDs[i] $ chr(13) $ chr(10); // List ID bans
                }
                else
                    result = "No ID-based bans found";
            }
            else
            {
                if (Level.Game.AccessControl.IPPolicies.Length > 0)
                {
                    for (i = 0; i < Level.Game.AccessControl.IPPolicies.Length; i++)
                        if (Level.Game.AccessControl.IPPolicies[i] != "")
                            result $= Level.Game.AccessControl.IPPolicies[i] $ chr(13) $ chr(10); // List IP bans
                }
                else
                    result = "No IP-based bans found";
            }
            Response.SendText(result);
        }
        // Kick and ban a player by name
        else if (InStr(cmd, "admin kickban ") == 0)
        {
            MapName = Mid(cmd, 13);     // Extract player name after "admin kickban "
            while (Left(MapName, 1) == " ") MapName = Mid(MapName, 1); // Trim leading spaces
            while (Right(MapName, 1) == " ") MapName = Left(MapName, Len(MapName) - 1); // Trim trailing spaces
            KickBanPlayer(MapName, result); // Call KickBanPlayer function
            Response.SendText(result);
        }
        // Kick a player by name (no ban)
        else if (InStr(cmd, "admin kick ") == 0)
        {
            MapName = Mid(cmd, 11);     // Extract player name after "admin kick "
            while (Left(MapName, 1) == " ") MapName = Mid(MapName, 1); // Trim leading spaces
            while (Right(MapName, 1) == " ") MapName = Left(MapName, Len(MapName) - 1); // Trim trailing spaces
            bActionTaken = false;
            for (C = Level.ControllerList; C != None; C = C.NextController)
            {
                if (C.bIsPlayer && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.PlayerName ~= MapName)
                {
                    IP = PlayerController(C).GetPlayerNetworkAddress();
                    Log("Kicking player: " $ MapName $ " (" $ IP $ ")");
                    PlayerController(C).Destroy();  // Disconnect player from server
                    bActionTaken = true;
                    break;
                }
            }
            if (bActionTaken)
                Response.SendText("Player " $ MapName $ " kicked");
            else
                Response.SendText("Error: Player " $ MapName $ " not found");
        }
        // Unban a player by name (ID-based only)
        else if (InStr(cmd, "admin unban ") == 0)
        {
            MapName = Mid(cmd, 11);     // Extract player name after "admin unban "
            while (Left(MapName, 1) == " ") MapName = Mid(MapName, 1); // Trim leading spaces
            while (Right(MapName, 1) == " ") MapName = Left(MapName, Len(MapName) - 1); // Trim trailing spaces
            UnbanPlayer(MapName, result); // Call UnbanPlayer function
            Response.SendText(result);
        }
        // Admin commands with additional parameters
        else if (InStr(cmd, "admin ") == 0)
        {
            Param = Mid(cmd, 6);    // Extract parameter after "admin "
            // Restart server on current map
            if (InStr(Param, "servertravel") == 0 && InStr(Param, "?restart") != -1)
            {
                Log("Restarting server with current map: " $ Level.Title);
                Level.ServerTravel(Left(Level, InStr(Level, ".")) $ ".ut2", false); // UT2004 uses .ut2 maps
                Response.SendText("Server restarting on current map: " $ Level.Title);
            }
            // Change server to a new map
            else if (InStr(Param, "servertravel") == 0)
            {
                Log("Server traveling to: " $ Param);
                Level.ServerTravel(Mid(Param, 12), false);
                Response.SendText("Server traveling to: " $ Mid(Param, 12));
            }
            // Set or clear game password
            else if (InStr(Param, "set Engine.AccessControl GamePassword") == 0)
            {
                Param = Mid(Param, 38);     // Extract password (can be empty)
                if (Param == "")
                {
                    Log("Clearing game password");
                    Level.Game.AccessControl.SetGamePassword("");
                    Level.Game.AccessControl.SaveConfig();
                    Response.SendText("Game password cleared");
                }
                else
                {
                    Log("Setting game password to: " $ Param);
                    Level.Game.AccessControl.SetGamePassword(Param);
                    Level.Game.AccessControl.SaveConfig();
                    Response.SendText("Game password set to: " $ Param);
                }
            }
            // Set server name
            else if (InStr(Param, "set Engine.GameReplicationInfo ServerName") == 0)
            {
                Param = Mid(Param, 42);     // Extract server name
                Log("Setting server name to: " $ Param);
                Level.Game.GameReplicationInfo.ServerName = Param;
                Level.Game.SaveConfig();
                Response.SendText("Server name set to: " $ Param);
            }
            // Execute generic console command
            else
            {
                result = Level.ConsoleCommand(Param);
                if (result != "" && result != "0")
                    Response.SendText(result); // Return command output if meaningful
                else
                    Response.SendText("OK: " $ Param); // Acknowledge command execution
            }
        }
        // Non-admin console command execution
        else
        {
            result = Level.ConsoleCommand(cmd);
            if (result != "" && result != "0")
                Response.SendText(result);
            else
                Response.SendText("OK: " $ cmd);
        }
    }
    else
    {
        Response.SendText("Error: No command provided"); // Handle empty command input
    }
}

defaultproperties
{
}