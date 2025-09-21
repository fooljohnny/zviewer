# Build stage
FROM golang:1.21-alpine AS builder

# Install FFmpeg and build dependencies
RUN apk add --no-cache \
    ffmpeg \
    build-base \
    pkgconfig \
    cairo-dev \
    jpeg-dev \
    png-dev \
    giflib-dev

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/api

# Final stage
FROM alpine:latest

# Install FFmpeg and runtime dependencies
RUN apk add --no-cache \
    ffmpeg \
    ca-certificates \
    tzdata

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Create uploads directory
RUN mkdir -p /uploads/media

# Expose port
EXPOSE 8081

# Run the application
CMD ["./main"]
