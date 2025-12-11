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

# Build arguments
ARG NODE_ENV=production
ARG VITE_API_URL=https://api.orthotrack.alexptech.com
ARG VITE_WS_URL=wss://api.orthotrack.alexptech.com/ws

# Set environment variables
ENV NODE_ENV=$NODE_ENV
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_WS_URL=$VITE_WS_URL

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install wget for healthcheck
RUN apk add --no-cache wget

# Create app directory
WORKDIR /app

# Copy built application (SvelteKit adapter-node output)
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S sveltekit -u 1001

# Change ownership
RUN chown -R sveltekit:nodejs /app
USER sveltekit

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application using SvelteKit's built-in Node server
CMD ["node", "build"]