// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
/// <reference types="node" />

import tailwindcssForms from "@tailwindcss/forms"
import fs from "node:fs"
import path from "node:path"
import defaultTheme from "tailwindcss/defaultTheme"
import plugin from "tailwindcss/plugin"
import { CSSRuleObject, DarkModeConfig } from "tailwindcss/types/config"

export default {
  darkMode: 'selector' as DarkModeConfig,
  content: [
    "./js/**/*.js",
    "../lib/live_vue_examples_web.ex",
    "../lib/live_vue_examples_web/**/*.*ex",
    "./vue/**/*.vue",
    "../lib/**/*.vue"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        orange: {
          phoenix: '#FD4F00'
        }
      },
      fontFamily: {
        'sans': ['"Inter var"', "Inter", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    tailwindcssForms(),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values: Record<string, { name: string, fullPath: string }> = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": (options) => {
          if (typeof options === "string") return null
          const { name, fullPath } = options
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          const css:CSSRuleObject = Object.assign({
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
          }, size ? { width: size, height: size } : {})

          return css
        }
      }, { values })
    })
  ]
}
