# Testing Guide

LiveVue provides a robust testing module `LiveVue.Test` that makes it easy to test Vue components within your Phoenix LiveView tests.

## Overview

Testing LiveVue components differs from traditional Phoenix LiveView testing in a key way:
- Traditional LiveView testing uses `render_component/2` to get final HTML
- LiveVue testing provides helpers to inspect the Vue component configuration before client-side rendering

## Basic Component Testing

Let's start with a simple component test:

```elixir
defmodule MyAppWeb.CounterTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  alias LiveVue.Test

  test "renders counter component with initial props" do
    {:ok, view, _html} = live(conn, "/counter")
    vue = Test.get_vue(view)

    assert vue.component == "Counter"
    assert vue.props == %{"count" => 0}
  end
end
```

The `get_vue/2` function returns a map containing:
- `:component` - Vue component name
- `:id` - Unique component identifier
- `:props` - Decoded props
- `:handlers` - Event handlers and operations
- `:slots` - Slot content
- `:ssr` - SSR status
- `:class` - CSS classes

## Testing Multiple Components

When your view contains multiple Vue components, you can specify which one to test:

```elixir
# Find by component name
vue = Test.get_vue(view, name: "UserProfile")

# Find by ID
vue = Test.get_vue(view, id: "profile-1")
```

Example with multiple components:

```elixir
def render(assigns) do
  ~H"""
  <div>
    <.vue id="profile-1" name="John" v-component="UserProfile" />
    <.vue id="card-1" name="Jane" v-component="UserCard" />
  </div>
  """
end

test "finds specific component" do
  html = render_component(&my_component/1)

  # Get UserCard component
  vue = Test.get_vue(html, name: "UserCard")
  assert vue.props == %{"name" => "Jane"}

  # Get by ID
  vue = Test.get_vue(html, id: "profile-1")
  assert vue.component == "UserProfile"
end
```

## Testing Event Handlers

You can verify event handlers are properly configured:

```elixir
test "component has correct event handlers" do
  vue = Test.get_vue(render_component(&my_component/1))

  assert vue.handlers == %{
    "click" => JS.push("click", value: %{"abc" => "def"}),
    "submit" => JS.push("submit")
  }
end
```

## Testing Slots

LiveVue provides tools to test both default and named slots:

```elixir
def component_with_slots(assigns) do
  ~H"""
  <.vue v-component="WithSlots">
    Default content
    <:header>Header content</:header>
    <:footer>Footer content</:footer>
  </.vue>
  """
end

test "renders slots correctly" do
  vue = Test.get_vue(render_component(&component_with_slots/1))

  assert vue.slots == %{
    "default" => "Default content",
    "header" => "Header content",
    "footer" => "Footer content"
  }
end
```

Important notes about slots:
- Use `<:inner_block>` instead of `<:default>` for default content
- Slots are automatically Base64 encoded in the HTML
- The test helper decodes them for easier assertions

## Testing SSR Configuration

Verify Server-Side Rendering settings:

```elixir
test "respects SSR configuration" do
  vue = Test.get_vue(render_component(&my_component/1))
  assert vue.ssr == true

  # Or with SSR disabled
  vue = Test.get_vue(render_component(&ssr_disabled_component/1))
  assert vue.ssr == false
end
```

## Testing CSS Classes

Check applied styling:

```elixir
test "applies correct CSS classes" do
  vue = Test.get_vue(render_component(&my_component/1))
  assert vue.class == "bg-blue-500 rounded"
end
```

## Integration Testing

For full integration tests, combine LiveVue testing with LiveView test helpers:

```elixir
test "counter increments correctly", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/counter")

  # Verify initial state
  vue = Test.get_vue(view)
  assert vue.props == %{"count" => 0}

  # Simulate increment event
  view |> element("button") |> render_click()

  # Verify updated state
  vue = Test.get_vue(view)
  assert vue.props == %{"count" => 1}
end
```

## Best Practices

1. **Component Isolation**
   - Test Vue components in isolation when possible
   - Use `render_component/1` for focused tests

2. **Clear Assertions**
   - Test one aspect per test
   - Use descriptive test names
   - Assert specific properties rather than entire component structure

3. **Integration Testing**
   - Test full component interaction in LiveView context
   - Verify both server and client-side behavior
   - Test error cases and edge conditions

4. **Maintainable Tests**
   - Use helper functions for common assertions
   - Keep test setup minimal and clear
   - Document complex test scenarios