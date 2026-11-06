# Stage 1: instala TODAS as dependências (inclusive devDependencies).
# Copiar só os package*.json antes do código aproveita o cache de camadas:
# o npm ci só roda de novo se as dependências mudarem.
FROM node:24-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: roda lint e testes. O CI faz: docker build --target test .
# Se lint ou teste falhar, o build falha.
FROM deps AS test
COPY . .
RUN npm ci-cd-test run lint && npm test

# Stage 3: compila TypeScript para dist/
FROM deps AS build
COPY . .
RUN npm run build

# Stage 4: imagem final de produção, só com o necessário para rodar.
FROM node:24-slim AS prod
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/main"]
