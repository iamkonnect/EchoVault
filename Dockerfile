# Flutter Web Dockerfile
FROM node:18-alpine AS build-deps

WORKDIR /build

# Install Flutter dependencies
RUN apk add --no-cache git curl bash unzip

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git --branch stable --depth 1
ENV PATH="/build/flutter/bin:$PATH"

# Run Flutter doctor
RUN flutter doctor

# Build stage
FROM build-deps AS builder

WORKDIR /app

COPY . .

# Get dependencies
RUN flutter pub get

# Build web release
RUN flutter build web --release

# Runtime stage
FROM nginx:alpine

# Copy built Flutter web app to nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
