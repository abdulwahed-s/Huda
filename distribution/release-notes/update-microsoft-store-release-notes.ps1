[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProductId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [string]$ReleaseNotesDirectory = (Join-Path $PSScriptRoot 'microsoft-store')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ReleaseNotesDirectory -PathType Container)) {
    throw "Microsoft Store release-notes directory not found: $ReleaseNotesDirectory"
}

$submissionOutput = @(msstore submission get $ProductId)
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$rawSubmission = [string]::Join([Environment]::NewLine, $submissionOutput)
$jsonStart = $rawSubmission.IndexOf('{')
$jsonEnd = $rawSubmission.LastIndexOf('}')
if ($jsonStart -lt 0 -or $jsonEnd -lt $jsonStart) {
    throw 'Microsoft Store CLI output did not contain a submission JSON object.'
}

$submissionJson = $rawSubmission.Substring($jsonStart, $jsonEnd - $jsonStart + 1) -replace '[\r\n]', ''
$submission = $submissionJson | ConvertFrom-Json -ErrorAction Stop
if ($null -eq $submission.Listings) {
    throw 'The Microsoft Store submission has no listings to update.'
}
if ([string]::IsNullOrWhiteSpace($submission.Id)) {
    throw 'The Microsoft Store submission has no ID.'
}

$updatedLocales = @()
$noteFiles = Get-ChildItem -LiteralPath $ReleaseNotesDirectory -Filter '*.txt' -File |
    Sort-Object Name

foreach ($noteFile in $noteFiles) {
    $locale = $noteFile.BaseName.ToLowerInvariant()
    $listingProperty = $submission.Listings.PSObject.Properties |
        Where-Object { $_.Name -ieq $locale } |
        Select-Object -First 1

    if ($null -eq $listingProperty) {
        Write-Host "Skipping $locale; no matching Microsoft Store listing."
        continue
    }

    $releaseNotes = (Get-Content -Raw -LiteralPath $noteFile.FullName).Trim()
    if ([string]::IsNullOrWhiteSpace($releaseNotes)) {
        throw "Release notes must not be empty: $($noteFile.FullName)"
    }

    $listing = $listingProperty.Value
    if ($null -eq $listing.BaseListing) {
        throw "Microsoft Store listing $locale has no BaseListing."
    }

    $listing.BaseListing.ReleaseNotes = $releaseNotes
    $updatedLocales += $locale
    Write-Host "Staged Microsoft Store release notes for $locale."
}

if ($updatedLocales.Count -eq 0) {
    throw 'No release-note files matched a Microsoft Store listing.'
}

$updatedSubmissionJson = $submission | ConvertTo-Json -Depth 100 -Compress

$tokenRequest = @{
    Method = 'Post'
    Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    ContentType = 'application/x-www-form-urlencoded'
    Body = @{
        client_id = $ClientId
        client_secret = $ClientSecret
        grant_type = 'client_credentials'
        scope = 'https://manage.devcenter.microsoft.com/.default'
    }
}
$token = Invoke-RestMethod @tokenRequest

if ([string]::IsNullOrWhiteSpace($token.access_token)) {
    throw 'Could not obtain a Microsoft Store API access token.'
}

$submissionUri = "https://manage.devcenter.microsoft.com/v1.0/my/applications/$ProductId/submissions/$($submission.Id)"
$updateRequest = @{
    Method = 'Put'
    Uri = $submissionUri
    Headers = @{
        Authorization = "Bearer $($token.access_token)"
        TenantId = $TenantId
    }
    ContentType = 'application/json'
    Body = $updatedSubmissionJson
}
Invoke-RestMethod @updateRequest | Out-Null

Write-Host "Updated Microsoft Store release notes for: $($updatedLocales -join ', ')."
