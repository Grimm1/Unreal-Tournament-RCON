Below is the README converted to README.md format with some "prettying up" applied—using Markdown enhancements like badges, emojis, code block highlighting, and a more polished layout. It’s still functional for GitHub and retains all the original content with a cleaner, more visually appealing style.

* * *

RconWebApp for Unreal Tournament

License UT99 UT2004

 ![📝](https://abs-0.twimg.com/emoji/v2/svg/1f4dd.svg "Memo") Description

RconWebApp is a custom UnrealScript web application crafted by K6\_Grimm to deliver a modern, HTTPS-compatible remote control (RCON) interface for Unreal Tournament servers—supporting both UT99 and UT2004. Say goodbye to the clunky, outdated built-in web admin interfaces! This project empowers server admins to manage their games via HTTP requests from a browser or a custom front-end, leveraging Unreal Tournament's web server framework for a lightweight, secure, and flexible solution.

Included are two UnrealScript files (RconWebApp.uc for UT99 and UT2004) and a PHP script as sample code. The PHP file is a starting point to showcase RCON integration, helping developers jumpstart their own projects or tailor it to their needs. With version-specific features like IP-based bans for UT99 and ID-based bans for UT2004, RconWebApp bridges classic gaming with modern web tech.

* * *

 ![✨](https://abs-0.twimg.com/emoji/v2/svg/2728.svg "Sparkles") Features

*   Player Management:
    
    *    ![👢](https://abs-0.twimg.com/emoji/v2/svg/1f462.svg "Woman’s boots") Kick players by name (UT99 & UT2004).
        
    *    ![🚫](https://abs-0.twimg.com/emoji/v2/svg/1f6ab.svg "No entry sign") Kick and ban players (UT99: IP-based, UT2004: ID-based).
        
    *    ![✅](https://abs-0.twimg.com/emoji/v2/svg/2705.svg "White heavy check mark") Unban players (UT99: by IP, UT2004: by name for ID bans).
        
    *    ![📋](https://abs-0.twimg.com/emoji/v2/svg/1f4cb.svg "Clipboard") List connected players (name, ping, IP).
        
*   Server Management:
    
    *    ![ℹ️](https://abs-0.twimg.com/emoji/v2/svg/2139.svg "Information source") Show server info (name, map, player count).
        
    *    ![📜](https://abs-0.twimg.com/emoji/v2/svg/1f4dc.svg "Scroll") List bans (UT99: IPs, UT2004: IDs or IPs).
        
    *    ![🔄](https://abs-0.twimg.com/emoji/v2/svg/1f504.svg "Anticlockwise downwards and upwards open circle arrows") Restart the server on the current map.
        
    *    ![🗺️](https://abs-0.twimg.com/emoji/v2/svg/1f5fa.svg "World map") Change maps with optional gametype.
        
    *    ![🔒](https://abs-0.twimg.com/emoji/v2/svg/1f512.svg "Lock") Set/clear game password.
        
    *    ![🏷️](https://abs-0.twimg.com/emoji/v2/svg/1f3f7.svg "Label") Set server name.
        
*   Extras:
    
    *    ![💬](https://abs-0.twimg.com/emoji/v2/svg/1f4ac.svg "Speech balloon") Send "say" messages to all players.
        
    *    ![⚙️](https://abs-0.twimg.com/emoji/v2/svg/2699.svg "Gear") Run console commands with admin privileges.
        
*   Cross-Version Support:
    
    *   Tailored for UT99 (.unr maps, Pawn-based) and UT2004 (.ut2 maps, Controller-based).
        
    *   Single .ini config for both.
        
*   Security:
    
    *    ![🔐](https://abs-0.twimg.com/emoji/v2/svg/1f510.svg "Closed lock with key") Password-protected via HTTP Basic Auth.
        
    *    ![📝](https://abs-0.twimg.com/emoji/v2/svg/1f4dd.svg "Memo") Logs actions for auditing.
        
*   PHP Sample Code:
    
    *    ![🛠️](https://abs-0.twimg.com/emoji/v2/svg/1f6e0.svg "Hammer and wrench") A web interface sample to inspire custom projects.
        

* * *

 ![🛠️](https://abs-0.twimg.com/emoji/v2/svg/1f6e0.svg "Hammer and wrench") Compile Instructions for the .uc File

To use RconWebApp, compile the UnrealScript (.uc) file into a .u package for your server.

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

 ![📦](https://abs-0.twimg.com/emoji/v2/svg/1f4e6.svg "Package") Install Instructions for .uc and .ini

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

 ![⚙️](https://abs-0.twimg.com/emoji/v2/svg/2699.svg "Gear") Configuration Example

RconWebApp.ini

ini

    [RconWebApp.RconWebApp]
    AdminPassword=MySecurePass123

*   Match this password in your PHP sample or browser.
    

* * *

 ![🚀](https://abs-0.twimg.com/emoji/v2/svg/1f680.svg "Rocket") Usage

*   Browser: Append ?cmd=<command> (e.g., http://<server\_ip>:<port>/rcon/?cmd=admin%20players).
    
*   PHP Sample: Use the script as a starting point for your web interface.
    

* * *

 ![📌](https://abs-0.twimg.com/emoji/v2/svg/1f4cc.svg "Pushpin") Notes

*   Open ListenPort in your firewall.
    
*   UT2004 IP unbanning requires manual .ini edits.
    
*   PHP logs to php\_debug.log for debugging.
    
*   The PHP file is sample code—adapt it for your needs!
    

* * *

This README.md is now GitHub-ready with a polished look, using emojis for visual flair, badges for quick info, and highlighted code blocks for clarity. Let me know if you want more adjustments!
