# Modo B: banco e backend no Docker, servidor Java rodando neste terminal
# (com os comandos "status" e "desativar").
#
# Uso:  .\scripts\modo-b.ps1            (rapido; reconstroi so se faltar imagem)
#       .\scripts\modo-b.ps1 -Build     (reconstroi o backend antes)
param([switch]$Build)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

function Falhar($mensagem) {
    Write-Host "ERRO: $mensagem" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Falhar "Docker nao encontrado. Abra o Docker Desktop." }
docker info *> $null
if ($LASTEXITCODE -ne 0) { Falhar "O Docker nao esta rodando. Abra o Docker Desktop e tente de novo." }
if (-not (Get-Command javac -ErrorAction SilentlyContinue)) { Falhar "Java 17 (javac) nao encontrado no PATH." }
if (-not (Test-Path .env)) { Falhar "Falta o arquivo .env na raiz. Veja o passo 2 do README (copy env.example .env)." }

Write-Host "==> Parando o servidor do Docker (se estiver rodando)..."
docker compose stop servidor *> $null

Write-Host "==> Subindo banco e backend (espera ficarem prontos)..."
$argumentos = @('compose', 'up', '-d', '--wait')
if ($Build) { $argumentos += '--build' }
$argumentos += @('mongo', 'backend')
& docker @argumentos
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "O backend nao ficou pronto. Ultimas linhas do log:" -ForegroundColor Yellow
    docker compose logs --tail 25 backend
    Write-Host ""
    Write-Host "Se aparecer SSLException/MongoTimeoutException com mongodb.net, libere seu IP no Atlas"
    Write-Host "ou comente MONGODB_URI no .env para usar o banco local."
    exit 1
}

Write-Host "==> Compilando o servidor Java..."
if (Test-Path servidor\out) { Remove-Item -Recurse -Force servidor\out }
New-Item -ItemType Directory servidor\out | Out-Null
javac -d servidor\out (Get-ChildItem servidor\src\*.java).FullName
if ($LASTEXITCODE -ne 0) { Falhar "Falha ao compilar o servidor." }

Write-Host "==> Servidor no ar. Digite status ou desativar."
Set-Location servidor
java -cp out Servidor
