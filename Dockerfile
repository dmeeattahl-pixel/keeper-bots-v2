# Multi-stage build for drift-labs/keeper-bots-v2
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies with memory optimization
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN bun install --production

# Copy source code
COPY . .

# Build the project
RUN bun run build

# Production stage
FROM oven/bun:1-alpine

WORKDIR /app

# Install tini for proper signal handling
RUN apk add --no-cache tini

# Copy built application and dependencies
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Set memory optimization for runtime
ENV NODE_OPTIONS="--max-old-space-size=512"

# Use tini as entrypoint
ENTRYPOINT ["/sbin/tini", "--"]

# Start the bot
CMD ["bun", "run", "dist/index.js"]
