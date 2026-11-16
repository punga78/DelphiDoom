{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the catalog of the music                     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Catalog;

interface

uses
  System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Types,
  DelphiDoom.MusInfo.Intf;

type
  /// <summary>
  ///   The (map, id) pairs of MUSINFO (the old musinfo array and P_AddMusInfo/P_FindMusinfoMusic).
  ///   It holds MUSINFO_MAX_ENTRIES pairs, the others are refused with a warning
  /// </summary>
  TMusInfoCatalog = class(TInterfacedObject, IMusInfoCatalog)
  private
    FEntries: TList<TMusInfoEntry>;
    FMusic: IMusInfoMusicResolver;
    FLog: ILog;
    function IndexOf(AMusicId: Integer; const AUpperMapName: string): Integer;
  public
    /// <param name="AMusic">Required</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AMusic: IMusInfoMusicResolver; const ALog: ILog);
    destructor Destroy; override;
    function Add(const AEntry: TMusInfoEntry): Boolean;
    procedure Clear;
    function Find(AMusicId: Integer; const AMapName: string): Integer;
    function Count: Integer;
    function GetEntry(AIndex: Integer): TMusInfoEntry;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings;

const
  SNeedsMusic = 'TMusInfoCatalog needs a music resolver';
  SFullMessage = 'P_AddMusInfo(): More than %d musinfo entries found, ignoring mus "%s" of map "%s"'#13#10;

{ TMusInfoCatalog }

constructor TMusInfoCatalog.Create(const AMusic: IMusInfoMusicResolver; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AMusic) then
    raise EArgumentNilException.Create(SNeedsMusic);
  FMusic := AMusic;
  FLog := ALog;
  FEntries := TList<TMusInfoEntry>.Create;
end;

destructor TMusInfoCatalog.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

function TMusInfoCatalog.IndexOf(AMusicId: Integer; const AUpperMapName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if (FEntries[LIndex].MusicId = AMusicId) and (FEntries[LIndex].MapName = AUpperMapName) then
      Exit(LIndex);
  Result := -1;
end;

function TMusInfoCatalog.Add(const AEntry: TMusInfoEntry): Boolean;
var
  LEntry: TMusInfoEntry;
  LIndex: Integer;
begin
  LEntry := AEntry;
  LEntry.MapName := TScannerStrings.UpperAscii(AEntry.MapName);
  LEntry.MusicName := TScannerStrings.UpperAscii(AEntry.MusicName);

  LIndex := IndexOf(LEntry.MusicId, LEntry.MapName);
  if (LIndex < 0) and (FEntries.Count >= MUSINFO_MAX_ENTRIES) then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SFullMessage, [FEntries.Count + 1, LEntry.MusicName, LEntry.MapName]));
    Exit(False);
  end;

  LEntry.MusicNumber := FMusic.MusicNumberFor(LEntry.MusicName);
  if LIndex < 0 then
    FEntries.Add(LEntry)
  else
    FEntries[LIndex] := LEntry;
  Result := True;
end;

procedure TMusInfoCatalog.Clear;
begin
  FEntries.Clear;
end;

function TMusInfoCatalog.Find(AMusicId: Integer; const AMapName: string): Integer;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AMusicId, TScannerStrings.UpperAscii(AMapName));
  if LIndex < 0 then
    Result := -1
  else
    Result := FEntries[LIndex].MusicNumber;
end;

function TMusInfoCatalog.Count: Integer;
begin
  Result := FEntries.Count;
end;

function TMusInfoCatalog.GetEntry(AIndex: Integer): TMusInfoEntry;
begin
  Result := FEntries[AIndex];
end;

end.
