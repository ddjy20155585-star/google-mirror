Set-Location D:\test

Write-Host "=== Push to GitHub ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] git add ." -ForegroundColor Yellow
git add .
if ($LASTEXITCODE -ne 0) { Write-Host "git add failed" -ForegroundColor Red; Read-Host; exit 1 }

Write-Host ""
Write-Host "[2/3] git commit" -ForegroundColor Yellow
git commit -m "auto update"
# 没有改动时 commit 返回非零，忽略

Write-Host ""
Write-Host "[3/3] git push" -ForegroundColor Yellow
git push
if ($LASTEXITCODE -ne 0) { Write-Host "git push failed" -ForegroundColor Red; Read-Host; exit 1 }

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Open https://ddjy20155585-star.github.io/google-mirror/ in 1-2 minutes."
Read-Host "Press Enter to exit"