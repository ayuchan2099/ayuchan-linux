#Requires -Version 5.1
param(
    [string]$RepoName = "ayuchan-linux",
    [switch]$Public,
    [switch]$CreateRelease,
    [string]$Tag = "v1.0.0"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Ensure-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Command not found: $name"
    }
}

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git @Args
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0) {
        throw "git failed: git $($Args -join ' ')"
    }
}

function Get-GitRemoteUrl([string]$name) {
    $output = cmd /c "git remote get-url $name 2>nul"
    if ($LASTEXITCODE -eq 0 -and $output) {
        return $output.Trim()
    }
    return $null
}

Ensure-Command git
Ensure-Command gh

Write-Host "==> Checking GitHub login..."
$loggedIn = $false
cmd /c "gh auth status >nul 2>nul"
if ($LASTEXITCODE -eq 0) { $loggedIn = $true }

if (-not $loggedIn) {
    Write-Host "Not logged in. Complete auth in the browser when prompted..."
    gh auth login --hostname github.com --git-protocol https --web
    cmd /c "gh auth status >nul 2>nul"
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub login failed. Run: gh auth login"
    }
}

$owner = gh api user --jq .login
if (-not $owner) {
    throw "Could not read GitHub username. Check network and run: gh auth login"
}
Write-Host "==> GitHub user: $owner"

if (-not (Test-Path ".git")) {
    Invoke-Git init
    Invoke-Git branch -M main
}

$remote = Get-GitRemoteUrl "origin"
if (-not $remote) {
    Write-Host "==> Creating repo: $owner/$RepoName"
    $visibility = if ($Public) { "--public" } else { "--private" }
    cmd /c "gh repo create $RepoName $visibility --source=. --remote=origin --description Ayuchan-Linux-custom-distro 2>nul"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "==> Repo may already exist, linking remote..."
        $remoteUrl = "https://github.com/$owner/$RepoName.git"
        Invoke-Git remote add origin $remoteUrl
    }
    $remote = Get-GitRemoteUrl "origin"
    if (-not $remote) {
        throw "Failed to configure git remote 'origin'."
    }
} else {
    Write-Host "==> Remote origin already set: $remote"
}

$prev = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$status = git status --porcelain
$ErrorActionPreference = $prev

if ($status) {
    Invoke-Git add .
    $env:GIT_AUTHOR_NAME = "ayuchan"
    $env:GIT_AUTHOR_EMAIL = "$owner@users.noreply.github.com"
    $env:GIT_COMMITTER_NAME = "ayuchan"
    $env:GIT_COMMITTER_EMAIL = "$owner@users.noreply.github.com"
    Invoke-Git commit -m "Update Ayuchan Linux build config"
}

Write-Host "==> Pushing to GitHub..."
Invoke-Git push -u origin main

Write-Host "==> Triggering GitHub Actions ISO build..."
gh workflow run "Build Ayuchan ISO"
Start-Sleep -Seconds 3
$runUrl = gh run list --workflow="Build Ayuchan ISO" --limit 1 --json url --jq ".[0].url"
Write-Host ""
Write-Host "Build triggered."
Write-Host "Track progress: $runUrl"
Write-Host "Download ISO from Actions Artifacts when finished."

if ($CreateRelease) {
    Write-Host "==> Creating release tag: $Tag"
    Invoke-Git tag -f $Tag
    Invoke-Git push -f origin $Tag
}

Write-Host ""
Write-Host "Repository: https://github.com/$owner/$RepoName"
