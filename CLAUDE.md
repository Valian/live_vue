# LiveVue Library Development with Claude Code

This is the LiveVue library itself - an Elixir library that integrates Vue.js with Phoenix LiveView.

## Project Structure

- **lib/**: Core LiveVue library code (components, SSR, encoding, etc.)
- **assets/**: Frontend TypeScript/JavaScript assets that get packaged with the library
- **guides/**: Comprehensive documentation for LiveVue users
- **example_project/**: Phoenix project using LiveVue directly from parent directory for testing

## Development Commands

### Testing

#### Elixir Tests
```bash
mix test
```
Runs the library test suite.

#### Frontend Tests
```bash
npm test
# or via Mix alias:
mix assets.test
```
Runs the frontend test suite using Vitest. Tests are located in `assets/js/live_vue/*.test.ts`.

Additional test commands:
- `npm run test:watch` - Run tests in watch mode
- `npm run test:ui` - Run tests with interactive UI

### Asset Watching (Development)
```bash
mix assets.watch
```
This command watches for changes in assets and rebuilds automatically. Essential for development workflow. Developer said it's always running in the background, you don't need to run it manually.

### Build Assets
```bash
mix assets.build
```
Builds all assets for the library. Not needed most of the time, as assets are built automatically in the background.

### Setup
```bash
mix setup
```
Sets up dependencies and builds assets for the first time.

## Testing Changes

### Example Project
```bash
cd example_project
mix phx.server
```
Visit http://localhost:4000 to test LiveVue features. Changes to the parent library are reflected immediately.

## Library Structure

### Core Modules
- **LiveVue.Components**: Component helpers and macros
- **LiveVue.SSR**: Server-side rendering (Node.js and Vite.js)
- **LiveVue.Encoder**: JSON encoding for Vue props
- **LiveVue.Diff**: Efficient prop diffing for WebSocket updates

### Key Technologies
- Elixir/Phoenix for server-side integration
- Vue 3 with TypeScript for client-side components
- Vite for fast development and building
- Server-side rendering support
- JSON patch diffing for efficient updates
- Vitest for frontend testing with TypeScript support

## CI/CD

The project uses two separate GitHub Actions workflows:

- **Elixir CI** (`.github/workflows/elixir.yml`): Tests Elixir code across multiple Elixir/OTP versions
- **Frontend CI** (`.github/workflows/frontend.yml`): Tests frontend TypeScript code across Node.js versions 20, 22, and 24

Both workflows run on pushes to main and pull requests.

## Important Notes

- This is a library, not an application - use `example_project/` for testing
- `mix assets.watch` should be running in the background, you don't need to run it manually.
- Changes to library code are immediately available in `example_project/`
- Assets are TypeScript/JavaScript files that get packaged with the hex package