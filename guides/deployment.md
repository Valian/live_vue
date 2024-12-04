# Deployment

Deploying a LiveVue app is similar to deploying a regular Phoenix app, with one key requirement: **Node.js version 19 or later must be installed** in your production environment.

## General Requirements

1. Node.js 19+ installed in production
2. Standard Phoenix deployment requirements
3. Build assets before deployment

## Fly.io Deployment Guide

Here's a detailed guide for deploying to [Fly.io](https://fly.io/). Similar principles apply to other hosting providers.

### 1. Generate Dockerfile

First, generate a Phoenix release Dockerfile:

```bash
mix phx.gen.release --docker
```

### 2. Modify Dockerfile

Update the generated Dockerfile to include Node.js:

```dockerfile
# Build Stage
FROM hexpm/elixir:1.14.4-erlang-25.3.2-debian-bullseye-20230227-slim AS builder

# Set environment variables
...(about 15 lines omitted)...

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js for build stage
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

# Copy application code
COPY . .

# Install npm dependencies
RUN cd /app/assets && npm install

...(about 20 lines omitted)...

# Production Stage
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js for production
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

...(remaining dockerfile content)...
```

Key changes:
- Add `curl` to build dependencies
- Install Node.js in both build and production stages
- Add npm install step for assets

### 3. Launch on Fly.io

1. Initialize your app:
```bash
fly launch
```

2. Configure database when prompted:
```bash
? Do you want to tweak these settings before proceeding? (y/N) y
```

3. In the configuration window:
   - Choose "Fly Postgres" for database
   - Name your database
   - Consider development configuration for cost savings
   - Review other settings as needed

4. After deployment completes, open your app:
```bash
fly apps open
```

## Other Deployment Options

### Heroku

For Heroku deployment:
1. Use the [Phoenix buildpack](https://hexdocs.pm/phoenix/heroku.html)
2. Add Node.js buildpack:
```bash
heroku buildpacks:add --index 1 heroku/nodejs
```

### Docker

If using your own Docker setup:
1. Ensure Node.js 19+ is installed
2. Follow standard Phoenix deployment practices
3. Configure SSR in production:
```elixir
# config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true
```

### Custom Server

For bare metal or VM deployments:
1. Install Node.js 19+:
```bash
curl -fsSL https://deb.nodesource.com/setup_19.x | bash -
apt-get install -y nodejs
```

2. Follow standard [Phoenix deployment guide](https://hexdocs.pm/phoenix/deployment.html)

## Production Checklist

- [ ] Node.js 19+ installed
- [ ] Assets built (`mix assets.build`)
- [ ] SSR configured properly
- [ ] Database configured
- [ ] Environment variables set
- [ ] SSL certificates configured (if needed)
- [ ] Production secrets generated
- [ ] Release configuration tested

## Troubleshooting

### Common Issues

1. **SSR Not Working**
   - Verify Node.js installation
   - Check SSR configuration
   - Ensure server bundle exists in `priv/vue/server.js`

2. **Asset Loading Issues**
   - Verify assets were built
   - Check digest configuration
   - Inspect network requests

3. **Performance Issues**
   - Consider adjusting NodeJS pool size:
```elixir
# in your application.ex
children = [
  {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
  # other children...
]
```

## Next Steps

- Review [FAQ](faq.html) for common questions
- Join our [GitHub Discussions](https://github.com/Valian/live_vue/discussions) for help
- Consider contributing to [LiveVue](https://github.com/Valian/live_vue)