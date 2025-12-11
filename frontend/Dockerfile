# Frontend Dockerfile for Production
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies needed for build)
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Fix permissions for node_modules/.bin
RUN chmod -R +x node_modules/.bin

# Build arguments - CRÍTICO!
ARG PUBLIC_API_URL=https://orthotrack.alexptech.com/api
ARG PUBLIC_WS_URL=wss://orthotrack.alexptech.com/ws

# Set environment variables for build
ENV NODE_ENV=production
ENV PUBLIC_API_URL=${PUBLIC_API_URL}
ENV PUBLIC_WS_URL=${PUBLIC_WS_URL}

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install wget for healthcheck
RUN apk add --no-cache wget

# Create app directory
WORKDIR /app

# Copy package files
COPY --from=builder /app/package*.json ./

# Install production dependencies only
RUN npm ci --only=production --legacy-peer-deps

# Copy built app
COPY --from=builder /app/build ./build

# Copy static files if they exist
COPY --from=builder /app/static ./static 2>/dev/null || true

# Environment variables for runtime
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
ENV ORIGIN=https://orthotrack.alexptech.com
ENV PUBLIC_API_URL=https://orthotrack.alexptech.com/api
ENV PUBLIC_WS_URL=wss://orthotrack.alexptech.com/ws

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application using SvelteKit's built-in Node server
CMD ["node", "build"]