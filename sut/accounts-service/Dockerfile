FROM node:24-alpine
WORKDIR /app
RUN npm install -g pnpm@12.3.4
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod
COPY src ./src
ENV NODE_ENV=production
USER node
CMD ["node", "src/index.ts"]
