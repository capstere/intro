# Skapa dessa kolumner först i SharePoint Lists

Viktigt: skapa kolumnnamnen exakt som de står här, utan mellanslag. Använd helst **Single line of text** för textfält, inte Choice, så att Power Apps-koden nedan kan patcha vanliga textvärden utan `{Value: ...}`.

## CM_PN_Master

| Column name | Type | Required | Kommentar |
|---|---|---:|---|
| MaterialCategory | Single line of text | No | T.ex. `Control material`, `Bulk SR`, `Customer SR` |
| QtyMode | Single line of text | No | Endast `Count` eller `Volume` |
| DisplayUnit | Single line of text | No | T.ex. `Box`, `Bottle`, `EA`, `L` |
| LowStockLimit | Number | No | Valfritt larmvärde |
| CheckIntervalDays | Number | No | T.ex. 30 |

## CM_Lots

| Column name | Type | Required | Kommentar |
|---|---|---:|---|
| MaterialCategory | Single line of text | No | Kopieras från master vid sparning |
| QtyMode | Single line of text | No | `Count` eller `Volume` |
| QtyUnit | Single line of text | No | T.ex. `Box`, `Bottle`, `EA`, `L` |
| QtyEA | Number | No | Används när QtyMode = Count |
| VolumeL | Number | No | Används när QtyMode = Volume |
| InitialQty | Number | No | Ursprungligt saldo vid Add |
| LifecycleStatus | Single line of text | No | `Active`, `Archived` |
| RemovedAt | Date and time | No | Sätts vid Delete/Archive |
| RemovedByName | Single line of text | No | Sätts vid Delete/Archive |
| RemovedByEmail | Single line of text | No | Sätts vid Delete/Archive |
| RemovalReason | Multiple lines of text | No | Sätts vid Delete/Archive |

## CM_Transactions

| Column name | Type | Required | Kommentar |
|---|---|---:|---|
| MaterialCategory | Single line of text | No | Kopieras till loggen |
| QtyMode | Single line of text | No | `Count` eller `Volume` |
| QtyUnit | Single line of text | No | T.ex. `Box`, `Bottle`, `EA`, `L` |
| OldQtyEA | Number | No | Gammalt antal, Count |
| NewQtyEA | Number | No | Nytt antal, Count |
| OldVolumeL | Number | No | Gammal volym, Volume |
| NewVolumeL | Number | No | Ny volym, Volume |

Efter detta i Power Apps Studio:

1. Data → `CM_PN_Master` → Refresh
2. Data → `CM_Lots` → Refresh
3. Data → `CM_Transactions` → Refresh
4. Kör `App.OnStart` igen
