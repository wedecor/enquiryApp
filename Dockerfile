FROM node:lts-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production --silent

# Copy TypeScript configuration
COPY tsconfig.json ./

# Copy source code
COPY src/ ./src/
COPY scripts/ ./scripts/

# Install TypeScript and tsx for runtime
RUN npm install -g tsx typescript

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S seeder -u 1001 -G nodejs

# Change ownership
RUN chown -R seeder:nodejs /app
USER seeder

# Default command
CMD ["npm", "run", "seed"]

