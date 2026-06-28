param(
    [string]$LogPath = (Join-Path $PSScriptRoot "UpdateLog_Kontrollprovsfil.csv")
)

# ==============================================================
# Kontrollprovsfil Log Dashboard
# Läser UpdateLog_Kontrollprovsfil.csv och visar historiken i en
# enkel WPF/XAML-dashboard. Inga externa moduler krävs.
# ==============================================================

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $argList = @(
        '-NoProfile',
        '-STA',
        '-File', ('"{0}"' -f $PSCommandPath),
        '-LogPath', ('"{0}"' -f $LogPath)
    )
    Start-Process -FilePath "powershell.exe" -ArgumentList $argList
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName Microsoft.VisualBasic

$script:LogPath = $LogPath
$script:AllRows = @()
$script:BadLineCount = 0
$script:HeaderWarning = ""

function Split-SemicolonCsvLine {
    param([Parameter(Mandatory=$true)][string]$Line)

    $sr = New-Object System.IO.StringReader($Line)
    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($sr)
    try {
        $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
        $parser.SetDelimiters(';')
        $parser.HasFieldsEnclosedInQuotes = $true
        return @($parser.ReadFields())
    }
    finally {
        $parser.Close()
        $sr.Dispose()
    }
}

function ConvertFrom-UpdateLogLine {
    param([Parameter(Mandatory=$true)][string]$Line)

    try {
        $fields = @(Split-SemicolonCsvLine -Line $Line)

        # Nytt format:
        # "timestamp";"user";"signature";...
        if ($fields.Count -eq 13) {
            return $fields
        }

        # Legacy-format från äldre logg:
        # "timestamp;""user"";""signature"";..."
        # Då blir första parsningen ofta 1 fält. Parsar insidan en gång till.
        if ($fields.Count -eq 1 -and $fields[0] -like '*;*') {
            $legacyFields = @(Split-SemicolonCsvLine -Line $fields[0])
            if ($legacyFields.Count -eq 13) {
                return $legacyFields
            }
        }

        return $null
    }
    catch {
        return $null
    }
}

function Try-GetDateTime {
    param([string]$Text)

    $dt = [datetime]::MinValue
    if ([datetime]::TryParseExact(
        $Text,
        'yyyy-MM-dd HH:mm:ss',
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$dt
    )) {
        return $dt
    }

    if ([datetime]::TryParse($Text, [ref]$dt)) {
        return $dt
    }

    return [datetime]::MinValue
}

function Read-UpdateLog {
    param([Parameter(Mandatory=$true)][string]$Path)

    $script:BadLineCount = 0
    $script:HeaderWarning = ""
    $rows = New-Object System.Collections.Generic.List[object]

    if (-not (Test-Path -LiteralPath $Path)) {
        $script:HeaderWarning = "Hittar inte loggfilen: $Path"
        return @()
    }

    $lines = [System.IO.File]::ReadAllLines($Path)
    if ($lines.Count -eq 0) {
        $script:HeaderWarning = "Loggfilen är tom."
        return @()
    }

    $expectedHeader = "Timestamp;User;Signature;Action;PN;Row;OldLot;OldExp;OldQty;NewLot;NewExp;NewQty;Machine"
    $header = $lines[0].TrimStart([char]0xFEFF)
    if ($header -ne $expectedHeader) {
        $script:HeaderWarning = "Header avviker från förväntat format. Dashboard försöker läsa ändå."
    }

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $f = ConvertFrom-UpdateLogLine -Line $line
        if ($null -eq $f -or $f.Count -ne 13) {
            $script:BadLineCount++
            continue
        }

        $ts = [string]$f[0]
        $dt = Try-GetDateTime -Text $ts

        $action = ([string]$f[3]).Trim().ToUpperInvariant()
        $pn     = ([string]$f[4]).Trim()
        $rowNo  = ([string]$f[5]).Trim()

        $oldLot = [string]$f[6]
        $oldExp = [string]$f[7]
        $oldQty = [string]$f[8]
        $newLot = [string]$f[9]
        $newExp = [string]$f[10]
        $newQty = [string]$f[11]

        $changeText = ""
        switch ($action) {
            "QTY"    { $changeText = ("Qty: {0} → {1}" -f $oldQty, $newQty) }
            "CHECK"  { $changeText = "Checked: datum + SIGN" }
            "ADD"    { $changeText = ("ADD: {0} / {1} / {2}" -f $newLot, $newExp, $newQty) }
            "REMOVE" { $changeText = ("REMOVE: {0} / {1} / {2}" -f $oldLot, $oldExp, $oldQty) }
            default  { $changeText = ("{0} → {1}" -f $oldQty, $newQty) }
        }

        $searchText = (@(
            $ts, $f[1], $f[2], $action, $pn, $rowNo,
            $oldLot, $oldExp, $oldQty, $newLot, $newExp, $newQty, $f[12], $changeText
        ) -join " ").ToLowerInvariant()

        $rows.Add([pscustomobject]@{
            Timestamp   = $ts
            TimestampDt = $dt
            User        = [string]$f[1]
            Signature   = [string]$f[2]
            Action      = $action
            PN          = $pn
            Row         = $rowNo
            OldLot      = $oldLot
            OldExp      = $oldExp
            OldQty      = $oldQty
            NewLot      = $newLot
            NewExp      = $newExp
            NewQty      = $newQty
            Machine     = [string]$f[12]
            Change      = $changeText
            SearchText  = $searchText
        })
    }

    return @($rows | Sort-Object TimestampDt -Descending)
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Kontrollprovsfil Log Dashboard"
        Height="760"
        Width="1220"
        MinHeight="650"
        MinWidth="1050"
        WindowStartupLocation="CenterScreen"
        Background="#F4F7FB"
        FontFamily="Segoe UI">
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="86"/>
            <RowDefinition Height="96"/>
            <RowDefinition Height="72"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="30"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" CornerRadius="14" Background="#0F172A" Padding="18">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel>
                    <TextBlock Text="Kontrollprovsfil – Log Dashboard" Foreground="White" FontSize="26" FontWeight="SemiBold"/>
                    <TextBlock x:Name="LogPathText" Text="Loggfil" Foreground="#CBD5E1" FontSize="12" Margin="0,8,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="RefreshButton" Content="↻ Uppdatera" Width="118" Height="34" Margin="0,0,8,0" Background="#38BDF8" Foreground="#0F172A" FontWeight="SemiBold"/>
                    <Button x:Name="OpenCsvButton" Content="Öppna CSV" Width="100" Height="34" Margin="0,0,8,0"/>
                    <Button x:Name="ExportButton" Content="Exportera vy" Width="110" Height="34"/>
                </StackPanel>
            </Grid>
        </Border>

        <UniformGrid Grid.Row="1" Columns="5" Margin="0,14,0,0">
            <Border Background="White" CornerRadius="12" Padding="14" Margin="0,0,10,0">
                <StackPanel>
                    <TextBlock Text="Totalt loggade" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="TotalCountText" Text="0" Foreground="#0F172A" FontSize="28" FontWeight="SemiBold"/>
                </StackPanel>
            </Border>
            <Border Background="White" CornerRadius="12" Padding="14" Margin="0,0,10,0">
                <StackPanel>
                    <TextBlock Text="Visas just nu" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="FilteredCountText" Text="0" Foreground="#0F172A" FontSize="28" FontWeight="SemiBold"/>
                </StackPanel>
            </Border>
            <Border Background="White" CornerRadius="12" Padding="14" Margin="0,0,10,0">
                <StackPanel>
                    <TextBlock Text="CHECK" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="CheckCountText" Text="0" Foreground="#7C3AED" FontSize="28" FontWeight="SemiBold"/>
                </StackPanel>
            </Border>
            <Border Background="White" CornerRadius="12" Padding="14" Margin="0,0,10,0">
                <StackPanel>
                    <TextBlock Text="QTY" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="QtyCountText" Text="0" Foreground="#0284C7" FontSize="28" FontWeight="SemiBold"/>
                </StackPanel>
            </Border>
            <Border Background="White" CornerRadius="12" Padding="14">
                <StackPanel>
                    <TextBlock Text="Senaste ändring" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="LastChangeText" Text="-" Foreground="#0F172A" FontSize="15" FontWeight="SemiBold" TextWrapping="Wrap"/>
                </StackPanel>
            </Border>
        </UniformGrid>

        <Border Grid.Row="2" Background="White" CornerRadius="12" Padding="14" Margin="0,14,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="2*"/>
                    <ColumnDefinition Width="160"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0">
                    <TextBlock Text="Sök" Foreground="#64748B" FontSize="12"/>
                    <TextBox x:Name="SearchBox" Height="30" FontSize="14" VerticalContentAlignment="Center"
                             ToolTip="Sök på P/N, lot, användare, signatur, dator, qty eller datum"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Margin="14,0,0,0">
                    <TextBlock Text="Action" Foreground="#64748B" FontSize="12"/>
                    <ComboBox x:Name="ActionFilter" Height="30" SelectedIndex="0">
                        <ComboBoxItem Content="Alla"/>
                        <ComboBoxItem Content="ADD"/>
                        <ComboBoxItem Content="QTY"/>
                        <ComboBoxItem Content="REMOVE"/>
                        <ComboBoxItem Content="CHECK"/>
                        <ComboBoxItem Content="OVERWRITE"/>
                    </ComboBox>
                </StackPanel>

                <StackPanel Grid.Column="2" Margin="14,0,0,0">
                    <TextBlock Text="Status" Foreground="#64748B" FontSize="12"/>
                    <TextBlock x:Name="StatusText" Text="Redo" Foreground="#334155" FontSize="13" TextWrapping="Wrap" Margin="0,6,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <Border Grid.Row="3" Background="White" CornerRadius="12" Padding="10" Margin="0,14,0,0">
            <DataGrid x:Name="LogGrid"
                      AutoGenerateColumns="False"
                      IsReadOnly="True"
                      CanUserSortColumns="True"
                      HeadersVisibility="Column"
                      GridLinesVisibility="None"
                      AlternatingRowBackground="#F8FAFC"
                      RowBackground="White"
                      BorderThickness="0"
                      FontSize="13">
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Tid" Binding="{Binding Timestamp}" Width="148"/>
                    <DataGridTextColumn Header="Action" Binding="{Binding Action}" Width="86"/>
                    <DataGridTextColumn Header="P/N" Binding="{Binding PN}" Width="105"/>
                    <DataGridTextColumn Header="Rad" Binding="{Binding Row}" Width="55"/>
                    <DataGridTextColumn Header="Ändring" Binding="{Binding Change}" Width="230"/>
                    <DataGridTextColumn Header="Old Lot" Binding="{Binding OldLot}" Width="105"/>
                    <DataGridTextColumn Header="New Lot" Binding="{Binding NewLot}" Width="105"/>
                    <DataGridTextColumn Header="Old Qty" Binding="{Binding OldQty}" Width="95"/>
                    <DataGridTextColumn Header="New Qty" Binding="{Binding NewQty}" Width="95"/>
                    <DataGridTextColumn Header="SIGN" Binding="{Binding Signature}" Width="70"/>
                    <DataGridTextColumn Header="User" Binding="{Binding User}" Width="145"/>
                    <DataGridTextColumn Header="Dator" Binding="{Binding Machine}" Width="145"/>
                </DataGrid.Columns>
            </DataGrid>
        </Border>

        <Grid Grid.Row="4" Margin="4,8,4,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="FooterText" Foreground="#64748B" FontSize="12"/>
            <TextBlock Grid.Column="1" Text="Tips: sök på t.ex. P/N, CHECK, signatur eller lot." Foreground="#64748B" FontSize="12"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$LogPathText       = $window.FindName("LogPathText")
$RefreshButton    = $window.FindName("RefreshButton")
$OpenCsvButton    = $window.FindName("OpenCsvButton")
$ExportButton     = $window.FindName("ExportButton")
$TotalCountText   = $window.FindName("TotalCountText")
$FilteredCountText= $window.FindName("FilteredCountText")
$CheckCountText   = $window.FindName("CheckCountText")
$QtyCountText     = $window.FindName("QtyCountText")
$LastChangeText   = $window.FindName("LastChangeText")
$SearchBox        = $window.FindName("SearchBox")
$ActionFilter     = $window.FindName("ActionFilter")
$StatusText       = $window.FindName("StatusText")
$LogGrid          = $window.FindName("LogGrid")
$FooterText       = $window.FindName("FooterText")

function Get-SelectedAction {
    $item = $ActionFilter.SelectedItem
    if ($null -eq $item) { return "Alla" }
    if ($item -is [System.Windows.Controls.ComboBoxItem]) { return [string]$item.Content }
    return [string]$item
}

function Update-DashboardView {
    $needle = ""
    if ($SearchBox.Text) {
        $needle = $SearchBox.Text.Trim().ToLowerInvariant()
    }

    $selectedAction = Get-SelectedAction

    $filtered = @($script:AllRows | Where-Object {
        $actionOk = ($selectedAction -eq "Alla" -or $_.Action -eq $selectedAction)
        $searchOk = ([string]::IsNullOrWhiteSpace($needle) -or $_.SearchText.Contains($needle))
        $actionOk -and $searchOk
    })

    $LogGrid.ItemsSource = $filtered

    $TotalCountText.Text = [string]$script:AllRows.Count
    $FilteredCountText.Text = [string]$filtered.Count
    $CheckCountText.Text = [string](@($script:AllRows | Where-Object { $_.Action -eq "CHECK" }).Count)
    $QtyCountText.Text = [string](@($script:AllRows | Where-Object { $_.Action -eq "QTY" }).Count)

    if ($script:AllRows.Count -gt 0) {
        $last = $script:AllRows[0]
        $LastChangeText.Text = ("{0}`n{1} {2}" -f $last.Timestamp, $last.Action, $last.PN)
    }
    else {
        $LastChangeText.Text = "-"
    }

    $msg = "Laddad: {0} | Rader: {1} | Ignorerade rader: {2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $script:AllRows.Count, $script:BadLineCount
    if (-not [string]::IsNullOrWhiteSpace($script:HeaderWarning)) {
        $msg = "$msg | $script:HeaderWarning"
    }

    $StatusText.Text = $msg
    $FooterText.Text = ("Loggfil: {0}" -f $script:LogPath)
}

function Load-DashboardData {
    $LogPathText.Text = ("Loggfil: {0}" -f $script:LogPath)
    $script:AllRows = @(Read-UpdateLog -Path $script:LogPath)
    Update-DashboardView
}

$RefreshButton.Add_Click({
    Load-DashboardData
})

$OpenCsvButton.Add_Click({
    if (Test-Path -LiteralPath $script:LogPath) {
        Invoke-Item -LiteralPath $script:LogPath
    }
    else {
        [System.Windows.MessageBox]::Show("Hittar inte loggfilen:`n$script:LogPath", "Loggfil saknas", "OK", "Warning") | Out-Null
    }
})

$ExportButton.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = "Exportera filtrerad loggvy"
    $dialog.Filter = "CSV-fil (*.csv)|*.csv"
    $dialog.FileName = ("Kontrollprovsfil_Loggvy_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

    if ($dialog.ShowDialog() -eq $true) {
        $items = @()
        foreach ($item in $LogGrid.ItemsSource) { $items += $item }

        $items |
            Select-Object Timestamp,User,Signature,Action,PN,Row,OldLot,OldExp,OldQty,NewLot,NewExp,NewQty,Machine,Change |
            Export-Csv -LiteralPath $dialog.FileName -NoTypeInformation -Delimiter ';' -Encoding UTF8

        [System.Windows.MessageBox]::Show("Exporterad:`n$($dialog.FileName)", "Klart", "OK", "Information") | Out-Null
    }
})

$SearchBox.Add_TextChanged({
    Update-DashboardView
})

$ActionFilter.Add_SelectionChanged({
    Update-DashboardView
})

Load-DashboardData
$null = $window.ShowDialog()
