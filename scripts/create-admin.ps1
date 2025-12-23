# Configuración del Admin
$Url = "https://sweet-models-enterprise-production.up.railway.app/auth/register"
$Body = @{
    username = "IsaiasCEO"
    email    = "admin@sweetmodels.com"
    password = "admin123"
}
$JsonBody = $Body | ConvertTo-Json

Write-Host "🚀 Conectando con Sweet Models Enterprise (Railway)..." -ForegroundColor Cyan

try {
    $Response = Invoke-RestMethod -Uri $Url -Method POST -Body $JsonBody -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "✅ ¡ÉXITO! Usuario Administrador Creado." -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "Usuario: IsaiasCEO"
    Write-Host "Email:   admin@sweetmodels.com"
    Write-Host "Pass:    admin123"
    Write-Host "----------------------------------------"
}
catch {
    Write-Host "❌ ERROR AL CREAR USUARIO" -ForegroundColor Red
    
    # Manejo de errores universal (Compatible con PowerShell moderno)
    if ($_.Exception.Response) {
        # Intentamos leer el cuerpo del error
        try {
            # Método moderno para PowerShell Core / 7+
            $ErrorBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
        }
        catch {
            # Método fallback para PowerShell antiguo
            try {
                $Stream = $_.Exception.Response.GetResponseStream()
                $Reader = New-Object System.IO.StreamReader($Stream)
                $ErrorBody = $Reader.ReadToEnd()
            }
            catch {
                $ErrorBody = $_.Exception.Message
            }
        }
        Write-Host "Servidor Dice: $ErrorBody" -ForegroundColor Yellow
    }
    else {
        Write-Host "Error de Conexión: $($_.Exception.Message)" -ForegroundColor Red
    }
}