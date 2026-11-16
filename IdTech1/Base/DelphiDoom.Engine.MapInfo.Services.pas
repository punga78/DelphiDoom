{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the UMAPINFO library asks of the game             }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.MapInfo.Services;

{$IFNDEF HEXEN}

interface

uses
  DelphiDoom.MapInfo.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The questions of the UMAPINFO parser, answered by the game: is a map name valid, does a
  ///   lump exist, which number has a music, which type an actor name, and the episode menu.
  ///   One class for several small interfaces: each user of the library sees only its own
  /// </summary>
  TEngineMapInfoServices = class(TInterfacedObject, IMapNameValidator, IMapLumpCatalog,
    IMapMusicResolver, IMapActorResolver, IMapEpisodeSink)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function IsValidMapName(const AName: string): Boolean;
    function LumpExists(const AName: string): Boolean;
    function MusicNumberFor(const AName: string): Integer;
    function ActorTypeFor(const AUpperName: string): Integer;
    procedure ClearEpisodes;
    procedure AddEpisode(const AMapName, APicture, AText: string; AKey: Char);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  g_game,
  info_common,
{$IFNDEF STRIFE}
  m_menu,
{$ENDIF}
  p_uactornames,
  sounds;

{ TEngineMapInfoServices }

constructor TEngineMapInfoServices.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineMapInfoServices.IsValidMapName(const AName: string): Boolean;
begin
  Result := G_ValidateMapName(AName, nil, nil);
end;

function TEngineMapInfoServices.LumpExists(const AName: string): Boolean;
begin
  Result := FLumps.CheckNumForName(AName) >= 0;
end;

function TEngineMapInfoServices.MusicNumberFor(const AName: string): Integer;
begin
  Result := S_GetMusicNumForName(AName);
end;

function TEngineMapInfoServices.ActorTypeFor(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to NUMACTORNAMES - 1 do
    if AUpperName = strupper(ActorNames[LIndex]) then
      Exit(LIndex);
  Result := Info_GetMobjNumForName(AUpperName);
end;

procedure TEngineMapInfoServices.ClearEpisodes;
begin
{$IFNDEF STRIFE}
  M_ClearEpisodes;
{$ENDIF}
  // Strife has no episodes: the composition root does not give it as a sink
end;

procedure TEngineMapInfoServices.AddEpisode(const AMapName, APicture, AText: string; AKey: Char);
begin
{$IFNDEF STRIFE}
  M_AddEpisode(AMapName, APicture, AText, AKey);
{$ENDIF}
end;

{$ELSE}

interface

implementation

{$ENDIF}

end.
