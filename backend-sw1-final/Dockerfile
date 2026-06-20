# --- Build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
# Generate Prisma client before building
RUN npx prisma generate
RUN npm run build

# --- Production stage ---
FROM node:20-alpine AS production
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled output and generated Prisma client
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/generated ./generated
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts

EXPOSE 3000
# DATABASE_URL is injected by Azure Container Apps at runtime
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
