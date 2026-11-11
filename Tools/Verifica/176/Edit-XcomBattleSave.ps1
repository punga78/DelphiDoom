<#
  Cambia un salvataggio con una battaglia in corso (testo .sav o start.sav.gz) e lo scrive come start.sav.gz, per
  preparare uno scenario di Compare-XcomBattle.ps1 che i salvataggi del repository non hanno (un oggetto in mano, un
  alieno accanto a un soldato, una ferita...). Il blocco -Edit lavora sulle righe ($L) con le funzioni:
    SetUnit <id> <chiave> <valore>         campo scalare di un'unita' di battleGame.units (direction, tu, visible...)
    SetUnitList <id> <chiave> <valori>     lista di un'unita' (position, fatalWounds...)
    SetItem <id> <chiave> <valore>         campo di un oggetto di battleGame.items (aggiunto se manca)
    DropItemKey <id> <chiave>              toglie un campo di un oggetto (ammoItem...)
  Esempio (medikit nella mano destra del soldato 1, soldato 4 ferito davanti a lui):
    Edit-XcomBattleSave.ps1 -In Tests\Data\XcomBattle\bg\g01_2\start.sav.gz -OutGz <radice>\Tests\Data\XcomBattle\bg\medi\start.sav.gz -Edit {
      SetUnitList 4 'position' @(7,3,0); SetUnit 1 'direction' '0'; SetUnitList 4 'fatalWounds' @(0,2,1,0,0,0)
      SetItem 9 'type' 'STR_MEDI_KIT'; DropItemKey 9 'ammoItem' }
  Gli oggetti alieni vogliono la ricerca: aggiungere a $L una lista 'discovered:' di primo livello con i loro nomi.
#>
param([string]$In,[string]$OutGz,[scriptblock]$Edit)
# Reads a .sav (text) or .sav.gz, lets $Edit change the list of lines ($L, a List[string]) and writes a start.sav.gz
function ReadText($p){ if($p -like '*.gz'){ $gz=New-Object IO.Compression.GZipStream([IO.File]::OpenRead($p),[IO.Compression.CompressionMode]::Decompress); $r=New-Object IO.StreamReader($gz); $t=$r.ReadToEnd(); $r.Close(); $t } else { [IO.File]::ReadAllText($p) } }
$L = New-Object 'System.Collections.Generic.List[string]'
$L.AddRange([string[]]((ReadText $In).Replace("`r`n","`n").Split("`n")))
function UnitLine([int]$id){ $u=$L.IndexOf('  units:'); for($i=$u;$i -lt $L.Count;$i++){ if($L[$i] -eq "    - id: $id"){ return $i } }; throw "unit $id" }
function SetUnit([int]$id,[string]$key,[string]$value){ $i=UnitLine $id; for($k=$i+1;$k -lt $L.Count;$k++){ if($L[$k] -match '^    - id:'){ break }; if($L[$k] -match "^      $key`:"){ $L[$k]="      $key`: $value"; return } }; throw "unit $id key $key" }
function SetUnitList([int]$id,[string]$key,[int[]]$values){ $i=UnitLine $id; for($k=$i+1;$k -lt $L.Count;$k++){ if($L[$k] -match "^      $key`:"){ for($v=0;$v -lt $values.Count;$v++){ $L[$k+1+$v]="        - $($values[$v])" }; return } }; throw "unit $id list $key" }
function ItemLine([int]$id){ $u=$L.IndexOf('  items:'); for($i=$u;$i -lt $L.Count;$i++){ if($L[$i] -eq "    - id: $id"){ return $i } }; throw "item $id" }
function SetItem([int]$id,[string]$key,[string]$value){ $i=ItemLine $id; for($k=$i+1;$k -lt $L.Count;$k++){ if($L[$k] -match '^    - id:' -or $L[$k] -notmatch '^      '){ break }; if($L[$k] -match "^      $key`:"){ $L[$k]="      $key`: $value"; return } }; $L.Insert($i+1,"      $key`: $value") }
function DropItemKey([int]$id,[string]$key){ $i=ItemLine $id; for($k=$i+1;$k -lt $L.Count;$k++){ if($L[$k] -match '^    - id:' -or $L[$k] -notmatch '^      '){ break }; if($L[$k] -match "^      $key`:"){ $L.RemoveAt($k); return } } }
. $Edit
$bytes=[Text.Encoding]::UTF8.GetBytes(($L -join "`n"))
New-Item -ItemType Directory -Force (Split-Path $OutGz) | Out-Null
$fs=[IO.File]::Create($OutGz); $gz=New-Object IO.Compression.GZipStream($fs,[IO.Compression.CompressionMode]::Compress); $gz.Write($bytes,0,$bytes.Length); $gz.Close(); $fs.Close()

