{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the catalog of the maps                     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Catalog;

interface

uses
  System.Generics.Collections, DelphiDoom.MapInfo.Types, DelphiDoom.MapInfo.Intf;

type
  /// <summary>The maps of UMAPINFO, with the merge with the defaults of UMAPDEF</summary>
  TMapInfoCatalog = class(TInterfacedObject, IMapInfoCatalog)
  private
    FMaps: TList<TMapInfoEntry>;
    FDefaults: TList<TMapInfoEntry>;
    FMusic: IMapMusicResolver;
    function MergedWithDefault(const AParsed: TMapInfoEntry; AIndex: Integer): TMapInfoEntry;
    class function IndexOfName(AList: TList<TMapInfoEntry>; const AMapName: string): Integer; static;
  public
    constructor Create(const AMusic: IMapMusicResolver);
    destructor Destroy; override;
    procedure AddParsed(const AEntry: TMapInfoEntry; AIsDefault: Boolean);
    procedure ClearMaps;
    procedure ClearDefaults;
    function MapCount: Integer;
    function GetMap(AIndex: Integer): TMapInfoEntry;
    function DefaultCount: Integer;
    function GetDefault(AIndex: Integer): TMapInfoEntry;
    function IndexOfMap(const AMapName: string): Integer;
    function IndexOfDefault(const AMapName: string): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapInfo.Merger;

const
  SNeedsMusic = 'TMapInfoCatalog needs a music resolver';

{ TMapInfoCatalog }

constructor TMapInfoCatalog.Create(const AMusic: IMapMusicResolver);
begin
  inherited Create;
  if not Assigned(AMusic) then
    raise EArgumentNilException.Create(SNeedsMusic);
  FMusic := AMusic;
  FMaps := TList<TMapInfoEntry>.Create;
  FDefaults := TList<TMapInfoEntry>.Create;
end;

destructor TMapInfoCatalog.Destroy;
begin
  FDefaults.Free;
  FMaps.Free;
  inherited Destroy;
end;

class function TMapInfoCatalog.IndexOfName(AList: TList<TMapInfoEntry>;
  const AMapName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AList.Count - 1 do
    if AList[LIndex].MapName = AMapName then
      Exit(LIndex);
  Result := -1;
end;

function TMapInfoCatalog.MergedWithDefault(const AParsed: TMapInfoEntry;
  AIndex: Integer): TMapInfoEntry;
begin
  // the default at the same position, whatever map it is of: the old code did so
  if FDefaults.Count > AIndex then
  begin
    Result := Default(TMapInfoEntry);
    TMapInfoMerger.Update(Result, FDefaults[AIndex], FMusic);
    TMapInfoMerger.Update(Result, AParsed, FMusic);
  end
  else
    Result := AParsed;
end;

procedure TMapInfoCatalog.AddParsed(const AEntry: TMapInfoEntry; AIsDefault: Boolean);
var
  LIndex: Integer;
begin
  if AIsDefault then
  begin
    FDefaults.Add(AEntry);
    Exit;
  end;

  // an entry of a map that is already there replaces it
  LIndex := IndexOfName(FMaps, AEntry.MapName);
  if LIndex >= 0 then
    FMaps[LIndex] := MergedWithDefault(AEntry, LIndex)
  else
    FMaps.Add(MergedWithDefault(AEntry, FMaps.Count));
end;

procedure TMapInfoCatalog.ClearMaps;
begin
  FMaps.Clear;
end;

procedure TMapInfoCatalog.ClearDefaults;
begin
  FDefaults.Clear;
end;

function TMapInfoCatalog.MapCount: Integer;
begin
  Result := FMaps.Count;
end;

function TMapInfoCatalog.GetMap(AIndex: Integer): TMapInfoEntry;
begin
  Result := FMaps[AIndex];
end;

function TMapInfoCatalog.DefaultCount: Integer;
begin
  Result := FDefaults.Count;
end;

function TMapInfoCatalog.GetDefault(AIndex: Integer): TMapInfoEntry;
begin
  Result := FDefaults[AIndex];
end;

function TMapInfoCatalog.IndexOfMap(const AMapName: string): Integer;
begin
  Result := IndexOfName(FMaps, AMapName);
end;

function TMapInfoCatalog.IndexOfDefault(const AMapName: string): Integer;
begin
  Result := IndexOfName(FDefaults, AMapName);
end;

end.
