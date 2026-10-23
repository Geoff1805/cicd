<#
.SYNOPSIS
    Pipeline CI/CD Local-First Ultra-Rapide (0 minute GitHub Actions consommée)
    Dev -> Test -> Compilation Release R8 -> Git Tag -> GitHub Release (InstallAPK) -> Cloudflare Pages

.DESCRIPTION
    Script d'automatisation locale certifié pour l'écosystème Antigravity.
    Compile en local (vitesse SSD + caches Gradle), normalise le binaire selon la Règle 6,
    publie la release GitHub pour l'application InstallAPK et déploie la web app sur Cloudflare Pages.
#>
param(
    [string]$Version = "",
    [switch]$SkipTests = $false,
    [switch]$SkipBuild = $false,
    [switch]$DeployWeb = $true,
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

# Verrou anti-collision (Règle 16)
$LockFile = ".build.lock"
if (Test-Path $LockFile) {
    $LockTime = (Get-Item $LockFile).LastWriteTime
    Write-Warning "⚠️ Un fichier $LockFile actif existe déjà (datant de $LockTime)."
    $Confirm = Read-Host "Un autre build est peut-être en cours. Voulez-vous continuer quand même ? (o/N)"
    if ($Confirm -ne "o" -and $Confirm -ne "O") {
        Write-Error "Arrêt par sécurité anti-collision multi-chats (Règle 16)."
    }
}

# Pose du marqueur de compilation éphémère
Set-Content -Path $LockFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force

try {
    # 1. Détection du Nom de l'Application et de la Version
    $AppName = (Get-Item .).Name
    if (Test-Path "settings.gradle.kts") {
        $RootProject = Get-Content "settings.gradle.kts" | Select-String 'rootProject.name\s*=\s*"(.*)"'
        if ($RootProject -and $RootProject.Matches[0].Groups[1].Value) {
            $AppName = $RootProject.Matches[0].Groups[1].Value
        }
    }

    if (-not $Version) {
        if (Test-Path "version.properties") {
            $VersionLine = Get-Content "version.properties" | Select-String "versionName"
            if ($VersionLine) {
                $Version = $VersionLine.Line.Split("=")[1].Trim()
            }
        } elseif (Test-Path "package.json") {
            $Version = (Get-Content "package.json" | ConvertFrom-Json).version
        }
    }

    if (-not $Version) {
        Write-Error "❌ Impossible de déterminer la version. Spécifiez -Version X.Y.Z"
    }

    $Tag = "v$Version"
    $ApkName = "$AppName-$Tag.apk"

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "🚀 Pipeline de Release Local : $AppName ($Tag)" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 2. Exécution des Tests Unitaires Locaux
    if (-not $SkipTests) {
        if (Test-Path "gradlew") {
            Write-Host "`n🧪 [1/5] Exécution des tests unitaires Gradle..." -ForegroundColor Yellow
            ./gradlew testDebugUnitTest --no-daemon
            Write-Host "✅ Tests unitaires validés avec succès." -ForegroundColor Green
        } elseif (Test-Path "package.json") {
            $pkg = Get-Content "package.json" | ConvertFrom-Json
            if ($pkg.scripts.test) {
                Write-Host "`n🧪 [1/5] Exécution des tests npm..." -ForegroundColor Yellow
                npm test
            }
        }
    } else {
        Write-Host "`n⏩ [1/5] Tests unitaires ignorés (-SkipTests)." -ForegroundColor DarkGray
    }

    # 3. Compilation Release Locale
    if (-not $SkipBuild) {
        if (Test-Path "gradlew") {
            Write-Host "`n📦 [2/5] Compilation de l'APK Release optimisé (R8 Full Mode)..." -ForegroundColor Yellow
            ./gradlew assembleRelease --no-daemon

            New-Item -ItemType Directory -Force "build-artifacts" | Out-Null
            $ReleaseApk = (Get-ChildItem -Path "app/build/outputs/apk/release/*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1)

            if ($ReleaseApk) {
                # Normalisation stricte Règle 6 : <AppName>-v<version>.apk brut sans ZIP
                Copy-Item $ReleaseApk.FullName "build-artifacts/$ApkName" -Force
                # Copie de rétrocompatibilité sans version
                Copy-Item $ReleaseApk.FullName "build-artifacts/$AppName.apk" -Force

                $SizeMb = [math]::Round((Get-Item "build-artifacts/$ApkName").Length / 1MB, 2)
                Write-Host "✅ APK normalisé prêt : build-artifacts/$ApkName ($SizeMb Mo)" -ForegroundColor Green
            } else {
                Write-Warning "⚠️ Aucun APK release trouvé dans app/build/outputs/apk/release/"
            }
        }
    } else {
        Write-Host "`n⏩ [2/5] Compilation ignorée (-SkipBuild)." -ForegroundColor DarkGray
    }

    if ($DryRun) {
        Write-Host "`n🔎 Mode DryRun : arrêt avant commit, tag et publication." -ForegroundColor Magenta
        return
    }

    # 4. Traçabilité Git & Tag Sémantique
    Write-Host "`n🏷️ [3/5] Création du commit et tag Git $Tag..." -ForegroundColor Yellow
    git add .
    git commit -m "chore(release): bump version to $Version [skip ci]" --allow-empty
    git tag -a $Tag -m "Release $Tag" -f
    git push origin main --tags
    Write-Host "✅ Commit et tag $Tag synchronisés sur GitHub." -ForegroundColor Green

    # 5. Publication GitHub Release (Compatible InstallAPK)
    Write-Host "`n📲 [4/5] Publication sur GitHub Releases (0 minute Cloud consommée)..." -ForegroundColor Yellow
    $ArtifactTarget = "build-artifacts/$ApkName"
    if (Test-Path $ArtifactTarget) {
        $ReleaseExists = $false
        try {
            gh release view $Tag 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $ReleaseExists = $true }
        } catch { $ReleaseExists = $false }

        if ($ReleaseExists) {
            Write-Host "Mise à jour des binaires pour le tag existant $Tag..." -ForegroundColor Cyan
            gh release upload $Tag "build-artifacts/$ApkName" "build-artifacts/$AppName.apk" --clobber
        } else {
            Write-Host "Création d'une nouvelle Release $Tag..." -ForegroundColor Cyan
            gh release create $Tag "build-artifacts/$ApkName" "build-artifacts/$AppName.apk" `
                --title "$AppName $Tag" `
                --generate-notes
        }
        Write-Host "✅ Binaire APK publié sur GitHub Releases (détectable en 1 clic par InstallAPK)." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Aucun APK à attacher à la release." -ForegroundColor DarkGray
    }

    # 6. Déploiement Web Cloudflare Pages (Optionnel)
    if ($DeployWeb -and (Test-Path "web") -and (Get-Command wrangler -ErrorAction SilentlyContinue)) {
        Write-Host "`n⚡ [5/5] Déploiement Cloudflare Pages via Wrangler..." -ForegroundColor Yellow
        $ProjectSlug = $AppName.ToLower().Replace(" ", "-")
        try {
            wrangler pages deploy web --project-name=$ProjectSlug --commit-dirty=true
            Write-Host "✅ Application Web déployée sur Cloudflare Pages." -ForegroundColor Green
        } catch {
            Write-Warning "⚠️ Déploiement Wrangler direct non finalisé (vérifier les identifiants Cloudflare)."
        }
    }

    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "🎉 Release $AppName $Tag terminée avec succès !" -ForegroundColor Green
    Write-Host "   - APK installable : build-artifacts/$ApkName" -ForegroundColor Green
    Write-Host "   - Minutes GitHub Actions consommées : 0" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green

} finally {
    # Nettoyage systématique du verrou (Règle 16)
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
