# MCP Kit for CodingReviewer

This directory contains the Model Context Protocol (MCP) integration kit for the CodingReviewer submodule.

## Overview

The MCP kit provides a lightweight interface to the centralized MCP server running in the root `tools-automation` workspace. This allows CodingReviewer to leverage AI capabilities without duplicating infrastructure.

## Files

- **mcp_client.sh** - Shim script that forwards requests to the root MCP client
- **mcp_config.json** - Project-specific MCP configuration
- **env.sh** - Environment variables for this submodule
- **simple_mcp_check.sh** - Health check script for MCP connectivity

## Quick Start

### 1. Check MCP Health

```bash
./.tools-automation/simple_mcp_check.sh
```

This verifies:

- MCP server is running (http://127.0.0.1:5005)
- Ollama is accessible (http://localhost:11434)

### 2. Use MCP Client

```bash
# Register this agent
./.tools-automation/mcp_client.sh register CodingReviewer-agent

# Run a command
./.tools-automation/mcp_client.sh run CodingReviewer-agent analyze --execute

# Check status
./.tools-automation/mcp_client.sh check mcp_server
```

## Configuration

### mcp_config.json

Contains project-specific settings:

- `project_name`: "CodingReviewer"
- `agent_name`: "CodingReviewer-agent"
- MCP server URL and version
- Provider endpoints

### env.sh

Source this file to set environment variables:

```bash
source ./.tools-automation/env.sh
```

This sets:

- `PROJECT_NAME`
- `SUBMODULE_ROOT`
- `MCP_SERVER_URL`
- `OLLAMA_ENDPOINT`

## Requirements

### MCP Server

The MCP server must be running in the root workspace:

```bash
# From tools-automation root
python3 mcp_server.py
```

Or use launchd for automatic startup (see root README).

### Authentication

MCP server requires authentication. Token is stored in macOS Keychain:

```bash
# Generate token (run once from root)
./security/mcp_auth_token.sh
```

The token is automatically retrieved from Keychain by the MCP client.

### Ollama

Local Ollama instance must be running:

```bash
ollama serve
```

## Troubleshooting

### "MCP server not responding"

1. Check if server is running: `ps aux | grep mcp_server`
2. Start server: `python3 ../../mcp_server.py`
3. Check logs: `tail ~/Library/Logs/tools-automation/mcp-server.log`

### "Unauthorized" error

1. Verify token exists: `security find-generic-password -a $USER -s 'tools-automation-mcp' -w`
2. Regenerate if needed: `../../security/mcp_auth_token.sh`
3. Restart MCP server

### "Ollama connection failed"

1. Check Ollama status: `ollama list`
2. Start Ollama: `ollama serve`
3. Verify endpoint: `curl http://localhost:11434/api/tags`

## Documentation

For complete API documentation, see:

- [MCP Endpoints](../../docs/MCP_ENDPOINTS.md)
- [Root README](../../README.md)
- [Master Plan](../../AGENT_ENHANCEMENT_MASTER_PLAN.md)

## Support

For issues or questions:

1. Check health: `./.tools-automation/simple_mcp_check.sh`
2. Review logs in `~/Library/Logs/tools-automation/`
3. Consult root workspace documentation
