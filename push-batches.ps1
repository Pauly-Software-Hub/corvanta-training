# Uploads the training videos to GitHub in batches of about 100 MB (one commit and one push per batch),
# because one 578 MB push stalls on this connection. Safe to run again: batches already on GitHub are skipped.
# Made by Claude for Paul Maritz & Doreen Maritz.
$ErrorActionPreference = "Continue"
$g = "D:\AI Software\EnergyDepotOrders\Build Tools\git\PortableGit\cmd\git.exe"
Set-Location $PSScriptRoot
$env:GIT_TERMINAL_PROMPT = "0"
if (-not (Test-Path ".git")) { & $g init -b main | Out-Null }
& $g config user.name "Pauly-Software-Hub"
& $g config user.email "Pauly-Software-Hub@users.noreply.github.com"
& $g config http.postBuffer 157286400
& $g config credential.helper manager
# start again from nothing (the earlier single commit is thrown away)
if (& $g rev-parse --verify -q HEAD) { & $g update-ref -d HEAD; & $g rm -r -q --cached . | Out-Null }
$batches = @(@("index.html", ".nojekyll", "robots.txt", "_headers", "push-batches.ps1", "posters"))
$cur = @(); $size = 0
foreach ($f in Get-ChildItem videos -Filter *.mp4 | Sort-Object Name) {
  if ($size + $f.Length -gt 100MB -and $cur.Count) { $batches += ,$cur; $cur = @(); $size = 0 }
  $cur += "videos/" + $f.Name; $size += $f.Length
}
if ($cur.Count) { $batches += ,$cur }
$i = 0
foreach ($b in $batches) {
  $i++
  & $g add -- $b
  & $g commit -q -m ("Training videos - part {0} of {1}" -f $i, $batches.Count)
  for ($t = 1; $t -le 5; $t++) {
    & $g push -q -u origin main --force-with-lease 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -eq 0) { "part $i of $($batches.Count) uploaded"; break }
    "part $i, try $t failed - trying again"; Start-Sleep 15
  }
  if ($LASTEXITCODE -ne 0) { "STOPPED at part $i"; exit 1 }
}
"ALL UPLOADED"
