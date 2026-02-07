FROM nginx:alpine-slim

# Install OpenSSL for certificate generation
RUN apk update && apk add --no-cache openssl

# Create a non-root user and group
RUN addgroup -S -g 10001 appgroup && \
    adduser -S -u 10001 -G appgroup appuser

# Prepare necessary directories
RUN mkdir -p /var/cache/nginx /var/run /run /usr/share/nginx/html /etc/nginx/ssl

# Copy certificate generation script
COPY generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/generate-certs.sh

# Generate self-signed certificates
RUN /usr/local/bin/generate-certs.sh

# Copy static content and config
COPY --chown=10001:10001 index.html /usr/share/nginx/html/index.html
COPY --chown=10001:10001 nginx.conf /etc/nginx/nginx.conf

# Set correct permissions
RUN chown -R 10001:10001 /var/cache/nginx /var/run /run /usr/share/nginx/html /etc/nginx/ssl

# Health check (check both HTTP and HTTPS)
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8080/ || exit 1

# Run as non-root user
USER 10001:10001

# Expose non-privileged ports (HTTP and HTTPS)
EXPOSE 8080 8443

# Set working directory
WORKDIR /usr/share/nginx/html

# Disable default entrypoint
ENTRYPOINT []

# Start nginx with custom config
CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]