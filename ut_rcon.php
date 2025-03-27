<?php
session_start();

// Initialize session variables with defaults if not set
if (!isset($_SESSION['server_ip'])) $_SESSION['server_ip'] = '127.0.0.1';
if (!isset($_SESSION['port'])) $_SESSION['port'] = '8080';
if (!isset($_SESSION['username'])) $_SESSION['username'] = 'admin';
if (!isset($_SESSION['password'])) $_SESSION['password'] = '';
if (!isset($_SESSION['game_version'])) $_SESSION['game_version'] = 'ut2004';

// Update session variables from POST data if provided
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["update_config"])) {
    $_SESSION['server_ip'] = !empty($_POST["server_ip"]) ? $_POST["server_ip"] : $_SESSION['server_ip'];
    $_SESSION['port'] = !empty($_POST["port"]) ? $_POST["port"] : $_SESSION['port'];
    $_SESSION['password'] = !empty($_POST["password"]) ? $_POST["password"] : $_SESSION['password'];
    $_SESSION['game_version'] = !empty($_POST["game_version"]) ? $_POST["game_version"] : $_SESSION['game_version'];
}

// Assign session variables to local variables for use
$server_ip = $_SESSION['server_ip'];
$port = $_SESSION['port'];
$username = $_SESSION['username'];
$password = $_SESSION['password'];
$game_version = $_SESSION['game_version'];

// Sends an RCON command to the server and returns the response
function send_rcon_command($command) {
    global $server_ip, $port, $username, $password;

    if (empty($server_ip) || empty($port)) {
        return "Error: Server configuration not set";
    }

    // Construct the URL for the RCON request
    $url = "http://{$server_ip}:{$port}/rcon/?cmd=" . urlencode($command);
    file_put_contents("php_debug.log", "Sending URL: $url\n", FILE_APPEND);

    // Initialize cURL session
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERPWD, "{$username}:{$password}");
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_MAXREDIRS, 10);

    // Execute request and log response
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    file_put_contents("php_debug.log", "Response: '$response'\nHTTP Code: $http_code\n", FILE_APPEND);
    curl_close($ch);

    return $http_code === 200 ? $response : "Error: HTTP $http_code";
}

// Process RCON command from form submission
$response = "";
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["command"])) {
    $cmd = $_POST["command"];

    // Handle commands requiring additional input
    switch ($cmd) {
        case "admin kick":
        case "admin kickban":
            $player = isset($_POST["player"]) ? trim($_POST["player"]) : "";
            if ($player === "") {
                $response = "Error: Player name required";
                $cmd = "";
            } else {
                $cmd .= " " . $player;
            }
            break;

        case "admin unban":
            if ($game_version === "ut2004") {
                $player = isset($_POST["player"]) ? trim($_POST["player"]) : "";
                if ($player === "") {
                    $response = "Error: Player name required";
                    $cmd = "";
                } else {
                    $cmd .= " " . $player;
                }
            } else { // UT99
                $ip = isset($_POST["ip"]) ? trim($_POST["ip"]) : "";
                if ($ip === "") {
                    $response = "Error: IP address required";
                    $cmd = "";
                } else {
                    $cmd .= " " . $ip;
                }
            }
            break;

        case "say":
            $message = isset($_POST["message"]) ? trim($_POST["message"]) : "";
            if ($message === "") {
                $response = "Error: Message required";
                $cmd = "";
            } else {
                $cmd .= " " . $message;
            }
            break;

        case "admin servertravel":
            $map = isset($_POST["map"]) ? trim($_POST["map"]) : "";
            $gametype = isset($_POST["gametype"]) ? trim($_POST["gametype"]) : "";
            if ($map === "") {
                $response = "Error: Map name required";
                $cmd = "";
            } else {
                $cmd .= " " . $map;
                if ($gametype !== "") {
                    $cmd .= "?Game=" . $gametype;
                }
            }
            break;

        case "admin set GamePassword":
            $gamepass = isset($_POST["gamepass"]) ? trim($_POST["gamepass"]) : "";
            $cmd = $game_version === "ut2004" 
                ? "admin set Engine.AccessControl GamePassword " . $gamepass 
                : "admin set Engine.GameInfo GamePassword " . $gamepass;
            break;

        case "admin set Engine.GameReplicationInfo ServerName":
            $servername = isset($_POST["servername"]) ? trim($_POST["servername"]) : "";
            if ($servername === "") {
                $response = "Error: Server name required";
                $cmd = "";
            } else {
                $cmd .= " " . $servername;
            }
            break;

        case "admin bans":
            // No additional parameters needed
            break;
    }

    // Send command if valid and no error occurred
    if ($cmd !== "" && $response === "") {
        $response = send_rcon_command($cmd);
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Unreal Tournament Rcon Control Panel</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px auto;
            max-width: 800px;
            background-color: #f4f4f9;
            color: #333;
        }
        h1 {
            background: #4CAF50;
            color: white;
            padding: 10px;
            text-align: center;
            border-radius: 5px;
        }
        h2 {
            margin-top: 0;
        }
        .response {
            background: #fffbe6;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border: 1px solid #ffe58f;
        }
        .container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .column {
            flex: 1;
            min-width: 300px;
            background: white;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
        }
        label {
            font-weight: bold;
            display: block;
            margin-bottom: 5px;
        }
        input, select, button {
            width: 100%;
            margin-bottom: 10px;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box;
        }
        button {
            background: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }
        button:hover {
            background: #45a049;
        }
    </style>
</head>
<body>
    <h1>Unreal Tournament Rcon Control Panel (<?php echo $game_version === 'ut2004' ? 'UT2004' : 'UT99'; ?>)</h1>

    <?php if (!empty($response)): ?>
        <div class="response">
            <strong>Response:</strong><br>
            <?php echo nl2br(htmlspecialchars($response)); ?>
        </div>
    <?php endif; ?>

    <!-- Server Configuration Form -->
    <form method="post" action="">
        <h2>Server Configuration</h2>
        <label for="server_ip">Server IP:</label>
        <input type="text" id="server_ip" name="server_ip" value="<?php echo htmlspecialchars($server_ip); ?>" required>
        <label for="web admin port">Port:</label>
        <input type="text" id="port" name="port" value="<?php echo htmlspecialchars($port); ?>" required>
        <label for="password">Password:</label>
        <input type="password" id="password" name="password" value="<?php echo htmlspecialchars($password); ?>" required>
        <label for="game_version">Game Version:</label>
        <select id="game_version" name="game_version">
            <option value="ut2004" <?php echo $game_version === 'ut2004' ? 'selected' : ''; ?>>UT2004</option>
            <option value="ut99" <?php echo $game_version === 'ut99' ? 'selected' : ''; ?>>UT99</option>
        </select>
        <button type="submit" name="update_config">Save Configuration</button>
    </form>

    <!-- Control Panel -->
    <div class="container">
        <!-- Column 1: Player Management -->
        <div class="column">
            <!-- Say Message -->
            <form method="post" action="">
                <label>Say:</label>
                <input type="text" name="message" placeholder="Enter message" required>
                <input type="hidden" name="command" value="say">
                <button type="submit">Send Message</button>
            </form>

            <!-- Kick Player -->
            <form method="post" action="">
                <label>Kick Player:</label>
                <input type="text" name="player" placeholder="Player name" required>
                <input type="hidden" name="command" value="admin kick">
                <button type="submit">Kick</button>
            </form>

            <!-- Kickban Player -->
            <form method="post" action="">
                <label>Kickban Player:</label>
                <input type="text" name="player" placeholder="Player name" required>
                <input type="hidden" name="command" value="admin kickban">
                <button type="submit">Kickban</button>
            </form>

            <?php if ($game_version === 'ut2004'): ?>
                <!-- Unban Player (UT2004) -->
                <form method="post" action="">
                    <label>Unban Player:</label>
                    <input type="text" name="player" placeholder="Player name" required>
                    <input type="hidden" name="command" value="admin unban">
                    <button type="submit">Unban</button>
                </form>
            <?php else: ?>
                <!-- Unban IP (UT99) -->
                <form method="post" action="">
                    <label>Unban IP:</label>
                    <input type="text" name="ip" placeholder="e.g., 192.168.0.10" required>
                    <input type="hidden" name="command" value="admin unban">
                    <button type="submit">Unban IP</button>
                </form>
            <?php endif; ?>
        </div>

        <!-- Column 2: Server Management -->
        <div class="column">
            <!-- List Players -->
            <form method="post" action="">
                <input type="hidden" name="command" value="admin players">
                <button type="submit">List Players</button>
            </form>

            <!-- List Bans -->
            <form method="post" action="">
                <input type="hidden" name="command" value="admin bans">
                <button type="submit">List Bans</button>
            </form>

            <!-- Restart Server -->
            <form method="post" action="">
                <input type="hidden" name="command" value="admin servertravel ?restart">
                <button type="submit">Restart Server</button>
            </form>

            <!-- Change Map/Game Type -->
            <form method="post" action="">
                <label>Change Map:</label>
                <input type="text" name="map" placeholder="e.g., DM-Rankin.ut2 or DM-Morpheus" required>
                <input type="text" name="gametype" placeholder="e.g., xGame.DM or Botpack.DeathMatchPlus (optional)">
                <input type="hidden" name="command" value="admin servertravel">
                <button type="submit">Change Map</button>
            </form>

            <!-- Set Game Password -->
            <form method="post" action="">
                <label>Set Game Password:</label>
                <input type="text" name="gamepass" placeholder="Enter password (leave blank to clear)">
                <input type="hidden" name="command" value="admin set GamePassword">
                <button type="submit">Set Password</button>
            </form>

            <!-- Set Server Name -->
            <form method="post" action="">
                <label>Set Server Name:</label>
                <input type="text" name="servername" placeholder="Enter server name" required>
                <input type="hidden" name="command" value="admin set Engine.GameReplicationInfo ServerName">
                <button type="submit">Set Server Name</button>
            </form>
        </div>
    </div>
</body>
</html>