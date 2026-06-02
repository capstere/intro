
<#
PQC Barcode Builder v1
PowerShell 5.1, no external libraries.
Generates Code 128B barcode PNGs + CSV + printable HTML scan sheet.

IMPORTANT:
- Print generated HTML at 100% / Actual size.
- Visible SampleID is what GX should receive.
- Encoded barcode includes ADF trigger prefix, e.g. @PQCN@.
- Requires Zebra DS4308 ADF rules to remove prefix and send key sequence.
#>

Set-StrictMode -Version 2.0
Add-Type -AssemblyName System.Drawing

$OutputRoot = Join-Path $PSScriptRoot ("PQC_Barcodes_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
$BarcodeDir = Join-Path $OutputRoot "barcodes"
New-Item -ItemType Directory -Path $BarcodeDir -Force | Out-Null

$Code128Patterns = @(
'212222','222122','222221','121223','121322','131222','122213','122312','132212','221213',
'221312','231212','112232','122132','122231','113222','123122','123221','223211','221132',
'221231','213212','223112','312131','311222','321122','321221','312212','322112','322211',
'212123','212321','232121','111323','131123','131321','112313','132113','132311','211313',
'231113','231311','112133','112331','132131','113123','113321','133121','313121','211331',
'231131','213113','213311','213131','311123','311321','331121','312113','312311','332111',
'314111','221411','431111','111224','111422','121124','121421','141122','141221','112214',
'112412','122114','122411','142112','142211','241211','221114','413111','241112','134111',
'111242','121142','121241','114212','124112','124211','411212','421112','421211','212141',
'214121','412121','111143','111341','131141','114113','114311','411113','411311','113141',
'114131','311141','411131','211412','211214','211232','2331112'
)

$AdfPrefixes = @{
    'PP'    = '@PQC2@'
    'P'     = '@PQC1@'
    'N'     = '@PQCN@'
    'Blank' = '@PQC0@'
}

function Get-Code128BValues {
    param([Parameter(Mandatory=$true)][string]$Data)
    $values = New-Object System.Collections.Generic.List[int]
    $values.Add(104) # Start Code B
    foreach ($ch in $Data.ToCharArray()) {
        $o = [int][char]$ch
        if ($o -lt 32 -or $o -gt 127) { throw "Unsupported Code128B character: '$ch'" }
        $values.Add($o - 32)
    }
    $checksum = $values[0]
    for ($i = 1; $i -lt $values.Count; $i++) { $checksum += $i * $values[$i] }
    $values.Add($checksum % 103)
    $values.Add(106) # Stop
    return ,$values.ToArray()
}

function New-Code128BarcodePng {
    param(
        [Parameter(Mandatory=$true)][string]$Data,
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$ModuleWidth = 3,
        [int]$Height = 105,
        [int]$QuietModules = 30
    )
    $values = Get-Code128BValues -Data $Data
    $moduleCount = $QuietModules * 2
    foreach ($v in $values) {
        foreach ($c in $Code128Patterns[$v].ToCharArray()) { $moduleCount += [int]::Parse($c) }
    }
    $width = $moduleCount * $ModuleWidth
    $bmp = New-Object System.Drawing.Bitmap $width, $Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $brush = [System.Drawing.Brushes]::Black
    $x = $QuietModules * $ModuleWidth
    foreach ($v in $values) {
        $black = $true
        foreach ($c in $Code128Patterns[$v].ToCharArray()) {
            $w = [int]::Parse($c) * $ModuleWidth
            if ($black) { $g.FillRectangle($brush, $x, 0, $w, $Height) }
            $x += $w
            $black = -not $black
        }
    }
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

function Add-BarcodeSet {
    param(
        [Parameter(Mandatory=$true)][System.Collections.ArrayList]$Rows,
        [Parameter(Mandatory=$true)][ref]$Order,
        [Parameter(Mandatory=$true)][string]$BaseID,
        [Parameter(Mandatory=$true)][string[]]$SamplePoints,
        [Parameter(Mandatory=$true)][int]$SampleCode,
        [Parameter(Mandatory=$true)][int[]]$Replicates,
        [Parameter(Mandatory=$true)][int]$ReplicateDigits,
        [Parameter(Mandatory=$true)][scriptblock]$LidCutRule,
        [Parameter(Mandatory=$true)][ValidateSet('PP','P','N','Blank')][string]$ADFProfile,
        [Parameter(Mandatory=$true)][string]$Group
    )
    foreach ($sp in $SamplePoints) {
        foreach ($r in $Replicates) {
            $rep = $r.ToString(("0" * $ReplicateDigits))
            $lid = & $LidCutRule $r
            $sampleId = "{0}_{1}_{2}_{3}{4}" -f $BaseID, $sp, $SampleCode, $rep, $lid
            $prefix = $AdfPrefixes[$ADFProfile]
            $barcodeData = $prefix + $sampleId
            [void]$Rows.Add([pscustomobject]@{
                ScanOrder = $Order.Value
                Group = $Group
                BaseID = $BaseID
                SamplePoint = $sp
                SampleCode = $SampleCode
                ReplicateNo = $rep
                LidCut = $lid
                ADFProfile = $ADFProfile
                ADFPrefix = $prefix
                SampleID = $sampleId
                BarcodeData = $barcodeData
            })
            $Order.Value++
        }
    }
}

$rows = New-Object System.Collections.ArrayList
$order = 1

# Current batch: total 210 cartridges
Add-BarcodeSet -Rows $rows -Order ([ref]$order) -BaseID '121425MMM' -SamplePoints @('00') -SampleCode 1 -Replicates (1..10) -ReplicateDigits 2 -LidCutRule { param($r) if ($r -le 5) {'X'} else {'+'} } -ADFProfile 'P' -Group 'Special SP00'

# SP01-10 ordered per Sample Point: 10 + 8 + 2 = 20 barcodes per SP
foreach ($sp in (1..10 | ForEach-Object { $_.ToString('00') })) {
    Add-BarcodeSet -Rows $rows -Order ([ref]$order) -BaseID '101525ARMO' -SamplePoints @($sp) -SampleCode 0 -Replicates (1..10) -ReplicateDigits 2 -LidCutRule { param($r) if ($r -le 5) {'X'} else {'+'} } -ADFProfile 'N' -Group ("SP$sp / Code 0 / N")
    Add-BarcodeSet -Rows $rows -Order ([ref]$order) -BaseID '121425MMM' -SamplePoints @($sp) -SampleCode 1 -Replicates (11..18) -ReplicateDigits 2 -LidCutRule { param($r) if ($r -le 14) {'X'} else {'+'} } -ADFProfile 'P' -Group ("SP$sp / Code 1 / P")
    Add-BarcodeSet -Rows $rows -Order ([ref]$order) -BaseID '121725MMM' -SamplePoints @($sp) -SampleCode 2 -Replicates @(19,20) -ReplicateDigits 2 -LidCutRule { param($r) if ($r -eq 19) {'X'} else {'+'} } -ADFProfile 'PP' -Group ("SP$sp / Code 2 / PP")
}

if ($rows.Count -ne 210) { throw "Expected 210 rows, got $($rows.Count)." }

foreach ($row in $rows) {
    $safeSid = $row.SampleID.Replace('+','PLUS')
    $file = "{0:000}_{1}_{2}.png" -f $row.ScanOrder, $safeSid, $row.ADFProfile
    $path = Join-Path $BarcodeDir $file
    New-Code128BarcodePng -Data $row.BarcodeData -Path $path
    $row | Add-Member -NotePropertyName PngFile -NotePropertyValue ("barcodes/" + $file)
}

$csvPath = Join-Path $OutputRoot 'PQC_Batch_210_expected_index.csv'
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

$htmlPath = Join-Path $OutputRoot 'PQC_Batch_210_PrintSheet.html'
$htmlRows = New-Object System.Text.StringBuilder
$currentSp = $null
foreach ($row in $rows) {
    if ($row.SamplePoint -ne $currentSp) {
        $currentSp = $row.SamplePoint
        $heading = if ($currentSp -eq '00') { 'Special Sample Point 00' } else { "Sample Point $currentSp" }
        [void]$htmlRows.AppendLine("<h2>$heading</h2>")
        [void]$htmlRows.AppendLine('<div class="row head"><div>#</div><div>Profile</div><div>Sample ID</div><div>Barcode</div><div>Done</div></div>')
    }
    $sid = [System.Web.HttpUtility]::HtmlEncode($row.SampleID)
    $pref = [System.Web.HttpUtility]::HtmlEncode($row.ADFPrefix)
    [void]$htmlRows.AppendLine("<div class='row'><div>$($row.ScanOrder.ToString('000'))</div><div>$($row.ADFProfile)</div><div><b>$sid</b><br><span class='small'>encoded prefix: $pref</span></div><div><img class='barcode' src='$($row.PngFile)'></div><div><span class='check'></span></div></div>")
}
$html = @"
<!doctype html>
<html><head><meta charset="utf-8"><title>PQC Batch 210 Barcode Sheet</title>
<style>
@page { size: A4; margin: 10mm; }
body { font-family: Arial, sans-serif; font-size: 10pt; }
h1 { font-size: 16pt; margin: 0 0 6px 0; }
h2 { font-size: 12pt; margin: 14px 0 4px 0; border-top: 1px solid #999; padding-top: 8px; }
.row { display: grid; grid-template-columns: 38px 66px 245px 350px 40px; align-items: center; gap: 6px; break-inside: avoid; page-break-inside: avoid; border-bottom: 1px solid #ddd; padding: 4px 0; }
.head { font-weight: bold; background: #eee; border-top: 1px solid #aaa; }
.barcode { max-width: 340px; height: 42px; object-fit: contain; }
.small { font-size: 8pt; color: #333; }
.check { border: 1px solid #000; width: 16px; height: 16px; display: inline-block; }
.warn { border: 1px solid #888; padding: 6px; background: #f7f7f7; margin: 6px 0 10px 0; }
</style></head><body>
<h1>PQC Barcode Scan Sheet – Batch 210 cartridges</h1>
<div class="warn"><b>Print:</b> 100% / Actual size. Visible Sample ID is what GX should receive. Encoded barcode includes hidden ADF trigger prefix.</div>
<p><b>Total:</b> 210 barcodes. Profiles used: N=@PQCN@, P=@PQC1@, PP=@PQC2@.</p>
$htmlRows
</body></html>
"@
$html | Set-Content -Encoding UTF8 -Path $htmlPath

Write-Host "Created:" -ForegroundColor Green
Write-Host $OutputRoot
Write-Host "Rows: $($rows.Count)"
Write-Host "Open and print: $htmlPath"
