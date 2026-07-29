# --- Build stage: compile the Flutter web app ---
FROM ghcr.io/cirruslabs/flutter:3.32.0 AS build

WORKDIR /app

# Build-time variable, provided by Railway as a service variable
ARG API_BASE_URL=http://localhost:8000

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# --- Runtime stage: serve the compiled static site ---
FROM node:20-alpine

WORKDIR /app
RUN npm install -g serve

COPY --from=build /app/build/web ./build/web

CMD ["sh", "-c", "serve -s build/web -l ${PORT:-8080}"]
