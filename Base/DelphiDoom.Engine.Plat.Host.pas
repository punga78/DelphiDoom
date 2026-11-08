{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the classic platforms ask to the game             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plat.Host;

// Not for Hexen: it has no classic platforms (see DelphiDoom.Engine.Plat.UdmfHost)

interface

uses
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>
  ///   The game side of the platforms of Doom, Heretic and Strife (p_plats): the plane move of the
  ///   floors, the sounds of the sector, the level time, the compatibility of the engine version and
  ///   the removal of a platform from the active ones. It is separate from p_plats because p_plats
  ///   needs the machine and the machine needs this host to run
  /// </summary>
  TEnginePlatHost = class(TInterfacedObject, IPlatHost)
  public
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      ADirection: Integer): TPlatMoveResult;
    function GetFloorHeight(ASector: Pointer): Integer;
    procedure PlaySound(ASector: Pointer; ASound: TPlatSound);
    function GetLevelTime: Integer;
    function IsModernEngine: Boolean;
    procedure RemovePlat(APlat: Pointer);
  end;

implementation

uses
  r_defs,
  p_spec,
  p_tick,
  p_floor,
  p_plats,
  s_sound,
  sounddata,
{$IF DEFINED(DOOM) OR DEFINED(HERETIC)}
  doomdef,
  g_game,
{$IFEND}
  m_fixed;

{ TEnginePlatHost }

function TEnginePlatHost.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer;
  ACrush: Boolean; ADirection: Integer): TPlatMoveResult;
begin
  case T_MovePlane(Psector_t(ASector), ASpeed, ADestination, ACrush, 0, ADirection) of
    crushed:
      Result := TPlatMoveResult.Crushed;
    pastdest:
      Result := TPlatMoveResult.PastDestination;
  else
    Result := TPlatMoveResult.Ok;
  end;
end;

function TEnginePlatHost.GetFloorHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).floorheight;
end;

procedure TEnginePlatHost.PlaySound(ASector: Pointer; ASound: TPlatSound);
begin
  case ASound of
    TPlatSound.Move:
      S_StartSound(@Psector_t(ASector).soundorg, Ord(sfx_stnmov));
    TPlatSound.Start:
      S_StartSound(@Psector_t(ASector).soundorg, Ord(sfx_pstart));
    TPlatSound.Stop:
      S_StartSound(@Psector_t(ASector).soundorg, Ord(sfx_pstop));
  end;
end;

function TEnginePlatHost.GetLevelTime: Integer;
begin
  Result := leveltime;
end;

function TEnginePlatHost.IsModernEngine: Boolean;
begin
{$IF DEFINED(DOOM) OR DEFINED(HERETIC)}
  Result := G_PlayingEngineVersion > VERSION115;
{$ELSE}
  // Strife has no engine versions before the current one and its rules never ask
  Result := True;
{$IFEND}
end;

procedure TEnginePlatHost.RemovePlat(APlat: Pointer);
begin
  P_RemoveActivePlat(Pplat_t(APlat));
end;

end.
