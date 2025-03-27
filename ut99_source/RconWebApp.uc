class RconWebApp expands WebApplication config(RconWebApp);

// Rcon web code by K6_Grimm for UT99 remote control without using the old web interface
// This class enables server administration from modern HTTPS websites, bypassing the outdated UT99 web admin interface.
// It supports commands like kicking, banning, unbanning, server info, player lists, and more, with a focus on IP-based bans.

// Admin password for authentication, stored in the config file (e.g., RconWebApp.ini)
var config string AdminPassword;

// Main query handler for web requests, processes all incoming commands
function Query(WebRequest Request, WebResponse Response)
{
    local string cmd, result, MapName;  // Command string, result text, and temporary name storage
    local Pawn P;                       // Iterator for pawn list (players in UT99 are pawns)
    local bool bActionTaken;            // Tracks if an action (e.g., kick, ban) was successful
    local string IP, Param;             // Stores IP address and command parameter
    local int i, ColonPos;              // Loop counter and colon position for IP parsing

    // Authentication check: ensures the provided password matches the configured AdminPassword (case-insensitive)
    if (AdminPassword == "" || Caps(Request.Password) != Caps(AdminPassword))
    {
        Response.FailAuthentication("UT Rcon"); // Fails if password is empty or incorrect
        return;
    }

    cmd = Request.GetVariable("cmd", "");   // Retrieve the command from the web request
    while (Left(cmd, 1) == " ") cmd = Mid(cmd, 1); // Trim leading spaces from command
    while (Right(cmd, 1) == " ") cmd = Left(cmd, Len(cmd) - 1); // Trim trailing spaces from command

    if (cmd != "")
    {
        // Server info command: returns basic server details
        if (cmd ~= "serverinfo" || cmd ~= "admin serverinfo")
        {
            result = "Server: " $ Level.Game.GameName $ 
                     ", Map: " $ Level.Title $ 
                     ", Players: " $ string(Level.Game.NumPlayers) $ "/" $ string(Level.Game.MaxPlayers);
            Response.SendText(result); // Sends server name, map, and player count
        }
        // Kick a player by name
        else if (Left(cmd, 11) ~= "admin kick ")
        {
            MapName = Mid(cmd, 11); // Extract player name after "admin kick "
            while (Left(MapName, 1) == " ") MapName = Mid(MapName, 1); // Trim leading spaces
            while (Right(MapName, 1) == " ") MapName = Left(MapName, Len(MapName) - 1); // Trim trailing spaces
            bActionTaken = false;
            // Iterate through all pawns (players) in the level
            for (P = Level.PawnList; P != None; P = P.NextPawn)
            {
                // Check if pawn is a valid, active player with replication info
                if (P.bIsPlayer && !P.bDeleteMe && PlayerPawn(P) != None && P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.PlayerName ~= MapName)
                {
                    Log("Kicking player: " $ MapName $ " (" $ PlayerPawn(P).GetPlayerNetworkAddress() $ ")");
                    P.Destroy(); // Disconnects the player from the server
                    Level.Game.SaveConfig(); // Saves any config changes (though not strictly needed here)
                    bActionTaken = true;
                    break;
                }
            }
            if (bActionTaken)
                Response.SendText("Player " $ MapName $ " kicked");
            else
                Response.SendText("Error: Player " $ MapName $ " not found");
        }
        // Kick and ban a player by name, adding their IP to the ban list
        else if (InStr(cmd, "admin kickban ") == 0)
        {
            MapName = Mid(cmd, 13); // Extract player name after "admin kickban "
            while (Left(MapName, 1) == " ") MapName = Mid(MapName, 1); // Trim leading spaces
            while (Right(MapName, 1) == " ") MapName = Left(MapName, Len(MapName) - 1); // Trim trailing spaces
            bActionTaken = false;
            for (P = Level.PawnList; P != None; P = P.NextPawn)
            {
                if (P.bIsPlayer && !P.bDeleteMe && PlayerPawn(P) != None && P.PlayerReplicationInfo != None)
                {
                    if (P.PlayerReplicationInfo.PlayerName ~= MapName)
                    {
                        IP = PlayerPawn(P).GetPlayerNetworkAddress(); // Get player's IP:port
                        ColonPos = InStr(IP, ":"); // Find port separator
                        if (ColonPos != -1)
                            IP = Left(IP, ColonPos); // Strip port, keep only IP
                        bActionTaken = false;
                        // Check if IP is already banned
                        for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
                        {
                            if (InStr(Level.Game.IPPolicies[i], "DENY," $ IP) != -1)
                            {
                                bActionTaken = true; // IP already banned
                                break;
                            }
                        }
                        // If not banned, add to the first empty IPPolicies slot
                        if (!bActionTaken)
                        {
                            for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
                            {
                                if (Level.Game.IPPolicies[i] == "")
                                {
                                    Level.Game.IPPolicies[i] = "DENY," $ IP;
                                    bActionTaken = true;
                                    Log("Added ban for IP: " $ IP);
                                    break;
                                }
                            }
                            if (bActionTaken)
                                Level.Game.SaveConfig(); // Save the updated ban list
                        }
                        Log("Kicking and banning player: " $ MapName $ " (" $ IP $ ")");
                        P.Destroy(); // Kick the player
                        Response.SendText("Player " $ MapName $ " kicked and banned");
                        return;
                    }
                }
            }
            Response.SendText("Error: Player " $ MapName $ " not found");
        }
        // Ban a player's IP without kicking (if they’re online)
        else if (Left(cmd, 9) ~= "admin ban ")
        {
            MapName = Mid(cmd, 9); // Extract player name after "admin ban "
            bActionTaken = false;
            for (P = Level.PawnList; P != None; P = P.NextPawn)
            {
                if (P.bIsPlayer && !P.bDeleteMe && PlayerPawn(P) != None && P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.PlayerName ~= MapName)
                {
                    IP = PlayerPawn(P).GetPlayerNetworkAddress();
                    ColonPos = InStr(IP, ":");
                    if (ColonPos != -1)
                        IP = Left(IP, ColonPos); // Strip port from IP
                    // Check if IP is already banned
                    for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
                    {
                        if (InStr(Level.Game.IPPolicies[i], "DENY," $ IP) != -1)
                        {
                            bActionTaken = true;
                            break;
                        }
                    }
                    // Add IP to ban list if not already banned
                    if (!bActionTaken)
                    {
                        for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
                        {
                            if (Level.Game.IPPolicies[i] == "")
                            {
                                Level.Game.IPPolicies[i] = "DENY," $ IP;
                                bActionTaken = true;
                                Log("Added ban for IP: " $ IP);
                                break;
                            }
                        }
                        if (bActionTaken)
                            Level.Game.SaveConfig();
                    }
                    Response.SendText("IP banned for player " $ MapName);
                    return;
                }
            }
            Response.SendText("Error: Player " $ MapName $ " not found");
        }
        // List all connected players with details
        else if (cmd ~= "admin players")
        {
            result = "Players:\n";
            for (P = Level.PawnList; P != None; P = P.NextPawn)
            {
                if (P.bIsPlayer && !P.bDeleteMe && P.PlayerReplicationInfo != None)
                {
                    result $= P.PlayerReplicationInfo.PlayerName $ " (Ping: " $ P.PlayerReplicationInfo.Ping $ ", IP: " $ PlayerPawn(P).GetPlayerNetworkAddress() $ ")\n";
                }
            }
            if (Len(result) > 9) // Check if any players were listed
                Response.SendText(result);
            else
                Response.SendText("No players connected");
        }
        // List all banned IPs
        else if (cmd ~= "admin bans")
        {
            result = "Banned IPs:" $ chr(13) $ chr(10); // Use explicit newline characters for web response
            for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
            {
                if (Left(Level.Game.IPPolicies[i], 5) ~= "DENY," && Level.Game.IPPolicies[i] != "")
                {
                    result $= Mid(Level.Game.IPPolicies[i], 5) $ chr(13) $ chr(10); // List each banned IP
                }
            }
            if (Len(result) > 11) // Check if any bans exist
                Response.SendText(result);
            else
                Response.SendText("No IPs are currently banned");
        }
        // Unban an IP address
        else if (InStr(cmd, "admin unban ") == 0)
        {
            IP = Mid(cmd, 11); // Extract IP after "admin unban "
            while (Left(IP, 1) == " ") IP = Mid(IP, 1); // Trim leading spaces
            while (Right(IP, 1) == " ") IP = Left(IP, Len(IP) - 1); // Trim trailing spaces
            bActionTaken = false;
            for (i = 0; i < ArrayCount(Level.Game.IPPolicies); i++)
            {
                if (InStr(Level.Game.IPPolicies[i], "DENY," $ IP) != -1)
                {
                    Log("Removing ban for IP: " $ IP);
                    Level.Game.IPPolicies[i] = ""; // Clear the ban entry
                    bActionTaken = true;
                    break;
                }
            }
            if (bActionTaken)
            {
                Level.Game.SaveConfig(); // Save updated config
                Response.SendText("IP " $ IP $ " unbanned");
            }
            else
            {
                Response.SendText("Error: IP " $ IP $ " not found in ban list");
            }
        }
        // Admin commands with additional parameters
        else if (Left(cmd, 6) ~= "admin ")
        {
            Param = Mid(cmd, 6); // Extract command after "admin "
            // Restart server on current map
            if (Left(Param, 11) ~= "servertravel" && InStr(Param, "?restart") != -1)
            {
                Log("Restarting server with current map: " $ Level.Title);
                Level.ServerTravel(Left(Level, InStr(Level, ".")) $ ".unr", false); // UT99 uses .unr maps
                Response.SendText("Server restarting on current map: " $ Level.Title);
            }
            // Change server to a new map
            else if (Left(Param, 11) ~= "servertravel")
            {
                Log("Server traveling to: " $ Param);
                Level.ServerTravel(Mid(Param, 12), false);
                Response.SendText("Server traveling to: " $ Mid(Param, 12));
            }
            // Set or clear game password
            else if (Left(Param, 22) ~= "set Engine.GameInfo GamePassword")
            {
                Param = Mid(Param, 23); // Extract password (can be empty)
                if (Param == "")
                {
                    Log("Clearing game password");
                    Level.ConsoleCommand("set Engine.GameInfo GamePassword \"\"");
                    Level.Game.SaveConfig();
                    Response.SendText("Game password cleared");
                }
                else
                {
                    Log("Setting game password to: " $ Param);
                    Level.ConsoleCommand("set Engine.GameInfo GamePassword " $ Param);
                    Level.Game.SaveConfig();
                    Response.SendText("Game password set to: " $ Param);
                }
            }
            // Set server name
            else if (Left(Param, 31) ~= "set Engine.GameReplicationInfo ServerName")
            {
                Param = Mid(Param, 32);
                Log("Setting server name to: " $ Param);
                Level.ConsoleCommand("set Engine.GameReplicationInfo ServerName " $ Param);
                Level.Game.GameReplicationInfo.SaveConfig();
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
