# QDIP Production Orders + Archive Export Tool
# PowerShell 5.1 / PnP.PowerShell
# Purpose:
#   Export key rows and calculated helper columns from:
#   - Cepheid | Production orders
#   - Cepheid | Production orders - Archive
#
# This script is read-only. It creates CSV files on your Desktop in a timestamped folder.
#
# How to use:
#   1. Open Windows PowerShell 5.1
#   2. Run this script
#   3. Paste/fill ClientId and CertificateBase64 when prompted, or fill them below first
#   4. Zip the output folder and send it for analysis

$ErrorActionPreference = "Stop"
$env:PNPPOWERSHELL_UPDATECHECK = "Off"

# ==============================
# DEFAULT SETTINGS
# ==============================

$DefaultTenant = "danaher.onmicrosoft.com"
$DefaultSiteUrl = "https://danaher.sharepoint.com/sites/CEP-Sweden-Production-Management"

# Fill these if you do not want prompts:
$ClientId = "MY KEY"
$CertificateBase64 = "MY KEY"

# Lists from your SharePoint export
$ProductionOrdersListId = "85bf77f5-4f4d-41c9-b89a-371db8d50e25"
$ArchiveListId          = "534c9592-d98d-480d-8d72-43449201136c"

# Default investigation window: official D-lagging comparison window
$DefaultStartDate = "2026-03-28"
$DefaultEndDateExclusive = "2026-04-26"

# Specific orders we have discussed + problem cases
$DefaultOrdersOfInterest = @(
    "1115740",
    "1115700",
    "1116193",
    "1115696",
    "1116176",
    "1116455",
    "1115869",
    "1115879",
    "1116181",
    "1115597",
    "1115688",
    "1116023",
    "1116125",
    "1116444",
    "1116544",
    "1116404",
    "1116446",
    "1115105"
)

# ==============================
# PROMPTS
# ==============================

Write-Host ""
Write-Host "QDIP Production Orders Investigation Export" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host ""

$tenant = Read-Host "Tenant [$DefaultTenant]"
if ([string]::IsNullOrWhiteSpace($tenant)) { $tenant = $DefaultTenant }

$siteUrl = Read-Host "SharePoint Site URL [$DefaultSiteUrl]"
if ([string]::IsNullOrWhiteSpace($siteUrl)) { $siteUrl = $DefaultSiteUrl }

if ($ClientId -eq "MY KEY" -or [string]::IsNullOrWhiteSpace($ClientId)) {
    $ClientId = Read-Host "ClientId"
}

if ($CertificateBase64 -eq "MY KEY" -or [string]::IsNullOrWhiteSpace($CertificateBase64)) {
    $CertificateBase64 = Read-Host "CertificateBase64Encoded"
}

$startInput = Read-Host "Start date [$DefaultStartDate]"
if ([string]::IsNullOrWhiteSpace($startInput)) { $startInput = $DefaultStartDate }

$endInput = Read-Host "End date exclusive [$DefaultEndDateExclusive]"
if ([string]::IsNullOrWhiteSpace($endInput)) { $endInput = $DefaultEndDateExclusive }

try {
    $StartDate = Get-Date $startInput
    $EndDateExclusive = Get-Date $endInput
}
catch {
    throw "Could not parse start/end dates. Use yyyy-MM-dd."
}

$orderInput = Read-Host "Orders of interest comma-separated [press Enter for default list]"
if ([string]::IsNullOrWhiteSpace($orderInput)) {
    $OrdersOfInterest = $DefaultOrdersOfInterest
}
else {
    $OrdersOfInterest = $orderInput.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

$Desktop = [Environment]::GetFolderPath("Desktop")
$OutFolder = Join-Path $Desktop ("QDIP_ProdOrders_Archive_Export_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $OutFolder | Out-Null

Write-Host ""
Write-Host "Output folder:" -ForegroundColor Green
Write-Host $OutFolder
Write-Host ""

# ==============================
# CONNECT
# ==============================

Write-Host "Connecting to SharePoint..." -ForegroundColor Cyan

Connect-PnPOnline `
    -Url $siteUrl `
    -Tenant $tenant `
    -ClientId $ClientId `
    -CertificateBase64Encoded $CertificateBase64

Write-Host "Connected." -ForegroundColor Green

# ==============================
# HELPER FUNCTIONS
# ==============================

function Convert-ToText {
    param($Value)

    if ($null -eq $Value) { return $null }

    # Choice/Lookup/Person-like objects often expose LookupValue or Email
    if ($Value -is [Microsoft.SharePoint.Client.FieldLookupValue]) {
        return $Value.LookupValue
    }

    if ($Value -is [Microsoft.SharePoint.Client.FieldUserValue]) {
        return $Value.LookupValue
    }

    if ($Value -is [System.Array]) {
        return (($Value | ForEach-Object { Convert-ToText $_ }) -join "; ")
    }

    if ($Value -is [DateTime]) {
        return $Value.ToString("yyyy-MM-dd HH:mm:ss")
    }

    return [string]$Value
}

function Convert-ToDateOrNull {
    param($Value)

    if ($null -eq $Value -or $Value -eq "") { return $null }

    try {
        return [datetime]$Value
    }
    catch {
        return $null
    }
}

function Convert-ToDoubleOrNull {
    param($Value)

    if ($null -eq $Value -or $Value -eq "") { return $null }

    $s = [string]$Value
    $s = $s.Replace(",", ".")

    try {
        return [double]::Parse($s, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        return $null
    }
}

function Get-HoursBetween {
    param(
        $StartValue,
        $EndValue
    )

    $s = Convert-ToDateOrNull $StartValue
    $e = Convert-ToDateOrNull $EndValue

    if ($null -eq $s -or $null -eq $e) { return $null }

    try {
        return [math]::Round((New-TimeSpan -Start $s -End $e).TotalHours, 4)
    }
    catch {
        return $null
    }
}

function Starts-With1011 {
    param($Value)

    if ($null -eq $Value) { return $false }

    $s = ([string]$Value).Trim()
    return ($s.StartsWith("10") -or $s.StartsWith("11"))
}

function Extract-CalculatedFormula {
    param([string]$SchemaXml)

    if ([string]::IsNullOrWhiteSpace($SchemaXml)) { return "" }

    if ($SchemaXml -match "<Formula>(.*?)</Formula>") {
        return [System.Net.WebUtility]::HtmlDecode($matches[1])
    }

    return ""
}

function Get-ListFieldMap {
    param(
        [string]$ListId,
        [string]$ListLabel
    )

    Write-Host "Reading fields for $ListLabel..." -ForegroundColor Cyan

    $fields = Get-PnPField -List $ListId

    $map = $fields | ForEach-Object {
        [PSCustomObject]@{
            ListLabel       = $ListLabel
            Title           = $_.Title
            InternalName    = $_.InternalName
            TypeDisplayName = $_.TypeDisplayName
            TypeAsString    = $_.TypeAsString
            Required        = $_.Required
            Formula         = Extract-CalculatedFormula $_.SchemaXml
            SchemaXml       = $_.SchemaXml
        }
    }

    return $map
}

function Resolve-Field {
    param(
        [array]$FieldMap,
        [string[]]$Titles,
        [string[]]$PreferredInternalNames = @()
    )

    # 1. Preferred internal names first
    foreach ($pin in $PreferredInternalNames) {
        $hit = $FieldMap | Where-Object { $_.InternalName -eq $pin } | Select-Object -First 1
        if ($hit) { return $hit }
    }

    # 2. Exact title, avoid computed where possible
    foreach ($title in $Titles) {
        $hits = $FieldMap | Where-Object { $_.Title -eq $title }
        if ($hits) {
            $nonComputed = $hits | Where-Object { $_.TypeDisplayName -ne "Computed" } | Select-Object -First 1
            if ($nonComputed) { return $nonComputed }
            return ($hits | Select-Object -First 1)
        }
    }

    # 3. Case-insensitive exact
    foreach ($title in $Titles) {
        $hits = $FieldMap | Where-Object { $_.Title.ToLowerInvariant() -eq $title.ToLowerInvariant() }
        if ($hits) {
            $nonComputed = $hits | Where-Object { $_.TypeDisplayName -ne "Computed" } | Select-Object -First 1
            if ($nonComputed) { return $nonComputed }
            return ($hits | Select-Object -First 1)
        }
    }

    return $null
}

function Get-ResolvedImportantFields {
    param(
        [array]$FieldMap,
        [string]$ListLabel
    )

    $defs = @(
        @{Key="Order"; Titles=@("Order#"); Preferred=@("Title")},
        @{Key="SAPBatch"; Titles=@("SAP Batch#"); Preferred=@("Batch_x0023_")},
        @{Key="SAPBatch2"; Titles=@("SAP Batch# 2"); Preferred=@("SAP_x0020_Batch_x0023__x0020_2")},
        @{Key="LSP"; Titles=@("LSP"); Preferred=@("LSP")},
        @{Key="Material"; Titles=@("Material"); Preferred=@("Material")},
        @{Key="WorkCenter"; Titles=@("Work Center"); Preferred=@("Work_x0020_Center")},
        @{Key="OrderQuantity"; Titles=@("Order quantity"); Preferred=@("Order_x0020_quantity")},
        @{Key="RobalStart"; Titles=@("ROBAL - Actual start date/ time"); Preferred=@("Actual_x0020_startdate_x002f__x0")},
        @{Key="RobalEnd"; Titles=@("ROBAL - Actual end date/ time"); Preferred=@("Actual_x0020_end_x0020_date_x002")},
        @{Key="IPTTestingFinalized"; Titles=@("IPT - Testing finalized"); Preferred=@("IPT_x0020__x002d__x0020_Testing_0")},
        @{Key="IPTResamplingFinalized"; Titles=@("IPT - Resampling finalized"); Preferred=@("IPT_x0020__x002d__x0020_Resampli0")},
        @{Key="IPTCompiling"; Titles=@("IPT - Compiling of data"); Preferred=@("IPT_x002d__x0020_compiling_x0020")},
        @{Key="IPTDocumentReview"; Titles=@("IPT - Document review"); Preferred=@("IPT_x0020__x002d__x0020_Document")},
        @{Key="IPTErrorFreeText"; Titles=@("IPT - Error Free text"); Preferred=@("IPT_x002d__x0020_Error_x0")},
        @{Key="IPTLFI"; Titles=@("IPT - LFI"); Preferred=@("IPT_x0020__x002d__x0020_LFI")},
        @{Key="IPTTestResults"; Titles=@("IPT - Test results"); Preferred=@("ITP_x0020_Test_x0020_results")},
        @{Key="PackingInfo"; Titles=@("Packing info"); Preferred=@("IPT_x0020__x002d__x0020_Packing_")},
        @{Key="FIRequestInitiated"; Titles=@("IPT – FI request initiated","IPT - FI request initiated"); Preferred=@("IPT_x0020__x2013__x0020_FI_x0020")},
        @{Key="FIRequestComplete"; Titles=@("FI – IPT FI request complete","FI - IPT FI request complete"); Preferred=@("FI_x0020__x2013__x0020_IPT_x0020")},
        @{Key="NCRNumber"; Titles=@("NC (QA) – NCR Number","NC (QA) - NCR Number"); Preferred=@("NCR_x0020__x002d__x0020_Process")},
        @{Key="NCInitiateDate"; Titles=@("NC (QA) – Initiate NCR date","NC (QA) - Initiate NCR date"); Preferred=@("QA_x0020__x002d__x0020_NCR_x00200")},
        @{Key="ReworkOriginalOrder"; Titles=@("REWORK - from SAP order# (original order#)"); Preferred=@("REWORK_x0020_from_x0020_SAP_x002")},
        @{Key="ReworkOriginalBatch"; Titles=@("REWORK - from SAP batch# (original batch#)"); Preferred=@("REWORK_x0020__x002d__x0020_Origi")},
        @{Key="ReworkActualStart"; Titles=@("REWORK - Actual start date"); Preferred=@("REWORK_x0020__x002d__x0020_Actua")},
        @{Key="ReworkActualEnd"; Titles=@("REWORK - Actual end date"); Preferred=@("REWORK_x0020_Completion_x0020_da")},
        @{Key="ReworkCompleted"; Titles=@("REWORK - Completed"); Preferred=@("REWORK_x0020_Completed")},
        @{Key="DocumentReviewRework"; Titles=@("Document review - REWORK"); Preferred=@("REWORK_x0020__x002d__x0020_Revie")},
        @{Key="LeadTime"; Titles=@("Lead-time"); Preferred=@("Lead_x002d_time")},
        @{Key="DVMCurrentPhaseLT"; Titles=@("DVM - Current phase lead-time (h)"); Preferred=@("DVM_x0020__x002d__x0020_Phase_x0")},
        @{Key="IPTTestingInProgress"; Titles=@("IPT testing in progress"); Preferred=@("Resampling_x0020_and_x0020_Extra")},
        @{Key="OrderClosed"; Titles=@("Order closed"); Preferred=@("Order_x0020_closed")},
        @{Key="OrderType"; Titles=@("Order type"); Preferred=@("Order_x0020_type")},
        @{Key="NotANewOrder"; Titles=@("Not a new order"); Preferred=@("Not_x0020_a_x0020_new_x0020_orde")},
        @{Key="Created"; Titles=@("Created"); Preferred=@("Created")},
        @{Key="Modified"; Titles=@("Modified"); Preferred=@("Modified")},
        @{Key="Editor"; Titles=@("Modified By"); Preferred=@("Editor")},
        @{Key="GUID"; Titles=@("GUID"); Preferred=@("GUID")},
        @{Key="ID"; Titles=@("ID"); Preferred=@("ID")}
    )

    $resolved = foreach ($d in $defs) {
        $hit = Resolve-Field -FieldMap $FieldMap -Titles $d.Titles -PreferredInternalNames $d.Preferred
        [PSCustomObject]@{
            ListLabel = $ListLabel
            Key = $d.Key
            RequestedTitles = ($d.Titles -join " | ")
            InternalName = if ($hit) { $hit.InternalName } else { $null }
            Title = if ($hit) { $hit.Title } else { $null }
            TypeDisplayName = if ($hit) { $hit.TypeDisplayName } else { $null }
            TypeAsString = if ($hit) { $hit.TypeAsString } else { $null }
            Found = [bool]$hit
        }
    }

    return $resolved
}

function Get-InternalNamesForFetch {
    param([array]$ResolvedFields)

    $names = $ResolvedFields |
        Where-Object { $_.Found -and $_.InternalName -ne $null -and $_.InternalName -ne "" } |
        Select-Object -ExpandProperty InternalName -Unique

    # Always include system fields if available
    return @($names)
}

function Get-ItemValueByResolvedKey {
    param(
        $Item,
        [hashtable]$InternalByKey,
        [string]$Key
    )

    if (-not $InternalByKey.ContainsKey($Key)) { return $null }

    $internal = $InternalByKey[$Key]
    if ([string]::IsNullOrWhiteSpace($internal)) { return $null }

    try {
        return $Item[$internal]
    }
    catch {
        return $null
    }
}

function Build-ExportRows {
    param(
        [string]$ListLabel,
        [array]$Items,
        [array]$ResolvedFields
    )

    $InternalByKey = @{}
    foreach ($r in $ResolvedFields) {
        if ($r.Found -and $r.InternalName) {
            $InternalByKey[$r.Key] = $r.InternalName
        }
    }

    $rows = foreach ($item in $Items) {

        $order = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "Order")
        $reworkOriginalOrder = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "ReworkOriginalOrder")

        $robalEnd = Get-ItemValueByResolvedKey $item $InternalByKey "RobalEnd"
        $testingFinalized = Get-ItemValueByResolvedKey $item $InternalByKey "IPTTestingFinalized"
        $resamplingFinalized = Get-ItemValueByResolvedKey $item $InternalByKey "IPTResamplingFinalized"
        $compiling = Get-ItemValueByResolvedKey $item $InternalByKey "IPTCompiling"
        $docReview = Get-ItemValueByResolvedKey $item $InternalByKey "IPTDocumentReview"
        $fiInit = Get-ItemValueByResolvedKey $item $InternalByKey "FIRequestInitiated"
        $fiComplete = Get-ItemValueByResolvedKey $item $InternalByKey "FIRequestComplete"
        $reworkEnd = Get-ItemValueByResolvedKey $item $InternalByKey "ReworkActualEnd"
        $docReviewRework = Get-ItemValueByResolvedKey $item $InternalByKey "DocumentReviewRework"

        $leadTimeRaw = Get-ItemValueByResolvedKey $item $InternalByKey "LeadTime"
        $dvmLT = Get-ItemValueByResolvedKey $item $InternalByKey "DVMCurrentPhaseLT"

        $rawRobalToReview = Get-HoursBetween -StartValue $robalEnd -EndValue $docReview
        $robalToCompiling = Get-HoursBetween -StartValue $robalEnd -EndValue $compiling
        $testingToReview = Get-HoursBetween -StartValue $testingFinalized -EndValue $docReview
        $fiPause = Get-HoursBetween -StartValue $fiInit -EndValue $fiComplete
        $reworkEndToReview = Get-HoursBetween -StartValue $reworkEnd -EndValue $docReviewRework

        $order10 = Starts-With1011 $order
        $rework10 = Starts-With1011 $reworkOriginalOrder

        $orderKeyCandidate = if ($rework10) { $reworkOriginalOrder } else { $order }

        $docDate = Convert-ToDateOrNull $docReview
        $modified = Convert-ToDateOrNull (Get-ItemValueByResolvedKey $item $InternalByKey "Modified")

        [PSCustomObject]@{
            SourceList = $ListLabel

            ID = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "ID")
            GUID = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "GUID")

            Order_Current = $order
            Rework_OriginalOrder = $reworkOriginalOrder
            OrderKeyCandidate = $orderKeyCandidate

            IsCurrentOrder10or11 = $order10
            IsReworkOriginal10or11 = $rework10
            IsQDIP_OrderCandidate = ($order10 -or $rework10)

            SAPBatch = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "SAPBatch")
            SAPBatch2 = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "SAPBatch2")
            Rework_OriginalBatch = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "ReworkOriginalBatch")
            LSP = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "LSP")
            Material = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "Material")
            WorkCenter = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "WorkCenter")
            OrderQuantity = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "OrderQuantity")

            RobalStart = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "RobalStart")
            RobalEnd = Convert-ToText $robalEnd
            IPTTestingFinalized = Convert-ToText $testingFinalized
            IPTResamplingFinalized = Convert-ToText $resamplingFinalized
            IPTCompiling = Convert-ToText $compiling
            IPTDocumentReview = Convert-ToText $docReview
            D_Lagging_Date = if ($docDate) { $docDate.ToString("yyyy-MM-dd") } else { $null }

            IPTErrorFreeText = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "IPTErrorFreeText")
            IPTLFI = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "IPTLFI")
            IPTTestResults = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "IPTTestResults")
            PackingInfo = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "PackingInfo")

            FIRequestInitiated = Convert-ToText $fiInit
            FIRequestComplete = Convert-ToText $fiComplete
            NCRNumber = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "NCRNumber")
            NCInitiateDate = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "NCInitiateDate")

            ReworkActualStart = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "ReworkActualStart")
            ReworkActualEnd = Convert-ToText $reworkEnd
            ReworkCompleted = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "ReworkCompleted")
            DocumentReviewRework = Convert-ToText $docReviewRework

            SP_LeadTime_Raw = Convert-ToText $leadTimeRaw
            SP_LeadTime_Double = Convert-ToDoubleOrNull $leadTimeRaw
            DVM_CurrentPhaseLT_Raw = Convert-ToText $dvmLT
            DVM_CurrentPhaseLT_Double = Convert-ToDoubleOrNull $dvmLT

            Calc_RobalToReview_Hours = $rawRobalToReview
            Calc_RobalToCompiling_Hours = $robalToCompiling
            Calc_TestingToReview_Hours = $testingToReview
            Calc_FI_Pause_Hours = $fiPause
            Calc_ReworkEndToReworkReview_Hours = $reworkEndToReview

            HasIPTDocumentReview = ($docReview -ne $null -and (Convert-ToText $docReview) -ne "")
            HasRobalEnd = ($robalEnd -ne $null -and (Convert-ToText $robalEnd) -ne "")
            HasCompiling = ($compiling -ne $null -and (Convert-ToText $compiling) -ne "")
            HasTestingFinalized = ($testingFinalized -ne $null -and (Convert-ToText $testingFinalized) -ne "")
            HasFIWindow = ($fiInit -ne $null -and $fiComplete -ne $null)
            HasNCR = ((Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "NCRNumber")) -ne $null -and (Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "NCRNumber")) -ne "")

            IPTTestingInProgress = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "IPTTestingInProgress")
            OrderClosed = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "OrderClosed")
            OrderType = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "OrderType")
            NotANewOrder = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "NotANewOrder")

            Created = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "Created")
            Modified = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "Modified")
            Modified_DateOnly = if ($modified) { $modified.ToString("yyyy-MM-dd") } else { $null }
            Editor = Convert-ToText (Get-ItemValueByResolvedKey $item $InternalByKey "Editor")
        }
    }

    return $rows
}

function Export-ListInvestigation {
    param(
        [string]$ListId,
        [string]$ListLabel
    )

    Write-Host ""
    Write-Host "=============================================="
    Write-Host "Processing $ListLabel" -ForegroundColor Cyan
    Write-Host "=============================================="

    $fieldMap = Get-ListFieldMap -ListId $ListId -ListLabel $ListLabel
    $safeLabel = ($ListLabel -replace '[\\/:*?"<>|]', '_')

    $fieldMapPath = Join-Path $OutFolder ("Fields_" + $safeLabel + ".csv")
    $fieldMap | Export-Csv $fieldMapPath -NoTypeInformation -Encoding UTF8

    $calcPath = Join-Path $OutFolder ("CalculatedFormulas_" + $safeLabel + ".csv")
    $fieldMap |
        Where-Object { $_.TypeDisplayName -eq "Calculated" -or $_.TypeAsString -eq "Calculated" -or $_.Formula -ne "" } |
        Export-Csv $calcPath -NoTypeInformation -Encoding UTF8

    $resolved = Get-ResolvedImportantFields -FieldMap $fieldMap -ListLabel $ListLabel
    $resolvedPath = Join-Path $OutFolder ("ResolvedFields_" + $safeLabel + ".csv")
    $resolved | Export-Csv $resolvedPath -NoTypeInformation -Encoding UTF8

    $internalNames = Get-InternalNamesForFetch -ResolvedFields $resolved

    Write-Host "Important fields resolved: $(($resolved | Where-Object {$_.Found}).Count) / $($resolved.Count)"
    Write-Host "Fields requested from SharePoint: $($internalNames.Count)"
    Write-Host "Reading items from $ListLabel. This can take a while..." -ForegroundColor Yellow

    $items = Get-PnPListItem -List $ListId -PageSize 5000 -Fields $internalNames

    Write-Host "Rows read from $ListLabel: $($items.Count)" -ForegroundColor Green

    $rows = Build-ExportRows -ListLabel $ListLabel -Items $items -ResolvedFields $resolved

    # Full key rows. Could be large, but this is intentional for investigation.
    $allPath = Join-Path $OutFolder ("Rows_All_" + $safeLabel + ".csv")
    $rows | Export-Csv $allPath -NoTypeInformation -Encoding UTF8

    # Rows in date window by IPT Document Review or Modified, plus QDIP candidate rows
    $windowRows = $rows | Where-Object {
        $include = $false

        $docDate = Convert-ToDateOrNull $_.IPTDocumentReview
        $modDate = Convert-ToDateOrNull $_.Modified

        if ($docDate -ne $null -and $docDate -ge $StartDate -and $docDate -lt $EndDateExclusive) {
            $include = $true
        }

        if ($modDate -ne $null -and $modDate -ge $StartDate -and $modDate -lt $EndDateExclusive) {
            $include = $true
        }

        if ($_.IsQDIP_OrderCandidate -eq $true -and $_.HasIPTDocumentReview -eq $true) {
            $d = Convert-ToDateOrNull $_.IPTDocumentReview
            if ($d -ne $null -and $d -ge $StartDate.AddDays(-14) -and $d -lt $EndDateExclusive.AddDays(14)) {
                $include = $true
            }
        }

        $include
    }

    $windowPath = Join-Path $OutFolder ("Rows_Window_" + $safeLabel + ".csv")
    $windowRows | Export-Csv $windowPath -NoTypeInformation -Encoding UTF8

    # Specific orders by current order or original rework order
    $specificRows = $rows | Where-Object {
        ($OrdersOfInterest -contains ([string]$_.Order_Current)) -or
        ($OrdersOfInterest -contains ([string]$_.Rework_OriginalOrder)) -or
        ($OrdersOfInterest -contains ([string]$_.OrderKeyCandidate))
    }

    $specificPath = Join-Path $OutFolder ("Rows_SpecificOrders_" + $safeLabel + ".csv")
    $specificRows | Export-Csv $specificPath -NoTypeInformation -Encoding UTF8

    # Candidate D-lagging rows
    $laggingRows = $rows | Where-Object {
        $_.HasIPTDocumentReview -eq $true -and $_.IsQDIP_OrderCandidate -eq $true
    }

    $laggingPath = Join-Path $OutFolder ("Rows_DLaggingCandidates_" + $safeLabel + ".csv")
    $laggingRows | Export-Csv $laggingPath -NoTypeInformation -Encoding UTF8

    # Candidate active leading rows
    $activeRows = $rows | Where-Object {
        $_.HasIPTDocumentReview -eq $false -and $_.HasRobalEnd -eq $true -and $_.IsQDIP_OrderCandidate -eq $true
    }

    $activePath = Join-Path $OutFolder ("Rows_ActiveLeadingCandidates_" + $safeLabel + ".csv")
    $activeRows | Export-Csv $activePath -NoTypeInformation -Encoding UTF8

    return [PSCustomObject]@{
        ListLabel = $ListLabel
        AllRows = $rows
        WindowRows = $windowRows
        SpecificRows = $specificRows
        LaggingRows = $laggingRows
        ActiveRows = $activeRows
        FieldMap = $fieldMap
        ResolvedFields = $resolved
    }
}

# ==============================
# RUN EXPORTS
# ==============================

$results = @()

$results += Export-ListInvestigation -ListId $ProductionOrdersListId -ListLabel "Cepheid | Production orders"
$results += Export-ListInvestigation -ListId $ArchiveListId -ListLabel "Cepheid | Production orders - Archive"

# ==============================
# COMBINED EXPORTS
# ==============================

Write-Host ""
Write-Host "Creating combined exports..." -ForegroundColor Cyan

$allCombined = @()
$windowCombined = @()
$specificCombined = @()
$laggingCombined = @()
$activeCombined = @()

foreach ($r in $results) {
    $allCombined += $r.AllRows
    $windowCombined += $r.WindowRows
    $specificCombined += $r.SpecificRows
    $laggingCombined += $r.LaggingRows
    $activeCombined += $r.ActiveRows
}

$allCombined | Export-Csv (Join-Path $OutFolder "Combined_AllRows.csv") -NoTypeInformation -Encoding UTF8
$windowCombined | Export-Csv (Join-Path $OutFolder "Combined_WindowRows.csv") -NoTypeInformation -Encoding UTF8
$specificCombined | Export-Csv (Join-Path $OutFolder "Combined_SpecificOrders.csv") -NoTypeInformation -Encoding UTF8
$laggingCombined | Export-Csv (Join-Path $OutFolder "Combined_DLaggingCandidates.csv") -NoTypeInformation -Encoding UTF8
$activeCombined | Export-Csv (Join-Path $OutFolder "Combined_ActiveLeadingCandidates.csv") -NoTypeInformation -Encoding UTF8

# Summary
$summary = @(
    [PSCustomObject]@{
        Metric = "StartDate"
        Value = $StartDate.ToString("yyyy-MM-dd")
    },
    [PSCustomObject]@{
        Metric = "EndDateExclusive"
        Value = $EndDateExclusive.ToString("yyyy-MM-dd")
    },
    [PSCustomObject]@{
        Metric = "OrdersOfInterest"
        Value = ($OrdersOfInterest -join ", ")
    },
    [PSCustomObject]@{
        Metric = "Combined_AllRows"
        Value = $allCombined.Count
    },
    [PSCustomObject]@{
        Metric = "Combined_WindowRows"
        Value = $windowCombined.Count
    },
    [PSCustomObject]@{
        Metric = "Combined_SpecificOrders"
        Value = $specificCombined.Count
    },
    [PSCustomObject]@{
        Metric = "Combined_DLaggingCandidates"
        Value = $laggingCombined.Count
    },
    [PSCustomObject]@{
        Metric = "Combined_ActiveLeadingCandidates"
        Value = $activeCombined.Count
    }
)

$summary | Export-Csv (Join-Path $OutFolder "README_Summary.csv") -NoTypeInformation -Encoding UTF8

$readmeText = @"
QDIP Production Orders + Archive Export

Purpose:
- Investigate how official Power BI may create:
  - Historical Production Orders
  - Active Production Order
- Compare active/archive SharePoint data with correct D-lagging export.

Important output files:
- Combined_SpecificOrders.csv
- Combined_DLaggingCandidates.csv
- Combined_ActiveLeadingCandidates.csv
- Combined_WindowRows.csv
- Rows_All_Cepheid _ Production orders.csv
- Rows_All_Cepheid _ Production orders - Archive.csv
- ResolvedFields_*.csv
- CalculatedFormulas_*.csv

Recommended next step:
Zip this whole folder and send it for analysis.

Notes:
- IsQDIP_OrderCandidate = Current Order# starts with 10/11 OR Rework original order starts with 10/11.
- Calc_RobalToReview_Hours = IPT Document Review - ROBAL End.
- Calc_RobalToCompiling_Hours = IPT Compiling - ROBAL End.
- Calc_TestingToReview_Hours = IPT Document Review - IPT Testing Finalized.
- Calc_FI_Pause_Hours = FI Request Complete - FI Request Initiated.
- Active leading candidate = no IPT Document Review, has ROBAL End, QDIP order candidate.
"@

$readmePath = Join-Path $OutFolder "README_QDIP_ProductionOrders_Archive_Export.txt"
$readmeText | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host "Zip this folder and send it:" -ForegroundColor Yellow
Write-Host $OutFolder
Write-Host ""
