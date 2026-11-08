{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the UMAPINFO records of the game                       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.MapInfo.Records;

interface

uses
  DelphiDoom.MapInfo.Intf,
  DelphiDoom.MapInfo.Types,
  DelphiDoom.Engine.MapInfo.Intf,
  p_umapinfo;

type
  /// <summary>
  ///   The records mapentry_t of the engine from the entries of the UMAPINFO library (it was
  ///   U_ParseMapInfo, U_FreeMapInfo and ubigstringtostring of p_umapinfo.pas; the records and
  ///   the variables u_mapinfo and default_mapinfo stay in that unit, which many modules read)
  /// </summary>
  TEngineMapInfoRecords = class(TInterfacedObject, IEngineMapInfoRecords)
  strict private
    FLoader: IMapInfoLoader;
    FCatalog: IMapInfoCatalog;
    class function TextToBigString(const AText: string): ubigstring_t; static;
    class procedure FreeMap(AEntry: Pmapentry_t); static;
    class procedure FreeMaps(var AInfo: umapinfo_t); static;
    class procedure MakeMapEntry(const AEntry: TMapInfoEntry; AEngineEntry: Pmapentry_t); static;
  public
    /// <param name="ALoader">Reads the lumps and merges the maps into the catalog</param>
    /// <param name="ACatalog">The maps and the defaults that the loader made</param>
    constructor Create(const ALoader: IMapInfoLoader; const ACatalog: IMapInfoCatalog);
    /// <summary>The text of a record of the engine, up to the terminator (was ubigstringtostring)</summary>
    class function BigStringToString(const ABigString: ubigstring_t): string; static;
    procedure Load(AIsDefault: Boolean; const ALumpName: string);
    procedure Release;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  z_zone;

{ TEngineMapInfoRecords }

constructor TEngineMapInfoRecords.Create(const ALoader: IMapInfoLoader;
  const ACatalog: IMapInfoCatalog);
begin
  inherited Create;
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  if not Assigned(ACatalog) then
    raise EArgumentNilException.Create('ACatalog');
  FLoader := ALoader;
  FCatalog := ACatalog;
end;

class function TEngineMapInfoRecords.BigStringToString(const ABigString: ubigstring_t): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 0;
  while ABigString[LIndex] <> #0 do
  begin
    Result := Result + string(ABigString[LIndex]);
    Inc(LIndex);
    if LIndex = BIGSTRINGSIZE then
      Exit;
  end;
end;

// The whole text, up to what fits with the terminator
class function TEngineMapInfoRecords.TextToBigString(const AText: string): ubigstring_t;
var
  LIndex: Integer;
  LLength: Integer;
begin
  ZeroMemory(@Result, SizeOf(Result));
  LLength := Length(AText);
  if LLength > BIGSTRINGSIZE - 1 then
    LLength := BIGSTRINGSIZE - 1;
  for LIndex := 1 to LLength do
    Result[LIndex - 1] := AnsiChar(AText[LIndex]);
end;

class procedure TEngineMapInfoRecords.FreeMap(AEntry: Pmapentry_t);
begin
  AEntry.mapname := '';
  AEntry.levelname := '';
  AEntry.mlabel := '';
  if AEntry.bossactions <> nil then
    Z_Free(AEntry.bossactions);
  AEntry.bossactions := nil;
end;

class procedure TEngineMapInfoRecords.FreeMaps(var AInfo: umapinfo_t);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AInfo.mapcount - 1 do
    FreeMap(@AInfo.maps[LIndex]);
  if AInfo.maps <> nil then
    Z_Free(AInfo.maps);
  AInfo.maps := nil;
  AInfo.mapcount := 0;
end;

class procedure TEngineMapInfoRecords.MakeMapEntry(const AEntry: TMapInfoEntry;
  AEngineEntry: Pmapentry_t);
var
  LIndex: Integer;
begin
  ZeroMemory(AEngineEntry, SizeOf(mapentry_t));
  AEngineEntry.mapname := ShortString(AEntry.MapName);
  AEngineEntry.levelname := ShortString(AEntry.LevelName);
  AEngineEntry.mlabel := ShortString(AEntry.MapLabel);
  AEngineEntry.intertext := TextToBigString(AEntry.InterText);
  AEngineEntry.intertextsecret := TextToBigString(AEntry.InterTextSecret);
  AEngineEntry.levelpic := ShortString(AEntry.LevelPic);
  AEngineEntry.nextmap := ShortString(AEntry.NextMap);
  AEngineEntry.nextsecret := ShortString(AEntry.NextSecret);
  AEngineEntry.music := ShortString(AEntry.Music);
  AEngineEntry.musicnum := AEntry.MusicNumber;
  AEngineEntry.skytexture := ShortString(AEntry.SkyTexture);
  AEngineEntry.skytexture2 := ShortString(AEntry.SkyTexture2);
  AEngineEntry.endpic := ShortString(AEntry.EndPic);
  AEngineEntry.exitpic := ShortString(AEntry.ExitPic);
  AEngineEntry.enterpic := ShortString(AEntry.EnterPic);
  AEngineEntry.interbackdrop := ShortString(AEntry.InterBackdrop);
  AEngineEntry.intermusic := ShortString(AEntry.InterMusic);
  AEngineEntry.intermusicnum := AEntry.InterMusicNumber;
  AEngineEntry.partime := AEntry.ParTime;
  AEngineEntry.nointermission := AEntry.NoIntermission;
  AEngineEntry.lightning := AEntry.Lightning;
  AEngineEntry.nojump := AEntry.NoJump;
  AEngineEntry.nocrouch := AEntry.NoCrouch;
  if AEntry.BossActionsCleared then
    AEngineEntry.numbossactions := -1
  else
    AEngineEntry.numbossactions := Length(AEntry.BossActions);
  if AEngineEntry.numbossactions > 0 then
  begin
    AEngineEntry.bossactions := Z_Malloc(SizeOf(bossaction_t) * AEngineEntry.numbossactions,
      PU_STATIC, nil);
    for LIndex := 0 to AEngineEntry.numbossactions - 1 do
    begin
      AEngineEntry.bossactions[LIndex].typ := AEntry.BossActions[LIndex].ActorType;
      AEngineEntry.bossactions[LIndex].special := AEntry.BossActions[LIndex].Special;
      AEngineEntry.bossactions[LIndex].tag := AEntry.BossActions[LIndex].Tag;
    end;
  end;
end;

procedure TEngineMapInfoRecords.Load(AIsDefault: Boolean; const ALumpName: string);
var
  LIndex: Integer;
begin
  FLoader.Load(ALumpName, AIsDefault);

  FreeMaps(default_mapinfo);
  default_mapinfo.mapcount := FCatalog.DefaultCount;
  if default_mapinfo.mapcount > 0 then
  begin
    default_mapinfo.maps := Z_Malloc(SizeOf(mapentry_t) * default_mapinfo.mapcount, PU_LEVEL, nil);
    for LIndex := 0 to default_mapinfo.mapcount - 1 do
      MakeMapEntry(FCatalog.GetDefault(LIndex), @default_mapinfo.maps[LIndex]);
  end;

  FreeMaps(u_mapinfo);
  u_mapinfo.mapcount := FCatalog.MapCount;
  if u_mapinfo.mapcount > 0 then
  begin
    u_mapinfo.maps := Z_Malloc(SizeOf(mapentry_t) * u_mapinfo.mapcount, PU_STATIC, nil);
    for LIndex := 0 to u_mapinfo.mapcount - 1 do
      MakeMapEntry(FCatalog.GetMap(LIndex), @u_mapinfo.maps[LIndex]);
  end;
end;

procedure TEngineMapInfoRecords.Release;
begin
  FreeMaps(u_mapinfo);
  FCatalog.ClearMaps;
end;

end.
