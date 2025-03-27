* * *

RconWebApp for Unreal Tournament

License UT99 UT2004

<img src="https://abs-0.twimg.com/emoji/v2/svg/1f4dd.svg" alt="Memo" width="20" height="20"> Description

RconWebApp is a custom UnrealScript web application crafted by K6\_Grimm to deliver a modern, HTTPS-compatible remote control (RCON) interface for Unreal Tournament servers—supporting both UT99 and UT2004. Say goodbye to the clunky, outdated built-in web admin interfaces! This project empowers server admins to manage their games via HTTP requests from a browser or a custom front-end, leveraging Unreal Tournament's web server framework for a lightweight, secure, and flexible solution.

Included are two UnrealScript files (RconWebApp.uc for UT99 and UT2004) and a PHP script as sample code. The PHP file is a starting point to showcase RCON integration, helping developers jumpstart their own projects or tailor it to their needs. With version-specific features like IP-based bans for UT99 and ID-based bans for UT2004, RconWebApp bridges classic gaming with modern web tech.

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/2728.svg" alt="Sparkles" width="20" height="20"> Features

*   Player Management:
    
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f462.svg" alt="Woman’s boots" width="20" height="20"> Kick players by name (UT99 & UT2004).
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f6ab.svg" alt="No entry sign" width="20" height="20"> Kick and ban players (UT99: IP-based, UT2004: ID-based).
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/2705.svg" alt="White heavy check mark" width="20" height="20"> Unban players (UT99: by IP, UT2004: by name for ID bans).
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f4cb.svg" alt="Clipboard" width="20" height="20"> List connected players (name, ping, IP).
        
*   Server Management:
    
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/2139.svg" alt="Information source" width="20" height="20"> Show server info (name, map, player count).
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f4dc.svg" alt="Scroll" width="20" height="20"> List bans (UT99: IPs, UT2004: IDs or IPs).
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f504.svg" alt="Anticlockwise downwards and upwards open circle arrows" width="20" height="20"> Restart the server on the current map.
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f5fa.svg" alt="World map" width="20" height="20"> Change maps with optional gametype.
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f512.svg" alt="Lock" width="20" height="20"> Set/clear game password.
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f3f7.svg" alt="Label" width="20" height="20"> Set server name.
        
*   Extras:
    
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f4ac.svg" alt="Speech balloon" width="20" height="20"> Send "say" messages to all players.
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/2699.svg" alt="Gear" width="20" height="20"> Run console commands with admin privileges.
        
*   Cross-Version Support:
    
    *   Tailored for UT99 (.unr maps, Pawn-based) and UT2004 (.ut2 maps, Controller-based).
        
    *   Single .ini config for both.
        
*   Security:
    
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f510.svg" alt="Closed lock with key" width="20" height="20"> Password-protected via HTTP Basic Auth.
        
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f4dd.svg" alt="Memo" width="20" height="20"> Logs actions for auditing.
        
*   PHP Sample Code:
    
    *    <img src="https://abs-0.twimg.com/emoji/v2/svg/1f6e0.svg" alt="Hammer and wrench" width="20" height="20"> A web interface sample to inspire custom projects.
        

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/1f6e0.svg" alt="Hammer and wrench" width="20" height="20"> Compile Instructions for the .uc File

To use RconWebApp, compile the UnrealScript (.uc) file into a .u package for your server.

IF YOU DO NOT WANT TO COMPILE THE .U FILE YOURSELF USE THE PRECOMPILED .U FILES FROM THIS REPOSITORY AND SKIP TO THE NEXT STEP!

Prerequisites

*   Unreal Tournament dev environment (UCC compiler).
    
*   Access to the server's System directory.
    
*   RconWebApp.uc for your version (UT99 or UT2004).
    

Steps

1.  Prepare the Script:
    
    *   Place RconWebApp.uc in RconWebApp/Classes/.
        
2.  Edit RconWebApp.ini (Optional):
    
    *   Set AdminPassword pre-compilation (see below).
        
3.  Compile:
    
    *   In the System directory, run:
        
        *   UT99:
            
            bash
            
                ucc make -mod=RconWebApp
            
        *   UT2004:
            
            bash
            
                ucc make -mod=RconWebApp
            
    *   Outputs RconWebApp.u.
        
4.  Verify:
    
    *   Check ucc.log for errors. Success = RconWebApp.u generated.
        

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/1f4e6.svg" alt="Package" width="20" height="20"> Install Instructions for .uc and .ini

Install the .u File

1.  Copy:
    
    *   Move RconWebApp.u to:
        
        *   UT99: UnrealTournament/System/
            
        *   UT2004: UT2004/System/
            
2.  Configure RconWebApp.ini:
    
    *   In the System directory, create/edit RconWebApp.ini:
        
        ini
        
            [RconWebApp.RconWebApp]
            AdminPassword=yourstrongpasswordhere
        
    *   Use a secure password for HTTP auth.
        

Modify Unreal Tournament .ini Files

Update the web server config:

UT99 (UnrealTournament.ini)

*   Replace \[UWeb.WebServer\] with:
    
    ini
    
        [UWeb.WebServer]
        Applications[0]=UTServerAdmin.UTServerAdmin
        ApplicationPaths[0]=/ServerAdmin
        Applications[1]=UTServerAdmin.UTImageServer
        ApplicationPaths[1]=/images
        Applications[2]=RconWebApp.RconWebApp
        ApplicationPaths[2]=/rcon
        DefaultApplication=0
        ListenPort=8076
        bEnabled=True
    
*   Notes:
    
    *   ListenPort (e.g., 8076) must be unique.
        
    *   Keeps default admin/image servers, adds /rcon.
        

UT2004 (UT2004.ini)

*   Replace \[UWeb.WebServer\] with:
    
    ini
    
        [UWeb.WebServer]
        Applications[0]=RconWebApp.RconWebApp
        ApplicationPaths[0]=/rcon
        bEnabled=True
        ListenPort=8800
    
*   Notes:
    
    *   Removes other apps for simplicity.
        
    *   ListenPort (e.g., 8800) must be unique.
        

Final Steps

1.  Restart Server:
    
    *   Restart UT to apply changes (bEnabled=True).
        
2.  Test Access:
    
    *   Visit http://<server\_ip>:<port>/rcon/ (e.g., http://127.0.0.1:8076/rcon/).
        
    *   Use admin and your AdminPassword.
        
3.  Use PHP Sample Code (Optional):
    
    *   The PHP script is a sample to demo RCON integration.
        
    *   Deploy on a web server (e.g., Apache + PHP).
        
    *   Configure with your server’s IP, port, and password.
        
    *   Use it as a base for your custom projects.
        

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/2699.svg" alt="Gear" width="20" height="20"> Configuration Example

RconWebApp.ini

ini

    [RconWebApp.RconWebApp]
    AdminPassword=MySecurePass123

*   Match this password in your PHP sample or browser.
    

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/1f680.svg" alt="Rocket" width="20" height="20"> Usage

*   Browser: Append ?cmd=<command> (e.g., http://<server\_ip>:<port>/rcon/?cmd=admin%20players).
    
*   PHP Sample: Use the script as a starting point for your web interface.
    

* * *

<img src="https://abs-0.twimg.com/emoji/v2/svg/1f4cc.svg" alt="Pushpin" width="20" height="20"> Notes

*   Open ListenPort in your firewall.
    
*   UT2004 IP unbanning requires manual .ini edits.
    
*   PHP logs to php\_debug.log for debugging.
    
*   The PHP file is sample code—adapt it for your needs!
    

* * *

