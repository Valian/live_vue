# Used by "mix format"
[
  import_deps: [:phoenix],
  line_length: 120,
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["{mix,.formatter}.exs", "{config,e2e_pw,lib,test}/**/*.{ex,exs}"]
]
