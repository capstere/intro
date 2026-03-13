# IPTCompile – README för Jesper

Det här är en praktisk orienteringsguide för **IPTCompile-v1.4.0-consolidated-safe**.

Syftet är inte att dokumentera all affärslogik i detalj, utan att snabbt svara på:
- **Var ligger saker nu?**
- **Vilken fil ska jag öppna först?**
- **Var hittar jag en viss typ av funktion?**
- **Vad är kvar i `Main.ps1` och vad har flyttats ut?**

---

## 1. Viktigaste nuläget

### Senast användarverifierade stabila bas
- `IPTCompile-v1.3.7-phase11-safe`

### Nuvarande konsoliderade struktur
- `IPTCompile-v1.4.0-consolidated-safe`

### Vad det betyder
- Kod som tidigare låg i stora blandfiler eller shim-filer har i stor utsträckning fått **riktiga hem** i:
  - `App/`
  - `Core/`
  - `Infrastructure/`
- `Modules/` innehåller nu bara de moduler som fortfarande är “riktiga” kvarvarande moduler.
- `Main.ps1` är fortfarande stor, men efter fas 11 innehåller den **inga egna funktionsdefinitioner** längre. Det som är kvar där är främst:
  - startup
  - UI-komposition / layout
  - event wiring
  - scan/build-orkestrering på top-level

---

## 2. Snabbt svar på din fråga: var finns `Get-ProjectStatusData`?

`Get-ProjectStatusData` ska ligga i:

- **`App/BuildController.ps1`**

Det är den fil du ska öppna först om du letar efter:
- projektstatus
- filflöde
- LSP-flytt
- externa scriptanrop
- controller-/handlingsnära hjälpfunktioner

---

## 3. Hela strukturen – tänk så här

## Root
Det här är projektets “nav”.

Typiskt viktiga filer i root:
- `Main.ps1`
- `Version.txt`
- `output_template-v4.xlsx`
- `StatusBoard.psd1`
- `RuleBank/RuleBank.compiled.ps1`
- `Lib/EPPlus.dll`
- `Lib/DocumentFormat.OpenXml.dll`

### Öppna root-filer när du vill:
- starta programmet → `Main.ps1`
- se version → `Version.txt`
- ändra rapportmall → `output_template-v4.xlsx`
- ändra regelbank → `RuleBank/RuleBank.compiled.ps1`

---

## 4. Vad varje huvudmapp betyder

## `App/`
Det här är **UI-/bootstrap-/användarflödeslagret**.

Tänk: 
- det användaren klickar på
- GUI-hjälp
- dialoger
- bootstrap
- controller-logik nära UI

### Filer i `App/`
- `App/EarlyGuards.ps1`
- `App/UiLogging.ps1`
- `App/UiSignatureDialogs.ps1`
- `App/UiHelpers.ps1`
- `App/Bootstrap.ps1`
- `App/BuildController.ps1`
- `App/UiDialogs.ps1`
- `App/UiTheme.ps1`

---

## `Core/`
Det här är **domänlogik / arbetsflödesnära logik**.

Tänk:
- regler
- klassificering
- assay-normalisering
- header-parsing
- compare-logik
- output-planering
- signaturworkflow

### Filer i `Core/`
- `Core/SignatureWorkflow.ps1`
- `Core/OpenXmlSignatureWorkflow.ps1`
- `Core/RuleEngineCore.ps1`
- `Core/RuleEngineDebug.ps1`
- `Core/AssayNormalization.ps1`
- `Core/HeaderParsing.ps1`
- `Core/HeaderComparison.ps1`
- `Core/OutputPlanning.ps1`

---

## `Infrastructure/`
Det här är **IO / teknisk infrastruktur**.

Tänk:
- logging
- forensics
- Excel/OpenXML
- EPPlus
- CSV-import
- file staging

### Filer i `Infrastructure/`
- `Infrastructure/LoggingCore.ps1`
- `Infrastructure/Forensics.ps1`
- `Infrastructure/ExcelOpenXml.ps1`
- `Infrastructure/ExcelEpplus.ps1`
- `Infrastructure/Csv.ps1`
- `Infrastructure/FileStaging.ps1`

---

## `Modules/`
Det här är nu **kvarvarande riktiga moduler**, inte bara shim.

### Filer i `Modules/`
- `Modules/Config.ps1`
- `Modules/SharePointClient.ps1`
- `Modules/Splash.ps1`
- `Modules/UiStyling.ps1`

### Tänk så här
Om något fortfarande känns “gammalt IPTCompile-original”, finns det stor chans att det är här eller i `Main.ps1`.

---

## 5. Var du hittar olika typer av funktioner

## A. UI-hjälpfunktioner
Öppna först:
- **`App/UiHelpers.ps1`**

Här ligger typiskt sådant som:
- GUI-hjälpare
- list-/watermark-hjälpare
- busy state
- enable/disable av knappar
- UI-stateuppdatering
- dubbelbuffering
- overwrite-verification UI

Exempel på sådant som flyttats hit under refactoren:
- `New-ListRow`
- watermark-funktioner
- `Clear-GUI`
- `Set-UiBusy`
- `Update-BuildEnabled`
- `Update-OverwriteVerificationUI`
- `Enable-DoubleBuffer`

---

## B. Bootstrap / användarprofil / startup-checks
Öppna först:
- **`App/Bootstrap.ps1`**
- **`App/EarlyGuards.ps1`**

Här ligger typiskt:
- startup guards
- user defaults
- config-baserad bootstrap
- blocked-user-check

Exempel:
- `Test-IsBlockedUser` → `App/EarlyGuards.ps1`
- `Get-UserProfileFromConfig`
- `Apply-UserDefaults`
- `Assert-StartupReady`
- `Assert-DevUnlocked`

---

## C. Dialoger
Öppna först:
- **`App/UiDialogs.ps1`**
- **`App/UiSignatureDialogs.ps1`**

Här ligger typiskt:
- info-dialoger
- status-dialoger
- filvals-/close file-dialoger
- signaturdialoger

Om du letar efter:
- `Show-StyledInfoDialog`
- `Show-ProjectStatusDialog`
- `Ensure-FilesClosedOrCancel`
- sign-input / sign-confirmation

…är det här rätt ställe.

---

## D. Build-/controller-funktioner
Öppna först:
- **`App/BuildController.ps1`**

Det här är en av de viktigaste filerna om du letar efter funktioner som styr “vad appen gör” ur användarens perspektiv.

Här ska du leta efter:
- `Get-ProjectStatusData`
- LSP-relaterat
- filflyttar
- externa scriptanrop
- mer controllernära arbetsflödessteg

Exempel på sådant som flyttats hit:
- `Get-ProjectStatusData`
- `Find-LspFolder`
- `Move-DownloadedLspFiles`
- `Invoke-ExternalScript`

---

## E. Theme / hjälpmeny / UI-ton
Öppna först:
- **`App/UiTheme.ps1`**

Om det handlar om:
- theme
- light/dark
- hjälp-/om-dialoger
- menyrelaterad UI-ton

så är det här rätt fil.

---

## F. Rule engine
Öppna först:
- **`Core/RuleEngineCore.ps1`**
- vid behov även `Core/RuleEngineDebug.ps1`

Det här är kärnan för:
- klassificering
- expected/observed call
- error code lookup
- deviation-logik
- tolkning av regelbanken

Om du letar efter något som “bestämmer resultatet”, börja här.

### Tumregel
- faktisk motor → `Core/RuleEngineCore.ps1`
- debug-/hjälpskrivning → `Core/RuleEngineDebug.ps1`

---

## G. RuleBank
Öppna:
- **`RuleBank/RuleBank.compiled.ps1`**

Här ligger data för regler, inte själva motorn.

Tänk:
- vad reglerna *är*
inte
- hur de körs

Om du undrar “varför blev det så här?”:
- börja ofta i `Core/RuleEngineCore.ps1`
- hoppa sedan till `RuleBank/RuleBank.compiled.ps1`

---

## H. Assay-normalisering
Öppna:
- **`Core/AssayNormalization.ps1`**

Här ska assay-/ID-/headertext-normalisering ligga.

Bra första stopp om problem gäller:
- assay aliases
- normaliserade namn
- ID-normalisering

---

## I. Header-läsning och header-jämförelse
Det här är viktigt eftersom just denna zon var känslig i refactoren.

### Parsing/läsning
Öppna:
- **`Core/HeaderParsing.ps1`**

Här ska du leta efter:
- `Extract-WorksheetHeader`
- `Get-WorksheetHeaderPerSheet`
- `Extract-SealTestHeader`
- headerutvinning / header-hjälpare

### Compare-set-logik
Öppna:
- **`Core/HeaderComparison.ps1`**

Här ska du leta efter:
- `Compare-WorksheetHeaderSet`
- `Get-SealTestHeaderPerSheet`
- `Compare-SealTestHeaderSet`
- lokala compare-/canon-delar

### Viktig notering
Header-zonen visade sig behöva behandlas som ett **sammanhängande block**, inte som lösa funktionsnamn. Om du ändrar här: var försiktig.

---

## J. Output-planering / rapportnära hjälpare
Öppna:
- **`Core/OutputPlanning.ps1`**

Det här är filen för mycket av det rapportnära och sammanställningsnära.

Exempel på sådant som ligger här:
- `_IsActiveSealSheet`
- `_GetPerSheetValueObjects`
- `_AggregateStatus`
- `Get-ControlTabName`
- `Get-MinitabMacro`
- `Get-OutSheetName`
- `Get-Threshold`
- `Is-FeatureEnabled`
- `Format-SpPresenceGrandTotalStrict`
- `Get-InfinitySpFromCsvStrict`

### Viktig notering
Den här filen innehåller också top-level mapping/index-state som behövs för vissa funktioner, t.ex. kring assay-/minitab-lookup. Det var just detta som gav fel i refactoren när bara funktionerna flyttades men inte tillhörande state.

---

## K. Signaturworkflow
Öppna:
- **`Core/SignatureWorkflow.ps1`**
- **`App/UiSignatureDialogs.ps1`**
- **`Core/OpenXmlSignatureWorkflow.ps1`**

### Fördelning
- signaturlogik / verifiering → `Core/SignatureWorkflow.ps1`
- signaturdialoger → `App/UiSignatureDialogs.ps1`
- worksheet-sign via OpenXML → `Core/OpenXmlSignatureWorkflow.ps1`

---

## L. OpenXML
Öppna:
- **`Infrastructure/ExcelOpenXml.ps1`**

Här ligger tekniska helpers för:
- celler
- merge handling
- skrivning/läsning i OpenXML
- sökningar i workbook

Om det är “teknisk Excel-skrivning”, börja här.

---

## M. EPPlus
Öppna:
- **`Infrastructure/ExcelEpplus.ps1`**

Här ligger EPPlus-specifika helpers, t.ex.:
- cell styling
- borders
- autofit
- safe cell text

---

## N. CSV
Öppna:
- **`Infrastructure/Csv.ps1`**

Här ligger:
- CSV-import
- delimiter detection
- streaming-import
- assay från CSV
- primary/resample-detektion

---

## O. File staging / nätverk / lås
Öppna:
- **`Infrastructure/FileStaging.ps1`**

Här ligger:
- fil-lås-kontroll
- snapshot/staging
- nätverksvägshantering

---

## P. Logging
Öppna:
- **`Infrastructure/LoggingCore.ps1`**
- **`App/UiLogging.ps1`**

### Fördelning
- audit/structured/core logging → `Infrastructure/LoggingCore.ps1`
- GUI-loggning → `App/UiLogging.ps1`

---

## Q. Forensics
Öppna:
- **`Infrastructure/Forensics.ps1`**

Här ska du leta om det gäller:
- forensic snapshots
- felsökningsdump/säkring av tillstånd

---

## R. SharePoint
Öppna:
- **`Modules/SharePointClient.ps1`**

SharePoint har lämnats som kvarvarande “riktig” modul.

---

## S. Config
Öppna:
- **`Modules/Config.ps1`**

Det här är fortfarande en viktig fil för:
- path resolution
- config-access
- flags
- vissa globala patterns, inklusive sådant som tidigare använts i delamination-sammanhang

---

## 6. Load order – i vilken ordning `Main.ps1` laddar filer

I `v1.4.0-consolidated-safe` laddar `Main.ps1` i praktiken detta:

1. `App/EarlyGuards.ps1`
2. `Modules/Config.ps1`
3. `Modules/Splash.ps1`
4. `Modules/SharePointClient.ps1`
5. `Modules/UiStyling.ps1`
6. `Infrastructure/LoggingCore.ps1`
7. `App/UiLogging.ps1`
8. `Infrastructure/ExcelEpplus.ps1`
9. `Infrastructure/Csv.ps1`
10. `Infrastructure/FileStaging.ps1`
11. `Core/AssayNormalization.ps1`
12. `Core/HeaderParsing.ps1`
13. `Core/HeaderComparison.ps1`
14. `Core/OutputPlanning.ps1`
15. `Core/SignatureWorkflow.ps1`
16. `App/UiSignatureDialogs.ps1`
17. `Infrastructure/Forensics.ps1`
18. `Infrastructure/ExcelOpenXml.ps1`
19. `Core/OpenXmlSignatureWorkflow.ps1`
20. `Core/RuleEngineCore.ps1`
21. `Core/RuleEngineDebug.ps1`
22. `App/UiHelpers.ps1`
23. `App/Bootstrap.ps1`
24. `App/UiDialogs.ps1`
25. `App/BuildController.ps1`
26. `App/UiTheme.ps1`

### Varför detta är viktigt
Om en funktion “plötsligt inte finns”, kontrollera:
- ligger den i rätt fil?
- laddas filen innan den används?
- finns det top-level state som funktionen förväntar sig?

---

## 7. Praktisk sökguide – om du letar efter något snabbt

## Om du letar efter en viss funktion
Börja så här:

### Status / projekt / knappar / controller
→ `App/BuildController.ps1`

### UI-state / listor / watermark / busy
→ `App/UiHelpers.ps1`

### Dialoger
→ `App/UiDialogs.ps1`

### Theme / Help / About
→ `App/UiTheme.ps1`

### Blocked user / startup guard
→ `App/EarlyGuards.ps1`

### Logging till GUI
→ `App/UiLogging.ps1`

### Core klassificering / rule engine
→ `Core/RuleEngineCore.ps1`

### Rule debug
→ `Core/RuleEngineDebug.ps1`

### Header parsing
→ `Core/HeaderParsing.ps1`

### Header compare
→ `Core/HeaderComparison.ps1`

### Output / report helpers
→ `Core/OutputPlanning.ps1`

### Signature logic
→ `Core/SignatureWorkflow.ps1`

### OpenXML worksheet-sign
→ `Core/OpenXmlSignatureWorkflow.ps1`

### CSV
→ `Infrastructure/Csv.ps1`

### EPPlus
→ `Infrastructure/ExcelEpplus.ps1`

### OpenXML low-level
→ `Infrastructure/ExcelOpenXml.ps1`

### File locks / staging
→ `Infrastructure/FileStaging.ps1`

### Config
→ `Modules/Config.ps1`

---

## 8. Viktiga lärdomar från refactoren

## 1. Alla funktioner var inte “rena”
Särskilt `DataHelpers.ps1` innehöll:
- top-level state/tabeller
- compare-block
- lokala helperfunktioner inuti andra funktioner

Så när du ändrar sådana filer: se upp med att bara flytta funktionsnamn utan tillhörande state.

## 2. Header-zonen är känslig
Allt kring:
- `Extract-WorksheetHeader`
- `Get-WorksheetHeaderPerSheet`
- `Compare-WorksheetHeaderSet`
- seal-test header compare

bör ses som ett **sammansatt område**.

## 3. `Main.ps1` är fortfarande stor av en anledning
Det som är kvar där är främst top-level runtime, UI-komposition och event wiring. Det är just den typen av kod som var farlig att flytta mekaniskt.

---

## 9. Min praktiska tumregel till dig

Om du undrar “var ska jag börja leta?” så använd detta:

- **GUI-saker** → `App/`
- **domänlogik / regler / compare / output** → `Core/`
- **Excel / CSV / IO / logging / staging** → `Infrastructure/`
- **config / SharePoint / splash / styling** → `Modules/`
- **fortfarande stort top-level-flöde** → `Main.ps1`

---

## 10. Kort version – super-snabb orientering

### Om du bara vill ha 10-sekundersvarianten:
- `Get-ProjectStatusData` → **`App/BuildController.ps1`**
- UI-hjälpare → **`App/UiHelpers.ps1`**
- dialoger → **`App/UiDialogs.ps1`**
- rule engine → **`Core/RuleEngineCore.ps1`**
- regeldata → **`RuleBank/RuleBank.compiled.ps1`**
- output helpers → **`Core/OutputPlanning.ps1`**
- header parsing → **`Core/HeaderParsing.ps1`**
- header compare → **`Core/HeaderComparison.ps1`**
- CSV → **`Infrastructure/Csv.ps1`**
- OpenXML → **`Infrastructure/ExcelOpenXml.ps1`**
- config → **`Modules/Config.ps1`**

---

## 11. Rekommenderad nästa förbättring senare

Om du längre fram vill göra detta ännu lättare att underhålla, då vore nästa steg inte mer splittring, utan:
- ett automatiskt funktionsindex
- eller en utvecklarfil som t.ex. `FUNCTION_INDEX.md`
- eller ett PowerShell-script som listar:
  - funktion → fil
  - fil → ansvar

Det hade varit nästa riktiga komfortlyft.

