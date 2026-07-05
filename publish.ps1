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

Ensure-Command git
Ensure-Command gh

Write-Host "==> Checking GitHub login..."
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in. Complete auth in the browser when prompted..."
    gh auth login --hostname github.com --git-protocol https --web
}

$owner = gh api user --jq .login
Write-Host "==> GitHub user: $owner"

if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

$remote = git remote get-url origin 2>$null
if (-not $remote) {
    Write-Host "==> Creating repo: $owner/$RepoName"
    if ($Public) {
        gh repo create "$RepoName" --public --source=. --remote=origin --description "Ayuchan Linux custom distro"
    } else {
        gh repo create "$RepoName" --private --source=. --remote=origin --description "Ayuchan Linux custom distro"
    }
} else {
    Write-Host "==> Remote origin already set: $remote"
}

$status = git status --porcelain
if ($status) {
    git add .
    $env:GIT_AUTHOR_NAME = "ayuchan"
    $env:GIT_AUTHOR_EMAIL = "$owner@users.noreply.github.com"
    $env:GIT_COMMITTER_NAME = "ayuchan"
    $env:GIT_COMMITTER_EMAIL = "$owner@users.noreply.github.com"
    git commit -m "Update Ayuchan Linux build config"
}

Write-Host "==> Pushing to GitHub..."
git push -u origin main

Write-Host "==> Triggering GitHub Actions ISO build..."
gh workflow run "Build Ayuchan ISO"
Start-Sleep -Seconds 3
$runUrl = gh run list --workflow="Build Ayuchan ISO" --limit 1 --json url --jq '.[0].url'
Write-Host ""
Write-Host "Build triggered."
Write-Host "Track progress: $runUrl"
Write-Host "Download ISO from Actions Artifacts when finished."

if ($CreateRelease) {
    Write-Host "==> Creating release tag: $Tag"
    git tag -f $Tag
    git push -f origin $Tag
}

Write-Host ""
Write-Host "Repository: https://github.com/$owner/$RepoName"
