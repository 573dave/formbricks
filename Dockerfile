# ---- Builder stage -------------------------------------------------
FROM node:22-alpine AS builder

# Enable pnpm via corepack
RUN corepack enable

WORKDIR /app

# Copy monorepo configs first (for layer caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Copy workspaces (you may also have `packages/` or others)
COPY apps ./apps
COPY packages ./packages

# Install all workspace deps using pnpm
RUN pnpm install --frozen-lockfile

# Build ONLY the web app workspace (@formbricks/web)
RUN pnpm --filter @formbricks/web build

# ---- Runtime stage -------------------------------------------------
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

# We’ll copy the whole repo over to be safe (keeps prisma/i18n/etc)
COPY --from=builder /app ./

# Expose the port Formbricks uses
EXPOSE 3000

# Start the web app using its package.json scripts
CMD ["pnpm", "--filter", "@formbricks/web", "start"]
