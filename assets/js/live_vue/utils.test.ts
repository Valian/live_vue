import { describe, it, expect } from "vitest"
import { findComponent } from "./utils"
import type { ComponentMap } from "./types"

describe("findComponent", () => {
  const MockComponent = {
    template: "<div>Mock Component</div>",
  }

  const MockCreateWorkspaceComponent = {
    template: "<div>Create Workspace Component</div>",
  }

  it("should find exact component match for 'workspace'", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace.vue": MockComponent,
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockComponent)
  })

  it("should NOT match 'workspace' to 'create-workspace'", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
      "../../lib/live_vue/web/pages/workspace.vue": MockComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockComponent)
  })

  it("should find 'create-workspace' component when requested", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace.vue": MockComponent,
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
    }

    const result = findComponent(components, "create-workspace")

    expect(result).toBe(MockCreateWorkspaceComponent)
  })

  it("should throw error when component is not found", () => {
    const components: ComponentMap = {
      "../../lib/leuchtturm/web/pages/workspace.vue": MockComponent,
    }

    expect(() => findComponent(components, "nonexistent")).toThrow("Component 'nonexistent' not found!")
  })

  it("should handle index.vue files", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace/index.vue": MockComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockComponent)
  })

  it("should handle index.vue files with multiple nested paths", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/admin/workspace/index.vue": MockComponent,
      "../../lib/live_vue/web/pages/public/dashboard/index.vue": MockCreateWorkspaceComponent,
    }

    const result1 = findComponent(components, "workspace")
    const result2 = findComponent(components, "dashboard")

    expect(result1).toBe(MockComponent)
    expect(result2).toBe(MockCreateWorkspaceComponent)
  })

  it("should avoid false matches due to substring matching", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
      "../../lib/live_vue/web/pages/workspace.vue": MockComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockComponent)
  })
})
