# Godot Jeopardy Game - Design Document

## Overview
A multiplayer web-based Jeopardy game built in Godot 4.4 that allows players to join via IP address, compete in real-time, and use custom game data loaded from JSON files.

## Core Features
- **Web-based multiplayer**: Host/join games via IP address
- **Real-time buzzer system**: First-to-buzz gets to answer
- **Custom game data**: Load questions/answers from JSON files
- **Timer system**: Countdown timers for questions and buzzing
- **Score tracking**: Individual player scores with point values
- **Screen sharing friendly**: Clean interface for streaming/sharing

## Architecture

### Networking
- **Protocol**: Godot's built-in multiplayer system using RPC
- **Connection Model**: Client-Server (Host acts as server)
- **Web Support**: Uses WebSocket for web builds
- **Player Limit**: 2-8 players (configurable)

### Game Flow
1. **Lobby Phase**: Host creates game, players join with IP
2. **Game Setup**: Load JSON game data, display board
3. **Round Play**: Players buzz in, answer questions, track scores
4. **End Game**: Display final scores and winner

### Data Structure
- **JSON-based question pools**: Easy to create and modify
- **Runtime loading**: Load different game files without rebuilding
- **Randomized board generation**: Game selects from question pool to create unique boards
- **Flexible point ranges**: Questions have min/max point values instead of fixed points
- **Category diversity**: Multiple questions per category for variety
- **Difficulty levels**: Questions tagged with difficulty for intelligent board placement

## Technical Specifications

### Scene Structure
```
Main.tscn (Game Manager)
├── UI/
│   ├── MainMenu.tscn (Host/Join screens)
│   ├── Lobby.tscn (Pre-game player list)
│   ├── GameBoard.tscn (Main game interface)
│   ├── QuestionDisplay.tscn (Question/answer popup)
│   └── ScoreBoard.tscn (Current scores)
├── Network/
│   ├── NetworkManager.gd (Multiplayer logic)
│   └── GameState.gd (Shared game state)
└── Data/
    ├── GameData.gd (JSON loader/parser)
    └── Player.gd (Player data structure)
```

### Core Scripts
- **NetworkManager.gd**: Handles all multiplayer communication
- **GameState.gd**: Manages current game state (scores, board, turn order)
- **GameData.gd**: Loads and parses JSON question pools
- **BoardGenerator.gd**: Handles randomized board creation from question pools
- **UIManager.gd**: Coordinates UI transitions and updates

### JSON Schema
```json
{
  "title": "Sample Jeopardy Game",
  "questions": [
    {
      "category": "CATEGORY NAME",
      "question": "This is the question text",
      "answer": "What is the answer?",
      "point_range": {"min": 200, "max": 600},
      "tags": ["optional", "metadata"]
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

### Board Generation Algorithm

The game creates unique boards each time by randomly selecting from the question pool:

1. **Category Selection**: 
   - Identify all unique categories in the question pool
   - Randomly select 6 categories (or configured amount)
   - Ensure each selected category has enough questions

2. **Question Selection**:
   - For each category, randomly select 5 questions (or configured amount)
   - Prioritize questions that fit the target point values (200, 400, 600, 800, 1000)
   - Use point_range to determine appropriate placement on board
   - Ensure no duplicate questions on the board

3. **Point Assignment**:
   - Assign point values based on board position and question point_range
   - Use point_range to determine if question fits the target value
   - Allow some randomization within acceptable ranges

4. **Daily Double Placement**:
   - Randomly select 2 questions to become Daily Doubles
   - Exclude lowest point value row (traditional Jeopardy rule)
   - Mark selected questions with daily_double flag

5. **Validation**:
   - Ensure all 30 board positions are filled
   - Verify no duplicate questions or categories
   - Confirm Daily Doubles are properly placed

**Benefits of Randomization**:
- **High Replayability**: Same question pool generates different games
- **Scalable Content**: Add more questions without changing game logic
- **Balanced Scoring**: Automatic distribution across point values using point_range
- **Easy Content Creation**: No need to manually structure categories or assign difficulty levels

## UI/UX Design

### Main Menu
- **Host Game**: Start server, display IP address
- **Join Game**: Input field for host IP address
- **Load Game Data**: File picker for JSON files

### Game Board
- **6x5 Grid**: Categories across top, point values in cells
- **Player List**: Names and current scores
- **Buzzer Button**: Large, prominent buzzer for mobile support
- **Timer Display**: Countdown for current question
- **Status Bar**: Current player turn, game phase

### Question Display
- **Modal Popup**: Covers board when question is active
- **Question Text**: Large, readable font
- **Timer**: Visual countdown (30 seconds)
- **Buzz Indicator**: Shows who buzzed first
- **Answer Reveal**: Show correct answer after timeout/wrong answer

## Game Rules Implementation

### Buzzer System
1. Question displayed with 30-second timer
2. Players can buzz in anytime during display
3. First buzz stops timer, gives player 10 seconds to answer
4. Correct answer: Award points, next question
5. Wrong answer: Deduct points, resume timer for others
6. No correct answer: Show answer, no points awarded

### Scoring
- **Correct Answer**: Add point value to score
- **Wrong Answer**: Subtract point value from score
- **No Answer**: No point change
- **Final Jeopardy**: Optional double-or-nothing round

### Turn Order
- Random first player selection
- Correct answers allow player to choose next question
- Wrong answers pass control to next player

## Networking Protocol

### RPC Methods
- `player_joined(name: String, id: int)`
- `player_left(id: int)`
- `game_data_loaded(question_pool: Dictionary)`
- `board_generated(board_layout: Dictionary)`
- `game_started()`
- `question_selected(category: int, points: int)`
- `player_buzzed(player_id: int, timestamp: float)`
- `answer_submitted(answer: String)`
- `score_updated(player_id: int, new_score: int)`
- `game_ended(final_scores: Dictionary)`

### State Synchronization
- Host maintains authoritative game state
- Clients receive state updates via RPC
- Conflict resolution: Host decision is final
- Disconnect handling: Game continues with remaining players

## File Structure
```
res://
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── Lobby.tscn
│   │   ├── GameBoard.tscn
│   │   ├── QuestionDisplay.tscn
│   │   └── ScoreBoard.tscn
│   └── components/
│       ├── PlayerCard.tscn
│       ├── CategoryHeader.tscn
│       └── QuestionButton.tscn
├── scripts/
│   ├── networking/
│   │   ├── NetworkManager.gd
│   │   └── GameState.gd
│   ├── data/
│   │   ├── GameData.gd
│   │   ├── BoardGenerator.gd
│   │   ├── Player.gd
│   │   └── Question.gd
│   └── ui/
│       ├── UIManager.gd
│       ├── MainMenuController.gd
│       ├── GameBoardController.gd
│       └── QuestionDisplayController.gd
├── data/
│   └── sample_games/
│       ├── classic_jeopardy.json
│       ├── tech_trivia.json
│       └── movie_quotes.json
├── assets/
│   ├── fonts/
│   ├── sounds/
│   │   ├── buzz.ogg
│   │   ├── correct.ogg
│   │   ├── wrong.ogg
│   │   └── timer.ogg
│   └── images/
│       ├── background.png
│       └── logo.png
└── export_presets.cfg
```

## Development Phases

### Phase 1: Core Framework
- Basic scene structure
- NetworkManager implementation
- Simple UI layouts
- JSON data loading

### Phase 2: Game Logic
- Buzzer system implementation
- Scoring logic
- Timer systems
- Question flow

### Phase 3: UI Polish
- Visual design implementation
- Sound effects
- Animations and transitions
- Mobile responsiveness

### Phase 4: Web Deployment
- Export settings for web
- WebSocket configuration
- Browser compatibility testing
- Performance optimization

## Technical Considerations

### Web Export
- Enable threads for better performance
- Configure CORS headers for WebSocket
- Optimize asset loading for web
- Handle browser security restrictions

### Performance
- Efficient RPC usage (avoid frequent updates)
- Lazy loading of question data
- Minimize texture memory usage
- Optimize for low-end devices

### Security
- Input validation for player names
- Rate limiting for buzzer spam
- Sanitize user-generated content
- No sensitive data in client builds

## Testing Strategy
- Local multiplayer testing
- Network latency simulation
- JSON parsing error handling
- Browser compatibility testing
- Mobile device testing

## Future Enhancements
- Daily Double questions
- Final Jeopardy round
- Team play support
- Spectator mode
- Game replay system
- Statistics tracking
- Custom themes/skins