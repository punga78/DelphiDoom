{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the loader of the levels                          }
{                                                                              }
{  Port of war1 (acoto87/war1), the level part of wg_loadDataFile and          }
{  war_resources.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.Loader;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf;

type
  /// <summary>
  ///   Reads a level on demand from an archive and its catalog (the original loaded every level at start). A
  ///   record the level points to must be of the right type in the catalog: the original used whatever was
  ///   there, which for a wrong index was another kind of resource
  /// </summary>
  TWarLevelLoader = class(TInterfacedObject, IWarLevelLoader)
  strict private
    FArchive: IWarArchive;
    FCatalog: IWarCatalog;
    FLevelIndices: TArray<Integer>;
    function ReadMap(ALevel: Integer; ARecord: Integer; AType: TWarRecordType; const AName: string): TArray<Word>;
  public
    constructor Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog);
    function GetLevelCount: Integer;
    function GetLevelIndex(APosition: Integer): Integer;
    function IsLevel(AIndex: Integer): Boolean;
    function Load(AIndex: Integer): IWarLevel;
    function LoadInfo(AIndex: Integer): TWarLevelInfo;
  end;

implementation

uses
  DelphiDoom.War.Level, DelphiDoom.War.Level.InfoReader, DelphiDoom.War.Level.MapReader;

{ TWarLevelLoader }

constructor TWarLevelLoader.Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog);
var
  LPosition: Integer;
begin
  inherited Create;
  if not Assigned(AArchive) or not Assigned(ACatalog) then
    raise EWarException.Create(SWarStreamIsNil);
  FArchive := AArchive;
  FCatalog := ACatalog;
  for LPosition := 0 to ACatalog.Count - 1 do
    if ACatalog.GetEntry(LPosition).RecordType = wrtLevelInfo then
    begin
      SetLength(FLevelIndices, Length(FLevelIndices) + 1);
      FLevelIndices[High(FLevelIndices)] := ACatalog.GetEntry(LPosition).Index;
    end;
end;

function TWarLevelLoader.GetLevelCount: Integer;
begin
  Result := Length(FLevelIndices);
end;

function TWarLevelLoader.GetLevelIndex(APosition: Integer): Integer;
begin
  if (APosition < 0) or (APosition > High(FLevelIndices)) then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [APosition, Length(FLevelIndices)]);
  Result := FLevelIndices[APosition];
end;

function TWarLevelLoader.IsLevel(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FArchive.EntryCount) and
    (FCatalog.RecordTypeOf(AIndex) = wrtLevelInfo) and FArchive.IsAvailable(AIndex);
end;

function TWarLevelLoader.LoadInfo(AIndex: Integer): TWarLevelInfo;
var
  LEntry: TWarCatalogEntry;
begin
  if not IsLevel(AIndex) or not FCatalog.TryFind(AIndex, LEntry) then
    raise EWarException.CreateFmt(SWarLevelIsNotLevelInfo, [AIndex]);
  Result := TWarLevelInfoReader.Read(FArchive.ReadRecord(AIndex), AIndex, LEntry.Param1, LEntry.Param2 = 1);
end;

function TWarLevelLoader.ReadMap(ALevel: Integer; ARecord: Integer; AType: TWarRecordType;
  const AName: string): TArray<Word>;
begin
  if (ARecord >= FArchive.EntryCount) or (FCatalog.RecordTypeOf(ARecord) <> AType) or
    not FArchive.IsAvailable(ARecord) then
    raise EWarException.CreateFmt(SWarLevelRecordMissing, [ALevel, ARecord, AName]);
  Result := TWarLevelMapReader.Read(FArchive.ReadRecord(ARecord));
end;

function TWarLevelLoader.Load(AIndex: Integer): IWarLevel;
var
  LInfo: TWarLevelInfo;
begin
  LInfo := LoadInfo(AIndex);
  Result := TWarLevel.Create(LInfo,
    ReadMap(AIndex, LInfo.VisualIndex, wrtLevelVisual, 'visual'),
    ReadMap(AIndex, LInfo.PassableIndex, wrtLevelPassable, 'passable'));
end;

end.
