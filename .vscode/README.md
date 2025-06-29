# Godot Tools VSCode Configuration for Jeopardy

This directory contains proper Godot Tools VSCode configurations for debugging and testing the multiplayer Jeopardy game.

## Prerequisites

1. **Godot Engine**: Version 4.x installed and accessible in PATH
2. **VSCode**: Visual Studio Code  
3. **Godot Tools Extension**: Install from VSCode marketplace (`geequlim.godot-tools`)

## Setup

1. **Install Godot Tools Extension**:
   - Open VSCode
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Godot Tools" by geequlim
   - Install the extension

2. **Configure Godot Editor Path** (if needed):
   - Open settings.json and update `godot_tools.editor_path` if Godot isn't in PATH
   - Windows: `"C:\\path\\to\\godot.exe"`
   - Linux/Mac: `"/path/to/godot"`

## Launch Configurations

### Available Configurations

1. **Launch Host Client**: Starts first game instance on port 6007
2. **Launch Client**: Starts second game instance on port 6008  
3. **Launch Two Clients (Host + Client)**: Compound launch for both instances
4. **Attach to Host**: Attach debugger to running host instance
5. **Attach to Client**: Attach debugger to running client instance

### How to Use

1. **Open Debug Panel**: Press Ctrl+Shift+D or click Debug icon
2. **Select Configuration**: Choose "Launch Two Clients (Host + Client)" from dropdown
3. **Start Debugging**: Press F5 or click green play button
4. **Two Godot instances** will launch with debugging enabled

### Testing Multiplayer

1. **Launch both clients** using the compound configuration
2. **In the first instance (Host)**:
   - Click "Host Game"
   - Game will start server on default port 8080
3. **In the second instance (Client)**:
   - IP should be "127.0.0.1" (default)
   - Click "Join Game"
4. **Both instances** connect and can play together

## Debugging Features

### Breakpoints
- Set breakpoints in GDScript files
- Both game instances can hit breakpoints
- Debug variables, call stack, and execution flow

### Console Output
- Each instance outputs to separate debug console
- Network messages and game state changes visible
- Error messages and print statements displayed

### Hot Reload
- Godot Tools supports live script editing
- Changes reflect in running instances (where supported)

## Configuration Details

### Ports Used
- **LSP Server**: 6005 (Language Server Protocol)
- **Host Debug**: 6007 (First game instance)  
- **Client Debug**: 6008 (Second game instance)
- **Game Network**: 8080 (Multiplayer game traffic)

### Files
- **launch.json**: Debug configurations
- **settings.json**: Godot Tools extension settings
- **tasks.json**: Build and export tasks (optional)

## Troubleshooting

### Common Issues

1. **"Godot not found"**: Update `godot_tools.editor_path` in settings.json
2. **Debug connection failed**: Check ports 6007/6008 aren't in use
3. **LSP not working**: Restart VSCode after installing Godot Tools
4. **Breakpoints not hit**: Ensure debug builds and proper scene loading

### Network Issues

1. **Connection refused**: Start host before client
2. **Firewall blocking**: Allow Godot through Windows Firewall  
3. **Port conflicts**: Change network port in NetworkManager.gd if needed

### Performance

- Debugging adds overhead - disable for performance testing
- Use Release builds for final testing
- Consider running instances on different machines for real network testing

## Advanced Usage

### Custom Scenes
- Modify `scene_file_config` in settings.json to launch specific scenes
- Useful for testing individual UI components

### Multiple Clients
- Add more configurations with different ports (6009, 6010, etc.)
- Create additional compound launches for 3+ player testing

### Remote Debugging
- Change `address` from "127.0.0.1" to target machine IP
- Useful for testing across network