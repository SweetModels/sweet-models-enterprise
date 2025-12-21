# TLS/HTTPS Configuration Guide

## Development Setup (Self-Signed Certificate)

### Windows (PowerShell)

1. **Install OpenSSL** (if not installed):
   - Download from: https://slproweb.com/products/Win32OpenSSL.html
   - Or use Chocolatey: `choco install openssl`

2. **Generate self-signed certificate**:
   ```powershell
   openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem -days 365 -subj "/CN=localhost"
   ```

3. **Configure .env**:
   ```env
   TLS_CERT_PATH=cert.pem
   TLS_KEY_PATH=key.pem
   ```

4. **Trust the certificate** (optional, to avoid browser warnings):
   ```powershell
   # Import certificate to Trusted Root Certification Authorities
   certutil -addstore -f "ROOT" cert.pem
   ```

### Linux/macOS

1. **Generate self-signed certificate**:
   ```bash
   openssl req -x509 -newkey rsa:4096 -nodes \
     -keyout key.pem -out cert.pem -days 365 \
     -subj "/CN=localhost"
   ```

2. **Configure .env**:
   ```env
   TLS_CERT_PATH=cert.pem
   TLS_KEY_PATH=key.pem
   ```

3. **Trust the certificate** (optional):
   - **macOS**: Add `cert.pem` to Keychain Access → System → Certificates
   - **Linux**: `sudo cp cert.pem /usr/local/share/ca-certificates/ && sudo update-ca-certificates`

## Production Setup (CA-Signed Certificate)

### Let's Encrypt (Free)

1. **Install Certbot**:
   ```bash
   # Ubuntu/Debian
   sudo apt install certbot
   
   # CentOS/RHEL
   sudo yum install certbot
   ```

2. **Obtain certificate**:
   ```bash
   sudo certbot certonly --standalone -d yourdomain.com
   ```

3. **Configure .env**:
   ```env
   TLS_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
   TLS_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem
   ```

4. **Auto-renewal** (cron job):
   ```bash
   sudo crontab -e
   # Add: 0 0 * * * certbot renew --quiet
   ```

### Commercial CA

1. **Generate CSR** (Certificate Signing Request):
   ```bash
   openssl req -new -newkey rsa:4096 -nodes -keyout key.pem -out csr.pem
   ```

2. **Submit CSR to CA** (e.g., DigiCert, GlobalSign)

3. **Download certificate** from CA

4. **Configure .env**:
   ```env
   TLS_CERT_PATH=/path/to/certificate.crt
   TLS_KEY_PATH=/path/to/private.key
   ```

## Testing HTTPS

### cURL
```bash
# Self-signed (skip verification)
curl -k https://localhost:3000/health

# Trusted certificate
curl https://yourdomain.com:3000/health
```

### Browser
- Navigate to `https://localhost:3000/health`
- For self-signed certs, accept security warning

## Troubleshooting

### Certificate Not Found
```
❌ Certificate file not found: cert.pem
```
**Solution**: Verify paths in `.env` are correct and files exist

### Permission Denied
```
❌ Failed to load TLS config: Permission denied
```
**Solution**: Check file permissions:
```bash
chmod 644 cert.pem
chmod 600 key.pem  # Private key should be restricted
```

### Invalid Certificate
```
❌ Failed to load TLS config: Invalid certificate
```
**Solution**: Regenerate certificate or check format (PEM)

### Port Already in Use
```
❌ Address already in use (os error 98)
```
**Solution**: Stop conflicting process or change port

## Security Best Practices

1. **Never commit certificates** to version control
   - Add to `.gitignore`: `*.pem`, `*.key`, `*.crt`

2. **Restrict private key permissions**:
   ```bash
   chmod 600 key.pem
   ```

3. **Use strong keys** (4096-bit RSA minimum)

4. **Rotate certificates** before expiration

5. **Production**: Always use CA-signed certificates

6. **Monitor certificate expiration**:
   ```bash
   openssl x509 -in cert.pem -noout -enddate
   ```

## Fallback to HTTP

If TLS configuration is missing or invalid, the server automatically falls back to HTTP:
```
ℹ️  TLS not configured (TLS_CERT_PATH/TLS_KEY_PATH not set)
   Running in HTTP mode (not recommended for production)
🌐 HTTP/WebSocket server escuchando en http://0.0.0.0:3000
```

To enable HTTPS, set `TLS_CERT_PATH` and `TLS_KEY_PATH` in `.env`.
