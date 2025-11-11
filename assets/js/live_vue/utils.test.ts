import { describe, it, expect } from "vitest"
import { findComponent } from "./utils"
import type { ComponentMap } from "./types"

describe("findComponent", () => {
  const MockWorkspaceComponent = {
    template: "<div>Mock Component</div>",
  }

  const MockCreateWorkspaceComponent = {
    template: "<div>Create Workspace Component</div>",
  }

  it("should find exact component match for 'workspace'", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockWorkspaceComponent)
  })

  it("should NOT match 'workspace' to 'create-workspace'", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
      "../../lib/live_vue/web/pages/workspace.vue": MockWorkspaceComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockWorkspaceComponent)
  })

  it("should find 'create-workspace' component when requested", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
    }

    const result = findComponent(components, "create-workspace")

    expect(result).toBe(MockCreateWorkspaceComponent)
  })

  it("should throw error when component is not found", () => {
    const components: ComponentMap = {
      "../../lib/leuchtturm/web/pages/workspace.vue": MockWorkspaceComponent,
    }

    expect(() => findComponent(components, "nonexistent")).toThrow("Component 'nonexistent' not found!")
  })

  it("should handle index.vue files", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace/index.vue": MockWorkspaceComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockWorkspaceComponent)
  })

  it("should handle index.vue files with multiple nested paths", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/admin/workspace/index.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/pages/public/dashboard/index.vue": MockCreateWorkspaceComponent,
    }

    const result1 = findComponent(components, "workspace")
    const result2 = findComponent(components, "dashboard/index.vue")

    expect(result1).toBe(MockWorkspaceComponent)
    expect(result2).toBe(MockCreateWorkspaceComponent)
  })

  it("should avoid false matches due to substring matching", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/create-workspace.vue": MockCreateWorkspaceComponent,
      "../../lib/live_vue/web/pages/workspace.vue": MockWorkspaceComponent,
    }

    const result = findComponent(components, "workspace")

    expect(result).toBe(MockWorkspaceComponent)
  })

  it("should find component by path suffix", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/components/admin/workspace.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/components/public/workspace.vue": MockCreateWorkspaceComponent,
    }

    const result1 = findComponent(components, "admin/workspace")
    const result2 = findComponent(components, "public/workspace.vue")

    expect(result1).toBe(MockWorkspaceComponent)
    expect(result2).toBe(MockCreateWorkspaceComponent)
  })

  it("should throw ambiguous error when filename matches multiple components", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/components/workspace/index.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/components/create/workspace.vue": MockCreateWorkspaceComponent,
    }

    expect(() => findComponent(components, "workspace")).toThrow("Component 'workspace' is ambiguous")
  })

  it("should throw ambiguous error for multiple index.vue matches", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/admin/workspace/index.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/pages/user/workspace/index.vue": MockCreateWorkspaceComponent,
    }

    expect(() => findComponent(components, "workspace")).toThrow("Component 'workspace' is ambiguous")
  })

  it("should handle mix of index.vue and regular .vue files", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace/index.vue": MockWorkspaceComponent,
      "../../lib/live_vue/web/pages/workspace.vue": MockCreateWorkspaceComponent,
    }
    
    expect(() => findComponent(components, "workspace")).toThrow("Component 'workspace' is ambiguous")
  })

  it("should handle empty component name gracefully", () => {
    const components: ComponentMap = {
      "../../lib/live_vue/web/pages/workspace.vue": MockWorkspaceComponent,
    }

    expect(() => findComponent(components, "")).toThrow("Component '' not found!")
  })
})
