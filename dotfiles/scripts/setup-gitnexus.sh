#!/bin/bash
set -e

echo "📦 Installing gitnexus globally..."
npm install -g gitnexus@latest

echo ""
echo "🔍 Indexing dotfiles repository..."
cd ~/Projects/dotfiles
gitnexus analyze

echo ""
echo "🔍 Indexing keymaging/meta repository..."
cd ~/Projects/keymaging/meta
gitnexus analyze

echo ""
echo "✅ GitNexus setup complete. Indexed repositories:"
gitnexus list

echo ""
echo "📋 Next steps:"
echo "  1. Run: gitnexus setup"
echo "  2. Restart Claude Code"
echo "  3. Verify MCP tools are available in agents"
