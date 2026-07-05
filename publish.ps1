#Requires -Version 5.1
<#
.SYNOPSIS
  一键推送 Ayuchan Linux 到 GitHub 并触发 ISO 构建。

.USAGE
  1. 首次请先登录 GitHub:
       gh auth login
  2. 然后运行:
       .\publish.ps1
     或指定仓库名:
       .\publish.ps1 -RepoName ayuchan-linux -Public
#>
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
        throw "未找到 $name。请先安装 Git / GitHub CLI 后重试。"
    }
}

Ensure-Command git
Ensure-Command gh

Write-Host "==> 检查 GitHub 登录状态..."
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "尚未登录 GitHub。请在弹出的浏览器中完成授权..."
    gh auth login --hostname github.com --git-protocol https --web
}

$owner = gh api user --jq .login
Write-Host "==> 当前 GitHub 用户: $owner"

if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

if (-not (git remote get-url origin 2>$null)) {
    Write-Host "==> 创建远程仓库: $owner/$RepoName"
    $visibility = if ($Public) { "--public" } else { "--private" }
    gh repo create "$RepoName" $visibility --source=. --remote=origin --description "Ayuchan Linux - custom Debian-based desktop distro"
} else {
    Write-Host "==> 已存在 remote origin，跳过创建仓库"
}

if (-not (git diff --cached --quiet 2>$null) -or (git status --porcelain)) {
    git add .
    $env:GIT_AUTHOR_NAME = "ayuchan"
    $env:GIT_AUTHOR_EMAIL = "$owner@users.noreply.github.com"
    $env:GIT_COMMITTER_NAME = "ayuchan"
    $env:GIT_COMMITTER_EMAIL = "$owner@users.noreply.github.com"
    git commit -m "Update Ayuchan Linux build config" 2>$null
}

Write-Host "==> 推送到 GitHub..."
git push -u origin main

Write-Host "==> 触发 GitHub Actions 构建 ISO..."
gh workflow run "Build Ayuchan ISO"
Start-Sleep -Seconds 3
$run = gh run list --workflow="Build Ayuchan ISO" --limit 1 --json databaseId,url,status --jq '.[0]'
Write-Host ""
Write-Host "构建已触发!"
Write-Host "查看进度: $($run.url)"
Write-Host ""
Write-Host "构建完成后，到 Actions 页面下载 Artifacts: ayuchan-linux-iso"

if ($CreateRelease) {
    Write-Host "==> 创建标签并发布 Release: $Tag"
    git tag -f $Tag
    git push -f origin $Tag
    Write-Host "Release 将在标签推送后自动创建。"
}

Write-Host ""
Write-Host "仓库地址: https://github.com/$owner/$RepoName"
