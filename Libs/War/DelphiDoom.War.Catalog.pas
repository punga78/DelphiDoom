{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what each record of DATA.WAR is                   }
{                                                                              }
{  Port of war1 (acoto87/war1), the table assets[] of war_database.h and       }
{  wres_tryGetPredefinedCustomMapIndex of war_resources.c, (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Catalog;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Intf;

type
  /// <summary>
  ///   The table of the records the game knows: index, type, a name and three numbers whose meaning depends on
  ///   the type (for a tiles record the two palettes, for a level info the race and whether it is a custom map).
  ///   The table is given to the constructor, so a test can give its own; TWarFactory has the one of the original
  /// </summary>
  TWarCatalog = class(TInterfacedObject, IWarCatalog)
  strict private
    FEntries: TArray<TWarCatalogEntry>;
    FByIndex: TDictionary<Integer, Integer>;
    FSkipped: TDictionary<Integer, Boolean>;
    class function SameName(const ALeft, ARight: string): Boolean; static;
  public
    constructor Create(const AEntries: TArray<TWarCatalogEntry>);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetEntry(APosition: Integer): TWarCatalogEntry;
    function TryFind(AIndex: Integer; out AEntry: TWarCatalogEntry): Boolean;
    function RecordTypeOf(AIndex: Integer): TWarRecordType;
    function IsSkipped(AIndex: Integer): Boolean;
    function TryGetPredefinedCustomMapIndex(const AName: string; out AIndex: Integer): Boolean;
  end;

implementation

{ TWarCatalog }

constructor TWarCatalog.Create(const AEntries: TArray<TWarCatalogEntry>);
var
  LPosition: Integer;
begin
  inherited Create;
  FEntries := Copy(AEntries);
  FByIndex := TDictionary<Integer, Integer>.Create;
  FSkipped := TDictionary<Integer, Boolean>.Create;
  for LPosition := 0 to High(FEntries) do
  begin
    // the first entry of an index is the one a search finds
    if not FByIndex.ContainsKey(FEntries[LPosition].Index) then
      FByIndex.Add(FEntries[LPosition].Index, LPosition);
    // skipDecompress[] of wg_loadDataFile: any entry with an unknown type
    if FEntries[LPosition].RecordType = wrtUnknown then
      FSkipped.AddOrSetValue(FEntries[LPosition].Index, True);
  end;
end;

destructor TWarCatalog.Destroy;
begin
  FSkipped.Free;
  FByIndex.Free;
  inherited Destroy;
end;

class function TWarCatalog.SameName(const ALeft, ARight: string): Boolean;
var
  LIndex: Integer;
  LLeft: Char;
  LRight: Char;
begin
  Result := Length(ALeft) = Length(ARight);
  if not Result then
    Exit;
  for LIndex := 1 to Length(ALeft) do
  begin
    LLeft := ALeft[LIndex];
    LRight := ARight[LIndex];
    // only the ASCII letters: the names are bytes of a table, not text of a language
    if (LLeft >= 'a') and (LLeft <= 'z') then
      LLeft := Char(Ord(LLeft) - 32);
    if (LRight >= 'a') and (LRight <= 'z') then
      LRight := Char(Ord(LRight) - 32);
    if LLeft <> LRight then
      Exit(False);
  end;
end;

function TWarCatalog.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TWarCatalog.GetEntry(APosition: Integer): TWarCatalogEntry;
begin
  if (APosition < 0) or (APosition >= Length(FEntries)) then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [APosition, Length(FEntries)]);
  Result := FEntries[APosition];
end;

function TWarCatalog.TryFind(AIndex: Integer; out AEntry: TWarCatalogEntry): Boolean;
var
  LPosition: Integer;
begin
  Result := FByIndex.TryGetValue(AIndex, LPosition);
  if Result then
    AEntry := FEntries[LPosition]
  else
    AEntry := Default(TWarCatalogEntry);
end;

function TWarCatalog.RecordTypeOf(AIndex: Integer): TWarRecordType;
var
  LEntry: TWarCatalogEntry;
begin
  if TryFind(AIndex, LEntry) then
    Result := LEntry.RecordType
  else
    Result := wrtUnknown;
end;

function TWarCatalog.IsSkipped(AIndex: Integer): Boolean;
begin
  Result := FSkipped.ContainsKey(AIndex);
end;

function TWarCatalog.TryGetPredefinedCustomMapIndex(const AName: string; out AIndex: Integer): Boolean;
var
  LPosition: Integer;
begin
  AIndex := 0;
  for LPosition := 0 to High(FEntries) do
  begin
    if (FEntries[LPosition].RecordType = wrtLevelInfo) and (FEntries[LPosition].Param2 = 1) and
      SameName(AName, FEntries[LPosition].Name) then
    begin
      AIndex := FEntries[LPosition].Index;
      Exit(True);
    end;
  end;
  Result := False;
end;

end.
