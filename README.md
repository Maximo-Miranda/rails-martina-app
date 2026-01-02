# README

## AI Integration (Rails MCP)

To use this project with GitHub Copilot MCP:

1. **Install Server:** `gem install rails-mcp-server`
2. **Register Project:** Run `rails-mcp-config` and add this repository.
3. **VS Code Setup:**
   - Install the **Copilot MCP** extension (by AutomataLabs).
   - Edit `mcp.json` in your VS Code User settings directory:
     - **macOS:** `~/Library/Application Support/Code/User/mcp.json`
     - **Linux:** `~/.config/Code/User/mcp.json`
   - Add the following configuration:
     ```json
     "rails": {
       "type": "stdio",
       "command": "rails-mcp-server",
       "args": []
     }
     ```
   *(Note: Use `which rails-mcp-server` to get the full path for the command if using mise/rbenv)*

