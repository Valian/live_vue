import { getRender } from "../../../assets/server.ts"
import { createLiveVue } from "../../../assets/app.ts"
import { findComponent } from "../../../assets/utils.ts"

const components = {
  ...import.meta.glob("../features/**/*.vue", { eager: true }),
}

export const render = getRender(
  createLiveVue({
  resolve: name => findComponent(components, name),
  })
)
