#!/bin/bash
set -e

echo "🔧 Setting up LiveVue workspace..."

# Check for required tools
if ! command -v mix &> /dev/null; then
    echo "❌ Error: mix (Elixir) is not installed"
    echo "Please install Elixir from https://elixir-lang.org/install.html"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm (Node.js) is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "✓ Found mix and npm"

# Install Elixir dependencies
echo "📦 Installing Elixir dependencies..."
mix deps.get

# Install Node dependencies
echo "📦 Installing Node dependencies..."
npm ci

# Install Playwright browsers for E2E tests
echo "🎭 Installing Playwright browsers..."
MIX_ENV=e2e mix deps.get && MIX_ENV=e2e mix playwright.install chromium

echo "✅ Setup complete! Run 'cd example_project && mix phx.server' to start development."
