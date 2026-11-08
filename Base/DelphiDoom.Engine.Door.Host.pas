{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the vertical doors ask of the game                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Door.Host;

interface

uses
  DelphiDoom.Thinkers.Door.Types,
  DelphiDoom.Thinkers.Door.Intf;

type
  /// <summary>
  ///   The services of the doors for the real game: it moves the ceiling with T_MovePlane (classic
  ///   doors) or TH_MovePlane (scripted doors), plays the sounds of the game, finds the sectors
  ///   around a door and says if the compatibility mode is on. The sector is a Psector_t
  /// </summary>
  /// <remarks>
  ///   The same object gives four interfaces: keep it in a variable of one of them (never in a
  ///   variable of the class) while the others are taken with "as"
  /// </remarks>
  TEngineDoorHost = class(TInterfacedObject, IDoorPlaneMover, IDoorSounds, IDoorSectorQueries,
    IDoorOptions)
  strict private
    FFlavor: TDoorFlavor;
  public
    constructor Create(AFlavor: TDoorFlavor);
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
    procedure Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    procedure Stop(ASector: Pointer);
    function LowestCeilingSurrounding(ASector: Pointer): Integer;
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function GetCompatibilityMode: Boolean;
  end;

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  p_mobj_h,
  p_spec,
  r_defs,
  udmf_floor,
{$IFDEF HEXEN}
  s_sndseq;
{$ELSE}
  s_sound,
  sounddata,
  g_game,
  p_floor;
{$ENDIF}

{ TEngineDoorHost }

constructor TEngineDoorHost.Create(AFlavor: TDoorFlavor);
begin
  inherited Create;
  FFlavor := AFlavor;
end;

function TEngineDoorHost.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer;
  ACrush: Boolean; AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
var
  LResult: result_e;
begin
  Result := TDoorPlaneResult.Ok;
{$IFNDEF HEXEN}
  if FFlavor = TDoorFlavor.Classic then
  begin
    LResult := T_MovePlane(Psector_t(ASector), ASpeed, ADestination, ACrush, AFloorOrCeiling,
      ADirection);
    if LResult = crushed then
      Result := TDoorPlaneResult.Crushed
    else if LResult = pastdest then
      Result := TDoorPlaneResult.PastDest;
  end
  else
{$ENDIF}
  begin
    LResult := TH_MovePlane(Psector_t(ASector), ASpeed, ADestination, ACrush, AFloorOrCeiling,
      ADirection);
    if LResult = RES_CRUSHED then
      Result := TDoorPlaneResult.Crushed
    else if LResult = RES_PASTDEST then
      Result := TDoorPlaneResult.PastDest;
  end;
end;

procedure TEngineDoorHost.Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
var
  LSector: Psector_t;
begin
  LSector := Psector_t(ASector);
{$IFDEF HEXEN}
  // the scripted doors of Hexen start the sound sequence of the sector, open or close
  S_StartSequence(Pmobj_t(@LSector.soundorg), Ord(SEQ_DOOR_STONE) + Ord(LSector.seqType));
{$ELSE}
  if FFlavor = TDoorFlavor.Udmf then
    // the scripted doors of the other games play the sound number kept in the sector
    S_StartSound(@LSector.soundorg, LSector.seqType)
  else
    case ASound of
      TDoorSound.Open:
        {$IFDEF STRIFE}
        S_StartSound(@LSector.soundorg, AState.OpenSound);
        {$ELSE}
        S_StartSound(@LSector.soundorg, Ord(sfx_doropn));
        {$ENDIF}
      TDoorSound.Close:
        {$IFDEF STRIFE}
        S_StartSound(@LSector.soundorg, AState.CloseSound);
        {$ELSE}
        S_StartSound(@LSector.soundorg, Ord(sfx_dorcls));
        {$ENDIF}
      {$IFNDEF HERETIC}
      TDoorSound.BlazeOpen:
        S_StartSound(@LSector.soundorg, Ord(sfx_bdopn));
      TDoorSound.BlazeClose:
        S_StartSound(@LSector.soundorg, Ord(sfx_bdcls));
      {$ENDIF}
    end;
{$ENDIF}
end;

procedure TEngineDoorHost.Stop(ASector: Pointer);
var
  LSector: Psector_t;
begin
  LSector := Psector_t(ASector);
{$IFDEF HEXEN}
  S_StopSequence(Pmobj_t(@LSector.soundorg));
{$ELSE}
  S_StopSound(Pmobj_t(@LSector.soundorg));
{$ENDIF}
end;

function TEngineDoorHost.LowestCeilingSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindLowestCeilingSurrounding(Psector_t(ASector));
end;

function TEngineDoorHost.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindLowestFloorSurrounding(Psector_t(ASector));
end;

function TEngineDoorHost.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindHighestFloorSurrounding(Psector_t(ASector));
end;

function TEngineDoorHost.GetCompatibilityMode: Boolean;
begin
{$IFDEF HEXEN}
  Result := False;
{$ELSE}
  Result := compatibilitymode;
{$ENDIF}
end;

end.
