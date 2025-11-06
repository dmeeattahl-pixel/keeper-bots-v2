# Use Node 20 Alpine as base
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies with virtual package for easy cleanup
RUN apk add --no-cache --virtual .build-deps \
    python3 \
    make \
    g++ \
    git

# Copy package files
COPY package*.json ./
COPY yarn.lock* ./

# Install dependencies with increased memory and optimizations
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm ci --only=production --prefer-offline --no-audit

# Remove build dependencies to reduce image size
RUN apk del .build-deps

# Copy application code
COPY . .

# Build TypeScript
RUN npm run build || true

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install runtime dependencies only
RUN apk add --no-cache \
    python3 \
    tini

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/config.yaml ./config.yaml

# Use tini to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start the bot
CMD ["node", "dist/index.js"]
