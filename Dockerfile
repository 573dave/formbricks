# ---- Builder stage -------------------------------------------------
FROM node:22-alpine AS builder

# Enable corepack so pnpm works
RUN corepack enable

WORKDIR /app

# Copy monorepo configs first for better layer caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Copy only what we need to build the web app
COPY apps ./apps
COPY packages ./packages

# Install deps (uses pnpm-lock.yaml)
RUN pnpm install --frozen-lockfile

# Build the web app (workspace name may be "web" or "@formbricks/web")
# Adjust the filter if their workspace name is different.
RUN pnpm turbo run build --filter=web...

# ---- Runtime stage -------------------------------------------------
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

# Copy built artifacts & runtime files from builder
COPY --from=builder /app/apps/web ./
# If you hit "missing module" errors, you can instead copy the whole repo:
# COPY --from=builder /app ./

# Next.js usually serves from .next
EXPOSE 3000

# If apps/web/package.json uses "start": "next start"
CMD ["pnpm", "start"]
