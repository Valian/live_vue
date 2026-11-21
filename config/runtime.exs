import Config

# Desktop Chrome for every test. Here, as config.exs runs before Playwright.device/1 is compiled.
if config_env() == :e2e do
  config :playwright, :test, Playwright.device("Desktop Chrome")
end
