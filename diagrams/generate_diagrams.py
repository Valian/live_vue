#!/usr/bin/env python
"""
Script to generate architecture diagrams for LiveVue documentation.

This script creates SVG diagrams using the diagrams library to visualize
the LiveVue architecture, component flow, and integration between Phoenix and Vue.
"""
from typing import Dict, List, Optional, Tuple, Union, Any
import os
from pathlib import Path

try:
    from diagrams import Diagram, Cluster, Edge
    from diagrams.custom import Custom
    from diagrams.programming.framework import Vue, React
    from diagrams.programming.language import Elixir, TypeScript, JavaScript
    from diagrams.onprem.client import Client
    from diagrams.onprem.compute import Server
    from diagrams.onprem.network import Nginx
except ImportError:
    print("Installing required dependencies...")
    os.system("pip install diagrams")
    from diagrams import Diagram, Cluster, Edge
    from diagrams.custom import Custom
    from diagrams.programming.framework import Vue, React
    from diagrams.programming.language import Elixir, TypeScript, JavaScript
    from diagrams.onprem.client import Client
    from diagrams.onprem.compute import Server
    from diagrams.onprem.network import Nginx

# Create the output directory if it doesn't exist
os.makedirs("output", exist_ok=True)

def create_high_level_architecture() -> None:
    """
    Create a high-level architecture diagram showing the main components of LiveVue.
    """
    with Diagram("LiveVue Architecture", filename="output/architecture", show=False):
        with Cluster("Client"):
            browser = Client("Browser")
            vue_client = Vue("Vue.js Components")
            
        with Cluster("Server"):
            phoenix = Elixir("Phoenix LiveView")
            with Cluster("LiveVue"):
                live_vue_core = Custom("LiveVue Core", "./docs/phoenix.png")
                ssr = Custom("SSR Module", "./docs/vue.png")
            
        browser >> vue_client
        browser >> phoenix
        phoenix >> live_vue_core
        live_vue_core >> ssr
        ssr >> vue_client

def create_component_flow_diagram() -> None:
    """
    Create a diagram showing the component rendering flow in LiveVue.
    """
    with Diagram("LiveVue Component Flow", filename="output/component_flow", show=False):
        with Cluster("Elixir"):
            template = Elixir("Template (HEEx)")
            live_component = Elixir("LiveVue.vue Component")
            ssr_module = Elixir("SSR Module")
            
        with Cluster("JavaScript"):
            hooks = TypeScript("Vue Hooks")
            vue_app = Vue("Vue Application")
            components = Vue("Vue Components")
            
        client = Client("Browser")
        
        template >> live_component
        live_component >> ssr_module
        live_component >> hooks
        hooks >> vue_app
        vue_app >> components
        components >> client

def create_data_flow_diagram() -> None:
    """
    Create a diagram showing the data flow between Phoenix LiveView and Vue components.
    """
    with Diagram("LiveVue Data Flow", filename="output/data_flow", show=False):
        with Cluster("Phoenix LiveView"):
            live_view = Elixir("LiveView")
            assigns = Elixir("Assigns")
            live_vue = Elixir("LiveVue Component")
            
        with Cluster("JavaScript Runtime"):
            hook = TypeScript("Vue Hook")
            vue_app = Vue("Vue Application")
            props = TypeScript("Props")
            events = TypeScript("Events")
            
        with Cluster("DOM"):
            element = Client("Vue Component Element")
            
        live_view >> assigns
        assigns >> live_vue
        live_vue >> element
        element >> hook
        hook >> props
        props >> vue_app
        vue_app >> events
        events >> live_view

def create_ssr_diagram() -> None:
    """
    Create a diagram showing the server-side rendering process in LiveVue.
    """
    with Diagram("LiveVue SSR Process", filename="output/ssr_process", show=False):
        with Cluster("Server"):
            live_view = Elixir("LiveView Render")
            live_vue_component = Elixir("LiveVue.vue Component")
            ssr_module = Elixir("SSR Module")
            node_server = JavaScript("Node.js SSR Server")
            vue_renderer = Vue("Vue SSR Renderer")
            
        with Cluster("Client"):
            browser = Client("Browser")
            client_vue = Vue("Vue Hydration")
            
        live_view >> live_vue_component
        live_vue_component >> ssr_module
        ssr_module >> node_server
        node_server >> vue_renderer
        vue_renderer >> live_vue_component
        live_vue_component >> browser
        browser >> client_vue

if __name__ == "__main__":
    print("Generating LiveVue architecture diagrams...")
    create_high_level_architecture()
    create_component_flow_diagram()
    create_data_flow_diagram()
    create_ssr_diagram()
    print("Diagrams generated successfully in diagrams/output/") 