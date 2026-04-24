# Deployment

Deploying a LiveVue app is similar to deploying a regular Phoenix app.

By default, LiveVue uses `LiveVue.SSR.QuickBEAM` for production SSR, which runs JavaScript
inside the BEAM — **no Node.js required in production**.

> #### Need Node.js instead? {: .tip}
>
> If you prefer the Node.js-based SSR, you can switch to `LiveVue.SSR.NodeJS`.
> See [Configuration](configuration.md#server-side-rendering-ssr) for details.
> This requires Node.js 19+ installed in production and `NodeJS.Supervisor` in your supervision tree.

## General Requirements

1. Standard Phoenix deployment requirements
2. Build assets before deployment (requires Node.js at **build time** only)
3. QuickBEAM hex dependency (`{:quickbeam, "~> 0.8"}`)

## Fly.io Deployment Guide

Here's a detailed guide for deploying to [Fly.io](https://fly.io/). Similar principles apply to other hosting providers.

### 1. Generate Dockerfile

First, generate a Phoenix release Dockerfile:

```bash
mix phx.gen.release --docker
```

### 2. Modify Dockerfile

Update the generated Dockerfile to install Node.js in the **build stage only** (for compiling assets):

```dockerfile
# Build Stage
FROM hexpm/elixir:1.14.4-erlang-25.3.2-debian-bullseye-20230227-slim AS builder

# Set environment variables
...

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js for building assets
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

# Copy application code
COPY . .

# Install npm dependencies
RUN npm install

...

# Production Stage — no Node.js needed!
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

...(remaining dockerfile content)...
```

Key points:
- Add `curl` to build dependencies
- Install Node.js **only in the build stage** for asset compilation
- No Node.js needed in the production stage — QuickBEAM handles SSR natively

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
2. Add Node.js buildpack for asset compilation:
```bash
heroku buildpacks:add --index 1 heroku/nodejs
```

### Docker

If using your own Docker setup:
1. Install Node.js in the build stage for asset compilation
2. Follow standard Phoenix deployment practices
3. No Node.js needed at runtime — QuickBEAM runs SSR inside the BEAM

### Custom Server

For bare metal or VM deployments:
1. Build assets on the build machine (requires Node.js)
2. Deploy the release — no Node.js needed on the production server
3. Follow standard [Phoenix deployment guide](https://hexdocs.pm/phoenix/deployment.html)

## Production Checklist

- [ ] Assets built (`mix assets.deploy`, which also creates `priv/static/server.mjs`)
- [ ] SSR configured properly (see [Configuration](configuration.md#production-ssr-setup))
- [ ] `LiveVue.SSR.QuickBEAM` added to supervision tree
- [ ] Database configured
- [ ] Environment variables set
- [ ] SSL certificates configured (if needed)
- [ ] Production secrets generated
- [ ] Release configuration tested

## Troubleshooting

### Common Issues

1. **SSR Not Working**
   - Check SSR configuration (see [Configuration](configuration.md#ssr-troubleshooting))
   - Ensure server bundle exists in `priv/static/server.mjs`
   - Verify `LiveVue.SSR.QuickBEAM` is in your supervision tree

2. **Asset Loading Issues**
   - Verify assets were built
   - Check digest configuration
   - Inspect network requests

3. **QuickBEAM Errors**
   - Ensure `{:quickbeam, "~> 0.8"}` is in your dependencies
   - Verify server bundle was built correctly

## Next Steps

- Review [FAQ](faq.md) for common questions
- Join our [GitHub Discussions](https://github.com/Valian/live_vue/discussions) for help
- Consider contributing to [LiveVue](https://github.com/Valian/live_vue)
