# Build stage
FROM node:20-alpine AS build
WORKDIR /app

# Layer cache: deps first
COPY package.json package-lock.json* ./
RUN npm ci || npm install

COPY . .
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL:-}
RUN npm run build

# Runtime stage (nginx)
FROM nginx:alpine AS runtime
RUN adduser -D -g '' appuser

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chown -R appuser:appuser /usr/share/nginx/html
USER appuser

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
