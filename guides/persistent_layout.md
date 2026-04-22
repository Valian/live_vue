# Persistent Layouts

This guide describes patterns for keeping a Vue layout alive while LiveView navigation changes the current page content.

The common goal is:

- keep one layout Vue app mounted across navigation
- replace only the page content inside that layout
- avoid losing client-side layout state, such as open menus, counters, scroll state, or local UI preferences
- optionally keep layout data in a separate sticky LiveView process

For the slot mechanics, see [Component Reference - Vue Component Slot Injection](component_reference.md#vue-component-slot-injection).

## Pattern 1: Root Layout Component with v-inject

This is the simplest persistent layout pattern. Render one shared layout component in `root.html.heex`, then render each LiveView page as a top-level component injected into the layout slot.

```elixir
<!-- root.html.heex -->
<LiveVue.vue
  id="layout"
  v-component="AppLayout"
  user={assigns[:current_user]}
/>

{@inner_content}
```

Each page LiveView renders one top-level component and injects it into the layout:

```elixir
def render(assigns) do
  ~H"""
  <.vue
    v-component="PostsPage"
    posts={@posts}
    v-inject="layout"
  />
  """
end
```

The layout component exposes a normal Vue slot:

```vue
<!-- AppLayout.vue -->
<template>
  <header>...</header>
  <main>
    <slot />
  </main>
</template>
```

On the initial HTTP render, LiveVue SSR composes the injected page into the layout HTML. After LiveView connects, navigation replaces the injected slot content without remounting the layout Vue app.

### Tradeoffs

This pattern works best when the layout mostly owns client-side state and does not need server-backed reactivity.

Important limitations:

- `root.html.heex` is rendered during the initial dead render. It is not backed by the page LiveView socket after connect.
- Props passed to the root layout component are initial values. If a socket assign changes later, the root layout component will not receive that update automatically.
- The root layout component should not be used for server-backed interactions that require its own LiveView events or assign updates.
- The injected page component is still reactive because it belongs to the current page LiveView.
- The layout Vue app survives LiveView navigation, so local Vue state in the layout is preserved while only the slot component changes.

Use this when you want a persistent client-side app shell and the changing page content is the server-reactive part.

## Pattern 2: Sticky LiveView Layout with v-inject

When the layout needs server-backed state or events, render it through a sticky LiveView from the root layout.

```elixir
<!-- root.html.heex -->
<%= if assigns[:current_user] do %>
  {live_render(@conn, MyAppWeb.StickyLayoutLive,
    session: %{"user_id" => assigns[:current_user].id},
    sticky: true
  )}
<% end %>

{@inner_content}
```

The sticky LiveView renders the layout Vue app:

```elixir
defmodule MyAppWeb.StickyLayoutLive do
  use MyAppWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    {:ok,
     socket
     |> assign(:current_user, load_user(user_id))
     |> stream(:notifications, [])}
  end

  def render(assigns) do
    ~H"""
    <.vue
      id="layout"
      v-component="AppLayout"
      v-socket={@socket}
      user={@current_user}
      notifications={@streams.notifications}
    />
    """
  end
end
```

Pages still inject their top-level component into the layout:

```elixir
def render(assigns) do
  ~H"""
  <.vue
    v-component="PostsPage"
    posts={@posts}
    v-inject="layout"
  />
  """
end
```

The layout can pass its own state to the page through slot props:

```vue
<!-- AppLayout.vue -->
<script setup lang="ts">
defineProps<{
  user: { id: number; name: string }
}>()
</script>

<template>
  <header>{{ user.name }}</header>
  <main>
    <slot :user="user" />
  </main>
</template>
```

The injected page receives both its LiveView props and the layout slot props:

```vue
<!-- PostsPage.vue -->
<script setup lang="ts">
defineProps<{
  posts: Array<{ id: number; title: string }>
  user: { id: number; name: string }
}>()
</script>
```

The sticky LiveView is a separate persistent backend process. It can handle its own events, update assigns and streams, and keep those props reactive across LiveView navigation.

### Accessing Layout Props by ID

Any LiveVue component can also look up another LiveVue hook by element id:

```vue
<script setup lang="ts">
import { useLiveVue } from "live_vue"

const layout = useLiveVue("layout")
</script>

<template>
  <div v-if="layout">
    Current user: {{ layout.vue.props.user.name }}
  </div>
</template>
```

Inside an injected page, `useLiveVue()` without arguments returns the page component's own hook. Use `useLiveVue("layout")` when you need the layout hook. The id lookup only succeeds after the target hook has been initialized; hooks initialize in HTML order, so render shared layout or headless state components before components that read them.

### Tradeoffs

This pattern is best when the layout is real application state, not just a visual wrapper.

Benefits:

- The layout has its own persistent LiveView process.
- The layout can handle events and update its own props.
- The layout Vue app is not discarded during LiveView navigation.
- Pages can receive layout data either through slot props or by calling `useLiveVue("layout")`.

Costs:

- There is one more LiveView process.
- You need to decide which state belongs to the sticky layout and which state belongs to the page LiveView.
- The sticky LiveView persists across LiveView navigation, but not across a full page reload.

## Pattern 3: Headless Sticky Layout State

Sometimes you do not want a shared layout Vue app at all. You only want persistent global props that page components can read while rendering their own layout.

In that case, render a sticky LiveView with a headless LiveVue component: give it an `id` and props, but no `v-component`.

```elixir
<!-- root.html.heex -->
<%= if assigns[:current_user] do %>
  {live_render(@conn, MyAppWeb.StickyLayoutLive,
    session: %{"user_id" => assigns[:current_user].id},
    sticky: true
  )}
<% end %>

{@inner_content}
```

```elixir
defmodule MyAppWeb.StickyLayoutLive do
  use MyAppWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    {:ok,
     socket
     |> assign(:current_user, load_user(user_id))
     |> assign(:workspaces, list_workspaces(user_id))
     |> stream(:notifications, [])}
  end

  def render(assigns) do
    ~H"""
    <.vue
      id="layout"
      v-socket={@socket}
      user={@current_user}
      workspaces={@workspaces}
      notifications={@streams.notifications}
    />
    """
  end
end
```

Because there is no `v-component`, LiveVue does not mount a Vue app for this element. It only keeps a reactive hook and props available under the id `"layout"`.

Each page renders normally, without `v-inject`:

```elixir
def render(assigns) do
  ~H"""
  <.vue
    v-component="PostsPage"
    posts={@posts}
  />
  """
end
```

The page component reads the persistent layout props and renders its own layout:

```vue
<!-- PostsPage.vue -->
<script setup lang="ts">
import { useLiveVue } from "live_vue"
import AppLayout from "./AppLayout.vue"

defineProps<{
  posts: Array<{ id: number; title: string }>
}>()

const layout = useLiveVue("layout")
</script>

<template>
  <AppLayout
    title="Posts"
    :user="layout?.vue.props.user"
    :workspaces="layout?.vue.props.workspaces"
  >
    <!-- page content -->
  </AppLayout>
</template>
```

### Tradeoffs

This pattern is best when every page controls its own layout composition, but you want global state to survive navigation.

Benefits:

- There is no shared layout Vue app to coordinate.
- Each page can render a different layout variant.
- Global props persist because the sticky LiveView is not remounted during LiveView navigation.
- Global props can use streams and normal LiveView updates.

Costs:

- Each page still mounts its own top-level Vue app.
- Layout UI state inside `AppLayout` does not automatically persist unless you store it in the sticky LiveView props or another client-side store.
- Components should handle the case where `useLiveVue("layout")` returns `null`, for example during tests or when the sticky layout is disabled.

## Choosing a Pattern

| Pattern | Use When | Main Benefit | Main Limitation |
|---------|----------|--------------|-----------------|
| Root layout with `v-inject` | The layout is mostly client-side UI | One Vue layout app survives navigation | Root layout props are not socket-reactive |
| Sticky LiveView layout with `v-inject` | The layout needs server-backed state or events | Persistent backend process and persistent Vue layout app | More moving parts |
| Headless sticky layout state | Pages render their own layout but need shared persistent props | Global reactive props across navigation | Top-level page Vue apps still remount |

## General Limitations

- `v-inject` needs a stable target `id`.
- Boolean shorthand such as `v-inject={true}` is invalid.
- `useLiveVue(id)` can only find a LiveVue hook that has already initialized. Render lookup targets earlier in the HTML than components that call `useLiveVue(id)`.
- Only one component can own a target slot at a time. If multiple components inject into the same target and slot, the last one wins and LiveVue logs a warning.
- Injected component props are merged with slot props. If the same prop exists in both places, the injected component's LiveView prop wins.
- Sticky LiveViews persist across LiveView navigation within the same root layout, but a full page reload creates a new process.
