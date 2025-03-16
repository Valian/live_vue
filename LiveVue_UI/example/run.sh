#!/bin/bash

# Change to the example directory
cd "$(dirname "$0")"

# Get dependencies
mix deps.get

# Setup LiveVue
mix live_vue.setup

# Setup LiveVue UI
mix live_vue_ui.setup

# Run the server
mix phx.server 