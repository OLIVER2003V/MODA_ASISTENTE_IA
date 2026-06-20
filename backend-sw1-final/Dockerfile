# --- Build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
# Generate Prisma client before building
RUN npx prisma generate
RUN npm run build
RUN echo "=== dist/ contents ===" && ls -la dist/ \
    && echo "=== checking dist/main.js ===" \
    && test -f dist/main.js \
    && echo "OK: dist/main.js found"

# --- Production stage ---
FROM node:20-alpine AS production
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled output and generated Prisma client
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/generated ./generated
COPY --from=builder /app/prisma ./prisma

EXPOSE 3000
CMD ["node", "dist/main"]
