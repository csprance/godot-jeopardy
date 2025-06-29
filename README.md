# 🎯 Godot Jeopardy

A fully-featured multiplayer Jeopardy game built with Godot 4.x. Host trivia nights, play with friends, or practice solo with this complete implementation of the classic game show format.

![Godot Version](https://img.shields.io/badge/Godot-4.4%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)

## ✨ Features

### 🎮 Game Modes
- **Single Player**: Practice and learn with solo gameplay
- **Multiplayer**: Host games for 2-8 players over local network
- **Cross-Platform**: Play across Windows, Linux, and macOS

### 🎯 Core Gameplay
- **Classic Jeopardy Format**: Categories, point values, Daily Doubles
- **Buzzer System**: First-to-buzz wins the right to answer
- **Real-time Scoring**: Live score updates for all players
- **Question Categories**: Fully customizable question sets
- **Host Controls**: Approve/deny answers, manage game flow

### 🔧 Technical Features
- **Godot 4.4+ Compatible**: Built with latest Godot features
- **Networking**: Robust multiplayer using Godot's built-in networking
- **Autoload Architecture**: Clean separation of concerns
- **VSCode Integration**: Full debugging support with Godot Tools
- **JSON Data Format**: Easy question import/export

## 🚀 Quick Start

### Prerequisites
- **Godot Engine 4.4+** - [Download here](https://godotengine.org/download)
- **Git** (optional) - For cloning the repository

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/csprance/godot-jeopardy.git
   cd godot-jeopardy
   ```

2. **Open in Godot**
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`
   - Click "Import & Edit"

3. **Run the game**
   - Press `F5` or click the "Play" button
   - Select the main scene when prompted

## 🎲 How to Play

### Single Player
1. **Launch the game**
2. **Click "Host Game"** on the main menu
3. **Click "Start Game"** in the lobby (no need to wait for others)
4. **Select questions** by clicking on point values
5. **Answer questions** and see your score grow!

### Multiplayer (Host)
1. **Click "Host Game"** on the main menu
2. **Share your IP address** shown in the lobby with other players
3. **Wait for players to join** (or start with fewer)
4. **Click "Start Game"** when ready
5. **Manage the game** as host - approve/deny answers

### Multiplayer (Join)
1. **Get the host's IP address**
2. **Enter IP** in the "Server IP" field
3. **Click "Join Game"**
4. **Wait in lobby** until host starts the game
5. **Use the "BUZZ!" button** to answer questions first

## 📋 Game Controls

| Action | Control |
|--------|---------|
| Buzz In | Click "BUZZ!" button |
| Submit Answer | Type answer and press Enter or click "Submit" |
| Host: Mark Correct | Click "Correct" button |
| Host: Mark Wrong | Click "Wrong" button |
| Close Question | Click "Close" button |

## 🛠️ Development

### Architecture
The game uses a clean autoload-based architecture:

- **NetworkManager**: Handles all multiplayer networking
- **GameState**: Manages game logic, scoring, and state
- **UIManager**: Coordinates UI transitions and updates

### Project Structure
```
godot-jeopardy/
├── scenes/
│   ├── main/           # Main game manager scene
│   └── ui/             # UI scenes (menu, lobby, game board)
├── scripts/
│   ├── data/           # Data classes (GameData, BoardGenerator)
│   ├── networking/     # Network and game state management
│   └── ui/             # UI controllers
├── .vscode/            # VSCode debug configuration
├── sample_game.json    # Example question set
└── game_schema.json    # JSON schema for question format
```

### VSCode Development
This project includes full VSCode integration:

1. **Install Godot Tools extension** (`geequlim.godot-tools`)
2. **Open project in VSCode**
3. **Press F5** to launch with debugging
4. **Use compound launch** "Launch Two Clients" for multiplayer testing

See [.vscode/README.md](.vscode/README.md) for detailed setup instructions.

## 📝 Creating Custom Questions

Questions are stored in JSON format. See `sample_game.json` for an example:

```json
{
  "title": "My Custom Game",
  "description": "Custom trivia questions",
  "questions": [
    {
      "category": "SCIENCE",
      "question": "This element has the chemical symbol 'O'",
      "answer": "What is Oxygen?",
      "point_range": {
        "min": 200,
        "max": 400
      }
    }
  ],
  "board_config": {
    "categories_count": 6,
    "questions_per_category": 5,
    "point_values": [200, 400, 600, 800, 1000],
    "daily_doubles_count": 2
  }
}
```

### Question Format
- **category**: Question category name
- **question**: The question text (what contestants see)
- **answer**: The correct answer (usually in "What is..." format)
- **point_range**: Min/max point values for this question difficulty

## 🔧 Configuration

### Network Settings
- **Default Port**: 8080 (configurable in NetworkManager.gd)
- **Max Players**: 8 (configurable in NetworkManager.gd)
- **Connection Type**: ENet (reliable UDP)

### Game Settings
- **Board Size**: 6 categories × 5 questions (configurable via JSON)
- **Point Values**: 200, 400, 600, 800, 1000 (configurable)
- **Daily Doubles**: 2 per game (configurable)
- **Question Timer**: 30 seconds (configurable in GameBoardController.gd)

## 🐛 Troubleshooting

### Common Issues

**"Network manager not available"**
- Ensure NetworkManager is properly set as autoload
- Check project.godot autoload configuration

**Cannot connect to host**
- Verify IP address is correct
- Check firewall settings (allow Godot through Windows Firewall)
- Ensure host and client are on same network

**Questions not loading**
- Check JSON format against schema in game_schema.json
- Verify file path in MainMenuController.gd
- Look for parsing errors in Godot's output console

**Scene loading errors**
- Ensure all scripts compile without errors
- Check that all required nodes exist in scene files
- Verify SubResource references are correct

### Debug Mode
Use VSCode debug configuration for detailed debugging:
1. Set breakpoints in scripts
2. Launch with F5
3. Monitor network traffic and game state changes

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (single + multiplayer)
5. Submit a pull request

### Code Style
- Follow GDScript style guide
- Use meaningful variable names
- Comment complex logic
- Test multiplayer scenarios

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Godot Engine](https://godotengine.org/)
- Inspired by the classic Jeopardy! game show
- Uses Godot's built-in networking for multiplayer functionality

---

**Made with ❤️ and Godot**

For support or questions, please open an issue on GitHub.