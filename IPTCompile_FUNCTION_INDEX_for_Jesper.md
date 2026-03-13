# IPTCompile – FUNCTION INDEX för Jesper

Det här är ett praktiskt funktionsindex för **IPTCompile-v1.4.0-consolidated-safe**.

Det viktigaste svaret först:

- **`Get-ProjectStatusData` → `App/BuildController.ps1`**

---

## Hur du använder den här filen

Tänk den här som:

- ett **snabbt uppslagsblad**
- ett sätt att slippa gissa vilken fil du ska öppna
- en bro mellan **original WIP-strukturen** och **nuvarande konsoliderade struktur**

### Viktig ärlig notering
Det här indexet bygger på:
- den ursprungliga funktionsinventeringen från `IPTCompile-20260311-WIP.zip`
- de verifierade refactor-stegen vi gjorde fram till `v1.4.0-consolidated-safe`
- tidigare README/noter om var funktioner flyttades

Jag har **inte** den fulla uppackade `v1.4.0-consolidated-safe`-kodbasen kvar i containern just nu, så:
- alla funktioner som kommer från de stora splitade modulerna är **verifierade** nedan
- de funktioner som ursprungligen låg i `Main.ps1` och som **inte uttryckligen nämndes i refactor-noterna** markeras som **inte fullt verifierade i den konsoliderade slutstrukturen**

Så: använd detta som ett **mycket bra navigationsstöd**, men om något verkar ha flyttat igen i din lokala kopia är `Ctrl+Shift+F` i projektroten fortfarande sista sanningen.

---

# 1. Snabbkarta: öppna rätt fil först

## App/
Öppna först om det gäller:
- knappar, menyer, dialoger, GUI-state, LSP-flöde, projektstatus

Viktigaste filer:
- `App/BuildController.ps1`
- `App/UiHelpers.ps1`
- `App/UiDialogs.ps1`
- `App/UiTheme.ps1`
- `App/Bootstrap.ps1`
- `App/EarlyGuards.ps1`
- `App/UiLogging.ps1`
- `App/UiSignatureDialogs.ps1`

## Core/
Öppna först om det gäller:
- regelmotor, headertolkning, compare-logik, output-planering, signaturworkflow

Viktigaste filer:
- `Core/RuleEngineCore.ps1`
- `Core/RuleEngineDebug.ps1`
- `Core/HeaderParsing.ps1`
- `Core/HeaderComparison.ps1`
- `Core/OutputPlanning.ps1`
- `Core/SignatureWorkflow.ps1`
- `Core/OpenXmlSignatureWorkflow.ps1`
- `Core/AssayNormalization.ps1`

## Infrastructure/
Öppna först om det gäller:
- CSV, EPPlus, OpenXML, file staging, logging, forensics

Viktigaste filer:
- `Infrastructure/Csv.ps1`
- `Infrastructure/ExcelEpplus.ps1`
- `Infrastructure/ExcelOpenXml.ps1`
- `Infrastructure/FileStaging.ps1`
- `Infrastructure/LoggingCore.ps1`
- `Infrastructure/Forensics.ps1`

## Modules/
Kvarvarande "riktiga" moduler:
- `Modules/Config.ps1`
- `Modules/SharePointClient.ps1`
- `Modules/Splash.ps1`
- `Modules/UiStyling.ps1`

---

# 2. Verifierat funktionsindex – nuvarande hem

## 2.1 App/EarlyGuards.ps1
Verifierat:
- `Test-IsBlockedUser`

---

## 2.2 App/Bootstrap.ps1
Verifierat:
- `Get-UserProfileFromConfig`
- `Apply-UserDefaults`
- `Assert-StartupReady`
- `Assert-DevUnlocked`

---

## 2.3 App/BuildController.ps1
Verifierat:
- `Get-ProjectStatusData`
- `Find-LspFolder`
- `Move-DownloadedLspFiles`
- `Invoke-ExternalScript`
- `Get-BatchLinkInfo`
- `Get-DefaultDownloadsPath`
- `Get-DownloadsPathEffective`
- `Get-LspDigitsFromString`
- `Get-UniqueDestinationPath`

Det här är filen du ska öppna först för:
- projektstatus
- LSP-flytt
- download-/file routing
- script launch / controller actions

---

## 2.4 App/UiHelpers.ps1
Verifierat:
- `New-ListRow`
- `Set-ClbWatermark`
- `Show-ClbWatermark`
- `Hide-ClbWatermark`
- `Add-CLBItems`
- `Get-CheckedFilePath`
- `Get-AllCheckedFilePaths`
- `Clear-GUI`
- `Get-SelectedFileCount`
- `Update-StatusBar`
- `Invoke-UiPump`
- `Set-UiBusy`
- `Set-UiStep`
- `Update-BuildEnabled`
- `Update-OverwriteVerificationUI`
- `Enable-DoubleBuffer`

Öppna den här först om det gäller:
- GUI-state
- listor/checklistor
- watermark
- busy/step-status
- enable/disable

---

## 2.5 App/UiDialogs.ps1
Verifierat:
- `Show-StyledInfoDialog`
- `Show-ListSelectionDialog`
- `Show-ProjectStatusDialog`
- `Show-FileMoveSelectionDialog`
- `Show-CloseFileToContinueDialog`
- `Ensure-FilesClosedOrCancel`

Mycket sannolik samhörighet här också:
- `New-StatusCard`

Den sista är **inte uttryckligen loggad i refactor-noterna**, men ligger logiskt i samma dialog-/statusområde.

---

## 2.6 App/UiTheme.ps1
Verifierat:
- `Set-Theme`

Den här filen är också rätt plats att titta i för:
- theme-relaterade menyhändelser
- help/about/light/dark

---

## 2.7 App/UiLogging.ps1
Verifierat:
- `Get-GuiAppendAction`
- `Get-OutputBox`
- `Set-LogOutputControl`
- `Get-GuiLogVerbosity`
- `Get-GuiLogList`
- `Should-LogToGui`
- `Gui-Log`

---

## 2.8 App/UiSignatureDialogs.ps1
Verifierat:
- `Confirm-SignatureInput`
- `Confirm-WorksheetSignInput`

---

## 2.9 Core/RuleEngineCore.ps1
Verifierat:
- `Test-RuleBankIntegrity`
- `_EnsureArray`
- `_NormalizeColumns`
- `_RequireColumns`
- `Load-RuleBank`
- `_HasKey`
- `Compile-RuleBank`
- `Get-ResultCallPatternsForAssay`
- `Get-ExpectationRulesForAssay`
- `Match-TextFast`
- `Get-TestTypePolicyForAssayCached`
- `Get-SampleNumberRuleForRowCached`
- `Get-RowField`
- `Test-RuleEnabled`
- `Test-AssayMatch`
- `Get-TestTypePolicyForAssay`
- `Test-IsStrictMtbUltraAssay`
- `Get-MtbUltraObservedCall`
- `Get-ObservedCallDetailed`
- `Get-ExpectedCallDetailed`
- `Get-ExpectedTestTypeDerived`
- `Build-ErrorCodeLookup`
- `Get-ErrorInfo`
- `Classify-Deviation`
- `Split-CsvLineQuoted`
- `Get-HeaderFromTestSummaryFile`
- `Convert-FieldRowsToObjects`
- `Get-MarkerValue`
- `Get-IntMarkerValue`
- `Get-ParityConfigForAssay`
- `Get-ControlCodeFromRow`
- `Get-SampleTokenAndBase`
- `Parse-SampleIdBasic`
- `Get-SampleNumberRuleForRow`
- `Invoke-RuleEngine`

Det här är kärnfilen för all faktisk regelutvärdering.

---

## 2.10 Core/RuleEngineDebug.ps1
Verifierat:
- `_RuleEngine_Log`
- `_Append-RuleFlag`
- `Write-RuleEngineDebugSheet`
- `_SvRuleFlags`
- `Write-SectionHeader`
- `Write-KV`

---

## 2.11 Core/AssayNormalization.ps1
Verifierat:
- `Normalize-Assay`
- `Normalize-Id`
- `Normalize-HeaderText`
- `Is-VlAssay`

---

## 2.12 Core/HeaderParsing.ps1
Verifierat:
- `Find-ObservationCol`
- `Test-IsWorksheetHeaderSkipSheet`
- `Extract-WorksheetHeader`
- `Get-WorksheetHeaderPerSheet`
- `Get-HeaderFooterText`
- `Try-FromHeaderFooter`
- `Try-FromCells`
- `Get-TestSummaryEquipmentFromWorksheet`
- `Get-TestSummaryEquipment`
- `Extract-SealTestHeader`
- `Parse-WorksheetHeaderRaw`
- `Try-Parse-HeaderDate`
- `Get-ConsensusValue`

---

## 2.13 Core/HeaderComparison.ps1
Verifierat:
- `Compare-WorksheetHeaderSet`
- `_canonWorksheet`
- `Get-SealTestHeaderPerSheet`
- `_getRightHeader`
- `_tryFromCells`
- `Compare-SealTestHeaderSet`
- `_canonSealHeader`
- `_pickMajor`

Det här blocket var känsligt i refactoren och ska ses som ett **sammanhängande block**.

---

## 2.14 Core/OutputPlanning.ps1
Verifierat:
- `Format-SpPresenceGrandTotalStrict`
- `Get-InfinitySpFromCsvStrict`
- `Get-ControlTabName`
- `Get-MinitabMacro`
- `Get-OutSheetName`
- `Get-Threshold`
- `Is-FeatureEnabled`
- `_IsActiveSealSheet`
- `_GetPerSheetValueObjects`
- `_AggregateStatus`

Viktig notering:
Den här filen innehåller även top-level mapping/index-state som vissa funktioner kräver.

---

## 2.15 Core/SignatureWorkflow.ps1
Verifierat:
- `Get-DataSheets`
- `Test-SignatureFormat`
- `Normalize-Signature`
- `Get-SignatureSetForDataSheets`
- `Get-BatchNumberFromSealFile`
- `Update-BatchLink`
- `Verify-SealTestSignatures`
- `Verify-WorksheetSignatures`

Trolig samhörighet här också:
- `_SignSealTestSheets`
- `Get-SealViolations`
- `_BuildUnsignedSealText`

Dessa tre är **inte uttryckligen loggade i refactor-noterna**, men de hör domänmässigt hemma i signatur-/seal-området. Kontrollera dem med projektsökning om du arbetar just där.

---

## 2.16 Core/OpenXmlSignatureWorkflow.ps1
Verifierat:
- `Get-WorksheetSignatureTargets_OpenXml`
- `Resolve-WorksheetSignatureRows_OpenXml`
- `Get-WorksheetSignaturePlan_OpenXml`
- `Invoke-WorksheetSignature_OpenXml`
- `Verify-WorksheetSignatures_OpenXml`

---

## 2.17 Infrastructure/LoggingCore.ps1
Verifierat:
- `Test-HasGetConfigValue`
- `Get-SafeFileNameComponent`
- `Add-AuditEntry`
- `Write-StructuredLog`

---

## 2.18 Infrastructure/Forensics.ps1
Verifierat:
- `Save-ForensicSnapshot`

---

## 2.19 Infrastructure/ExcelOpenXml.ps1
Verifierat:
- `Import-OpenXmlSdk`
- `Normalize-OpenXmlText`
- `Get-OpenXmlChildrenOfType`
- `Get-OpenXmlDescendantsOfType`
- `Convert-ColLetterToIndex`
- `Convert-ColIndexToLetter`
- `Split-OpenXmlCellRef`
- `Get-MergeIndexes_OpenXml`
- `Get-MergeCellMap_OpenXml`
- `Get-OpenXmlCellText`
- `Ensure-OpenXmlCell`
- `Test-OpenXmlTreatAsBlankText`
- `Get-OpenXmlCellSafe`
- `Clear-OpenXmlCellContent`
- `Set-OpenXmlCellInlineText`
- `Resolve-OpenXmlMergeOwner`
- `Get-OpenXmlMergeGroupOwnerRowRefs`
- `Write-OpenXmlCellText_DeterministicMerge`
- `Set-OpenXmlCellText`
- `Find-FirstRowByContains_OpenXml`
- `Find-FirstRowByContains_FromRow_OpenXml`
- `Test-OpenXmlDataSummaryHasData`
- `Write-OpenXmlSignDebug`
- `Find-OpenXmlCell`

---

## 2.20 Infrastructure/ExcelEpplus.ps1
Verifierat:
- `Load-EPPlus`
- `Set-RowBorder`
- `Style-Cell`
- `Safe-AutoFitColumns`
- `Get-SafeCellText`
- `Get-CellText`

---

## 2.21 Infrastructure/Csv.ps1
Verifierat:
- `Get-CsvDelimiter`
- `Test-IsResampleCsv`
- `Resolve-CsvPrimaryAndResample`
- `Get-AssayFromCsv`
- `Import-CsvRows`
- `ConvertTo-CsvFields`
- `Get-CsvStats`
- `Import-CsvRowsStreaming`
- `Split-CsvSmart`

---

## 2.22 Infrastructure/FileStaging.ps1
Verifierat:
- `Test-FileLocked`
- `Test-IsNetworkPath`
- `Stage-InputFileSnapshot`

---

## 2.23 Modules/Config.ps1
Verifierat:
- `Get-EnvNonEmpty`
- `Resolve-IptPath`
- `Resolve-IptPathList`
- `Test-IsNetworkPathSimple`
- `Resolve-LocalFirstFile`
- `Get-ConfigValue`
- `Get-ConfigFlag`
- `Test-Config`

---

## 2.24 Modules/SharePointClient.ps1
Verifierat:
- `Start-SPClient`
- `Connect-SPClient`
- `Connect-SPClientAsync`
- `Poll-SPClientAsync`
- `Invoke-SPClient`
- `Get-SPClientStatus`
- `Stop-SPClient`
- `_Invoke-InRunspace`

---

## 2.25 Modules/Splash.ps1
Verifierat:
- `Show-Splash`
- `Update-Splash`
- `Close-Splash`

---

## 2.26 Modules/UiStyling.ps1
Verifierat:
- `Get-WinAccentColor`
- `New-Color`
- `Darken`
- `Lighten`
- `Set-AccentButton`

---

# 3. Funktioner som kom från gamla Main.ps1 men vars slutfil inte är fullt verifierad här

Nedanstående funktioner fanns i original `Main.ps1`, men deras **exakta slutfil i v1.4.0-consolidated-safe** är inte uttryckligen dokumenterad i de refactor-noter jag har kvar.

Det betyder inte att de saknas — bara att jag inte vill låtsas veta fel fil med 100% säkerhet.

## Starka kandidater: `Core/OutputPlanning.ps1`
Börja här om du söker dessa:
- `Convert-A1ToRowCol`
- `Get-DataSummaryFindings`
- `Write-SPBlockIntoInformation`
- `Get-CleanLeaf`
- `Mark-Phase`
- `_EquipTokens`
- `_EquipPretty`
- `_FixMonthText`
- `_EquipEvalList`
- `_EquipEvalMonth`
- `_Txt`
- `_CleanSheets`
- `Get-SealHeaderDocInfo`
- `Find-InfoRow`
- `Find-LabelValueRightward`

## Möjliga kandidater: `Infrastructure/ExcelEpplus.ps1` eller `Infrastructure/ExcelOpenXml.ps1`
Börja här om du söker dessa:
- `Set-MergedWrapAutoHeight`
- `Add-Hyperlink`
- `Find-RegexCell`

## Möjlig kandidat: `App/UiDialogs.ps1`
- `New-StatusCard`

## Möjlig kandidat: `Core/SignatureWorkflow.ps1`
- `_SignSealTestSheets`
- `Get-SealViolations`
- `_BuildUnsignedSealText`

### Praktiskt råd
Om du letar efter just en av ovanstående:
1. sök först i `Core/OutputPlanning.ps1`
2. sök sedan i `Core/SignatureWorkflow.ps1`
3. sök sedan i `Infrastructure/ExcelEpplus.ps1` / `Infrastructure/ExcelOpenXml.ps1`
4. annars kör projektsökning på funktionsnamnet

---

# 4. Snabbsök – vanliga frågor

## Var ligger `Get-ProjectStatusData`?
- `App/BuildController.ps1`

## Var ligger `Compare-WorksheetHeaderSet`?
- `Core/HeaderComparison.ps1`

## Var ligger `Get-WorksheetHeaderPerSheet`?
- `Core/HeaderParsing.ps1`

## Var ligger `Get-SealTestHeaderPerSheet`?
- `Core/HeaderComparison.ps1`

## Var ligger `Invoke-RuleEngine`?
- `Core/RuleEngineCore.ps1`

## Var ligger `Gui-Log`?
- `App/UiLogging.ps1`

## Var ligger `Add-AuditEntry`?
- `Infrastructure/LoggingCore.ps1`

## Var ligger `Update-BatchLink`?
- `Core/SignatureWorkflow.ps1`

## Var ligger `Get-CellText`?
- `Infrastructure/ExcelEpplus.ps1`

## Var ligger `Write-OpenXmlCellText_DeterministicMerge`?
- `Infrastructure/ExcelOpenXml.ps1`

## Var ligger `Get-ControlTabName`?
- `Core/OutputPlanning.ps1`

## Var ligger `Normalize-Assay`?
- `Core/AssayNormalization.ps1`

---

# 5. Min praktiska tumregel till dig

När du inte hittar något:

- **UI / knappar / status / project cards** → börja i `App/BuildController.ps1` eller `App/UiHelpers.ps1`
- **dialoger** → `App/UiDialogs.ps1`
- **regler / klassificering** → `Core/RuleEngineCore.ps1`
- **headerproblem** → `Core/HeaderParsing.ps1` + `Core/HeaderComparison.ps1`
- **rapportnära helpers** → `Core/OutputPlanning.ps1`
- **signatur / seal / verify** → `Core/SignatureWorkflow.ps1`
- **OpenXML** → `Infrastructure/ExcelOpenXml.ps1`
- **EPPlus** → `Infrastructure/ExcelEpplus.ps1`
- **CSV** → `Infrastructure/Csv.ps1`

---

# 6. Extra tips

Om du vill göra detta ännu bekvämare i projektet kan du lägga till en egen liten PowerShell-sökning, typ:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern '^\s*function\s+Get-ProjectStatusData\b'
```

eller mer generellt:

```powershell
param([string]$FunctionName)
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern ('^\s*function\s+' + [regex]::Escape($FunctionName) + '\b')
```

Då kan du snabbt slå upp funktioner lokalt utan att behöva minnas filerna.

