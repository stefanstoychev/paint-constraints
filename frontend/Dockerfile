# ── Stage 1: Build Flutter Web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache pub dependencies separately from source code
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source and build for web
COPY . .
RUN flutter build web --release --base-href "/"

# ── Stage 2: Serve with Nginx ─────────────────────────────────────────────────
FROM nginx:alpine

# Remove the default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy the Flutter build output
COPY --from=build /app/build/web /usr/share/nginx/html

# Serve single-page app: fall back to index.html for client-side routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
