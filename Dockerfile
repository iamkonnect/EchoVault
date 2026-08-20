FROM ghcr.io/cirruslabs/flutter:3.29.1 AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# ✅ Build Flutter web with API_BASE_URL from build argument
# Default: https://api.echovaultz.com (can be overridden at build time)
ARG API_BASE_URL=https://api.echovaultz.com
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# Serve with nginx
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

RUN chmod -R a+rX /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
