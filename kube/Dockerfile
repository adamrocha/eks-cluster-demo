FROM nginx:alpine

# Create a non-root user and group
RUN addgroup -S -g 10001 appgroup && \
    adduser -S -u 10001 -G appgroup appuser

# Prepare necessary directories
RUN mkdir -p /var/cache/nginx /var/run /run /usr/share/nginx/html /etc/nginx/ssl

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy static content and config
COPY --chown=10001:10001 index.html /usr/share/nginx/html/index.html
COPY --chown=10001:10001 nginx.conf /etc/nginx/nginx.conf

# Set correct permissions
RUN chown -R 10001:10001 /var/cache/nginx /var/run /run /usr/share/nginx/html /etc/nginx/ssl

# Health check
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Run as non-root user
USER 10001:10001

# Expose non-privileged ports (HTTP and HTTPS)
EXPOSE 8080 8443

# Set working directory
WORKDIR /usr/share/nginx/html

# Start with entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]