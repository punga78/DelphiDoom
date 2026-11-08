{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the scripted platforms ask to the game            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plat.UdmfHost;

interface

uses
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>
  ///   The game side of the platforms of the scripted specials (udmf_plats): the plane move of the
  ///   scripted floors and the sound of the sector, which is a sequence in Hexen and the sound of
  ///   the sector type in the other games. It is separate from udmf_plats for the reason given in
  ///   DelphiDoom.Engine.Plat.Host
  /// </summary>
  TEngineUdmfPlatHost = class(TInterfacedObject, IPlatHost)
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
  p_mobj_h,
  udmf_floor,
  udmf_plats,
{$IFDEF HEXEN}
  s_sndseq;
{$ELSE}
  s_sound;
{$ENDIF}

{ TEngineUdmfPlatHost }

function TEngineUdmfPlatHost.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer;
  ACrush: Boolean; ADirection: Integer): TPlatMoveResult;
begin
  case TH_MovePlane(Psector_t(ASector), ASpeed, ADestination, ACrush, 0, ADirection) of
    RES_CRUSHED:
      Result := TPlatMoveResult.Crushed;
    RES_PASTDEST:
      Result := TPlatMoveResult.PastDestination;
  else
    Result := TPlatMoveResult.Ok;
  end;
end;

function TEngineUdmfPlatHost.GetFloorHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).floorheight;
end;

procedure TEngineUdmfPlatHost.PlaySound(ASector: Pointer; ASound: TPlatSound);
begin
  case ASound of
    TPlatSound.Start:
{$IFDEF HEXEN}
      S_StartSequence(Pmobj_t(@Psector_t(ASector).soundorg),
        Ord(SEQ_PLATFORM) + Ord(Psector_t(ASector).seqType));
{$ELSE}
      S_StartSound(@Psector_t(ASector).soundorg, Psector_t(ASector).seqType);
{$ENDIF}
    TPlatSound.Stop:
{$IFDEF HEXEN}
      S_StopSequence(Pmobj_t(@Psector_t(ASector).soundorg));
{$ELSE}
      S_StopSound(@Psector_t(ASector).soundorg);
{$ENDIF}
  end;
  // the stone sound of a plane that moves in steps is not used by the scripted platforms
end;

function TEngineUdmfPlatHost.GetLevelTime: Integer;
begin
  Result := leveltime;
end;

function TEngineUdmfPlatHost.IsModernEngine: Boolean;
begin
  // the scripted platforms do not depend on the engine version
  Result := True;
end;

procedure TEngineUdmfPlatHost.RemovePlat(APlat: Pointer);
begin
  PH_RemoveActivePlat(Pplat_t(APlat));
end;

end.
