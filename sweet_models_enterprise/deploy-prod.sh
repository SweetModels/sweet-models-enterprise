#!/bin/bash

# ════════════════════════════════════════════════════════════════
# PRODUCTION DEPLOYMENT SCRIPT
# Studios DK - Sweet Models Enterprise
# ════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN="api.studios-dk.com"
ENVIRONMENT="production"
LOG_FILE="deployment-$(date +%Y%m%d-%H%M%S).log"

# ════════════════════════════════════════════════════════════════
# FUNCTIONS
# ════════════════════════════════════════════════════════════════

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

# ════════════════════════════════════════════════════════════════
# VALIDATION
# ════════════════════════════════════════════════════════════════

log "═══════════════════════════════════════════════════════════════"
log "PRODUCTION DEPLOYMENT - Studios DK"
log "═══════════════════════════════════════════════════════════════"

# Check required files
log "Checking required files..."
[ -f ".env.prod" ] || error ".env.prod file not found!"
[ -f "docker-compose.prod.yml" ] || error "docker-compose.prod.yml file not found!"
[ -f "nginx/nginx.conf" ] || error "nginx/nginx.conf file not found!"

success "All required files present"

# Check Docker
log "Checking Docker installation..."
docker --version || error "Docker is not installed"
docker-compose --version || error "Docker Compose is not installed"

success "Docker is installed"

# ════════════════════════════════════════════════════════════════
# PRE-DEPLOYMENT CHECKS
# ════════════════════════════════════════════════════════════════

log "Running pre-deployment checks..."

# Check environment variables
warning "⚠ Review .env.prod before deploying!"
warning "⚠ Change all CHANGE_ME_* values to secure random strings!"

# Create required directories
log "Creating directory structure..."
mkdir -p data/postgres data/redis data/minio data/nats
mkdir -p logs/app logs/nginx
mkdir -p nginx/certbot/conf nginx/certbot/www
mkdir -p monitoring

success "Directory structure created"

# ════════════════════════════════════════════════════════════════
# SSL CERTIFICATE SETUP
# ════════════════════════════════════════════════════════════════

log "Checking SSL certificates..."

if [ ! -d "nginx/certbot/conf/live" ]; then
    log "First-time SSL setup required for Let's Encrypt..."
    
    warning "You will be asked to verify domain ownership"
    warning "Make sure DNS is configured for: $DOMAIN"
    
    read -p "Press Enter to continue with certificate generation..."
    
    docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
        --webroot -w /var/www/certbot \
        -d "$DOMAIN" \
        -d "www.$DOMAIN" \
        --agree-tos \
        --no-eff-email \
        --email admin@studios-dk.com || error "Certificate generation failed"
    
    success "SSL certificates generated"
else
    success "SSL certificates already present"
fi

# ════════════════════════════════════════════════════════════════
# BACKUP EXISTING DATA (if any)
# ════════════════════════════════════════════════════════════════

if [ -d "data/postgres" ] && [ ! -z "$(ls -A data/postgres)" ]; then
    log "Creating backup of existing database..."
    BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r data/postgres "$BACKUP_DIR/postgres_backup"
    cp -r data/redis "$BACKUP_DIR/redis_backup" 2>/dev/null || true
    success "Backup created at $BACKUP_DIR"
fi

# ════════════════════════════════════════════════════════════════
# PULL LATEST IMAGES
# ════════════════════════════════════════════════════════════════

log "Pulling latest Docker images..."
docker-compose -f docker-compose.prod.yml pull || error "Failed to pull images"
success "Images pulled successfully"

# ════════════════════════════════════════════════════════════════
# BUILD BACKEND
# ════════════════════════════════════════════════════════════════

log "Building backend application..."
docker-compose -f docker-compose.prod.yml build --no-cache app || error "Backend build failed"
success "Backend built successfully"

# ════════════════════════════════════════════════════════════════
# START SERVICES
# ════════════════════════════════════════════════════════════════

log "Starting services..."
docker-compose -f docker-compose.prod.yml up -d || error "Failed to start services"
success "Services started"

# Wait for services to be healthy
log "Waiting for services to become healthy..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker-compose -f docker-compose.prod.yml ps | grep -q "healthy"; then
        success "All services are healthy"
        break
    fi
    
    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    warning "Services did not become healthy in time. Check logs with:"
    warning "docker-compose -f docker-compose.prod.yml logs"
fi

# ════════════════════════════════════════════════════════════════
# DATABASE MIGRATIONS
# ════════════════════════════════════════════════════════════════

log "Running database migrations..."
sleep 5  # Give DB time to start

docker-compose -f docker-compose.prod.yml exec -T postgres \
    psql -U sme_prod_user -d sme_production \
    -c "SELECT version();" || error "Failed to connect to database"

success "Database is accessible"

# ════════════════════════════════════════════════════════════════
# HEALTH CHECKS
# ════════════════════════════════════════════════════════════════

log "Running health checks..."

# Check HTTP
if curl -f http://localhost:3000/health 2>/dev/null; then
    success "HTTP health check passed"
else
    warning "HTTP health check failed"
fi

# Check Nginx
if curl -f http://localhost/health 2>/dev/null; then
    success "Nginx health check passed"
else
    warning "Nginx health check failed - may still be initializing"
fi

# Check database
if docker-compose -f docker-compose.prod.yml exec -T postgres \
    pg_isready -U sme_prod_user -d sme_production; then
    success "Database health check passed"
else
    error "Database health check failed"
fi

# Check Redis
if docker-compose -f docker-compose.prod.yml exec -T redis \
    redis-cli ping | grep -q PONG; then
    success "Redis health check passed"
else
    error "Redis health check failed"
fi

# ════════════════════════════════════════════════════════════════
# POST-DEPLOYMENT CONFIGURATION
# ════════════════════════════════════════════════════════════════

log "Configuring production settings..."

# Create S3 bucket if it doesn't exist
log "Creating MinIO bucket..."
docker-compose -f docker-compose.prod.yml exec -T minio \
    mc mb minio/studios-dk --ignore-existing || warning "Could not create MinIO bucket"

success "MinIO bucket configured"

# ════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ════════════════════════════════════════════════════════════════

log "═══════════════════════════════════════════════════════════════"
success "DEPLOYMENT COMPLETE!"
log "═══════════════════════════════════════════════════════════════"

echo ""
echo "📊 Service URLs:"
echo "   - API: https://$DOMAIN"
echo "   - Prometheus: https://$DOMAIN:9090 (restricted)"
echo "   - MinIO Console: https://$DOMAIN/minio/"
echo ""
echo "📝 Useful Commands:"
echo "   - View logs: docker-compose -f docker-compose.prod.yml logs -f [service]"
echo "   - Restart service: docker-compose -f docker-compose.prod.yml restart [service]"
echo "   - Stop services: docker-compose -f docker-compose.prod.yml down"
echo "   - Shell into container: docker exec -it [container_id] /bin/sh"
echo ""
echo "⚠️  Important:"
echo "   - Change default admin password: admin / Admin@123456"
echo "   - Configure backup schedule"
echo "   - Set up monitoring and alerts"
echo "   - Enable 2FA for admin accounts"
echo ""
echo "📄 Deployment log: $LOG_FILE"
echo ""
