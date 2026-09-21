FROM node:16-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci || npm install
COPY . .
RUN npm run build

FROM node:16-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY package*.json ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev
ENV PORT=3000
EXPOSE 3000
CMD ["node", "dist/main"]
