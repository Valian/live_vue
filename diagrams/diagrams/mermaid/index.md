# LiveVue Architecture Diagrams

This document contains various diagrams explaining the architecture of LiveVue.

## Architecture


```mermaid
flowchart TB
    subgraph Client
        Browser["Browser"]
        VueComponents["Vue.js Components"]
    end
    
    subgraph Server
        subgraph LiveVue
            LiveVueCore["LiveVue Core"]
            SSRModule["Server-Side Rendering"]
        end
        Phoenix["Phoenix LiveView"]
    end
    
    Browser --> VueComponents
    Browser --> Phoenix
    Phoenix --> LiveVueCore
    LiveVueCore --> SSRModule
    SSRModule --> VueComponents
```


## Component Flow


```mermaid
flowchart LR
    subgraph Elixir
        Template["Template (HEEx)"]
        LiveVueComponent["LiveVue.vue Component"]
        SSRModule["SSR Module"]
    end
    
    subgraph JavaScript
        Hooks["Vue Hooks"]
        VueApp["Vue Application"]
        Components["Vue Components"]
    end
    
    Client["Browser"]
    
    Template --> LiveVueComponent
    LiveVueComponent --> SSRModule
    LiveVueComponent --> Hooks
    Hooks --> VueApp
    VueApp --> Components
    Components --> Client
```


## Data Flow


```mermaid
flowchart TD
    subgraph PhoenixLiveView
        LiveView["LiveView"]
        Assigns["Assigns"]
        LiveVueComponent["LiveVue Component"]
    end
    
    subgraph JavaScriptRuntime
        Hook["Vue Hook"]
        VueApp["Vue Application"]
        Props["Props"]
        Events["Events"]
    end
    
    subgraph DOM
        Element["Vue Component Element"]
    end
    
    LiveView --> Assigns
    Assigns --> LiveVueComponent
    LiveVueComponent --> Element
    Element --> Hook
    Hook --> Props
    Props --> VueApp
    VueApp --> Events
    Events --> LiveView
```


## Ssr Process


```mermaid
sequenceDiagram
    participant LV as LiveView
    participant LVC as LiveVue.vue Component
    participant SSR as SSR Module
    participant Node as Node.js SSR Server
    participant VueSSR as Vue SSR Renderer
    participant Browser
    participant Client as Client Vue
    
    LV->>LVC: Render component
    LVC->>SSR: Request SSR
    SSR->>Node: Forward component data
    Node->>VueSSR: Render component
    VueSSR-->>Node: HTML & preload links
    Node-->>SSR: HTML & preload links
    SSR-->>LVC: HTML & preload links
    LVC-->>Browser: Complete HTML
    Browser->>Client: Hydrate Vue component
```


## Class Diagram


```mermaid
classDiagram
    class LiveVue {
        +vue(assigns)
        +__using__(opts)
        -extract(assigns, type)
        -normalize_key(key, val)
        -key_changed(assigns, key)
        -ssr_render(assigns)
        -json(data)
        -id(name)
    }
    
    class LiveVue_SSR {
        +render(name, props, slots)
    }
    
    class LiveVue_Components {
        +__using__(opts)
        -name_to_function(name)
    }
    
    class LiveVue_Slots {
        +rendered_slot_map(slots)
        +base_encode_64(slots)
    }
    
    class Vue_Hooks {
        +mounted()
        +updated()
        +destroyed()
    }
    
    class Vue_App {
        +createApp()
        +createSSRApp()
    }
    
    LiveVue --> LiveVue_SSR : uses
    LiveVue --> LiveVue_Slots : uses
    LiveVue --> LiveVue_Components : provides
    Vue_Hooks --> Vue_App : creates
    LiveVue_SSR --> Vue_App : renders with
```


## Lifecycle


```mermaid
stateDiagram-v2
    [*] --> TemplateRender: Elixir template includes LiveVue component
    TemplateRender --> SSRCheck: LiveVue.vue function called
    
    SSRCheck --> SSRRender: If initial render and not connected
    SSRCheck --> NoSSR: If connected or SSR disabled
    
    SSRRender --> HTMLGeneration: SSR module renders component
    NoSSR --> HTMLGeneration: Skip SSR, generate placeholder
    
    HTMLGeneration --> DOMMount: HTML rendered to page
    
    DOMMount --> HookMount: Vue hook mounted
    HookMount --> VueApp: Vue app created
    VueApp --> ClientHydration: Vue app hydrates component
    
    ClientHydration --> EventHandling: Component ready for interaction
    EventHandling --> EventHandling: User interacts with component
    
    EventHandling --> LiveViewUpdate: Events sent to LiveView
    LiveViewUpdate --> ComponentUpdate: LiveView updates component props
    ComponentUpdate --> EventHandling: Component re-renders with new props
    
    ComponentUpdate --> HookDestroy: When LiveView navigates away
    HookDestroy --> [*]: Vue app unmounted
```


