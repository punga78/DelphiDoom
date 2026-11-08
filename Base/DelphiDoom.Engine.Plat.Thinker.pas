{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the platform thinker as the library sees it            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plat.Thinker;

interface

uses
  p_spec,
  DelphiDoom.Thinkers.Platform.Types;

//==============================================================================
//
// UdmfPlatKindOf
//
// The kind of a scripted platform (the PLAT_* of plattype_e, in every game)
//
//==============================================================================
function UdmfPlatKindOf(AType: plattype_e): TUdmfPlatKind;

//==============================================================================
//
// UdmfPlatLoadState
//
// Copies the fields of the thinker of a scripted platform, which stays a record in the
// zone memory, into the state that the library works on
//
//==============================================================================
procedure UdmfPlatLoadState(APlat: Pplat_t; out AState: TPlatState);

//==============================================================================
//
// UdmfPlatStoreState
//
// Writes the state back into the thinker (a status that the scripted platforms
// do not have is left as it was)
//
//==============================================================================
procedure UdmfPlatStoreState(APlat: Pplat_t; const AState: TPlatState);

{$IFNDEF HEXEN}

//==============================================================================
//
// PlatKindOf
//
// The kind of a classic platform (the plattype_e of the game)
//
//==============================================================================
function PlatKindOf(AType: plattype_e): TPlatKind;

//==============================================================================
//
// PlatStatusOf
//
//==============================================================================
function PlatStatusOf(AStatus: plat_e): TPlatStatus;

//==============================================================================
//
// PlatEngineStatusOf
//
//==============================================================================
function PlatEngineStatusOf(AStatus: TPlatStatus): plat_e;

//==============================================================================
//
// PlatLoadState
//
// As UdmfPlatLoadState, for a classic platform
//
//==============================================================================
procedure PlatLoadState(APlat: Pplat_t; out AState: TPlatState);

//==============================================================================
//
// PlatStoreState
//
//==============================================================================
procedure PlatStoreState(APlat: Pplat_t; const AState: TPlatState);

{$ENDIF}

implementation

//==============================================================================
//
// UdmfPlatKindOf
//
//==============================================================================
function UdmfPlatKindOf(AType: plattype_e): TUdmfPlatKind;
begin
  case AType of
    PLAT_PERPETUALRAISE:
      result := TUdmfPlatKind.PerpetualRaise;
    PLAT_DOWNWAITUPSTAY:
      result := TUdmfPlatKind.DownWaitUpStay;
    PLAT_DOWNBYVALUEWAITUPSTAY:
      result := TUdmfPlatKind.DownByValueWaitUpStay;
    PLAT_UPWAITDOWNSTAY:
      result := TUdmfPlatKind.UpWaitDownStay;
    PLAT_UPBYVALUEWAITDOWNSTAY:
      result := TUdmfPlatKind.UpByValueWaitDownStay;
    PLAT_PERPETUALRAISELIP:
      result := TUdmfPlatKind.PerpetualRaiseLip;
    PLAT_DOWNWAITUPSTAYLIP:
      result := TUdmfPlatKind.DownWaitUpStayLip;
    PLAT_UPNEARESTWAITDOWNSTAY:
      result := TUdmfPlatKind.UpNearestWaitDownStay;
  else
    // not a scripted platform: it never reaches the scripted thinker, and this kind does nothing special
    result := TUdmfPlatKind.PerpetualRaise;
  end;
end;

//==============================================================================
//
// UdmfStatusOf
//
//==============================================================================
function UdmfStatusOf(AStatus: plat_e): TPlatStatus;
begin
  case AStatus of
    PLAT_UP:
      result := TPlatStatus.Up;
    PLAT_DOWN:
      result := TPlatStatus.Down;
    PLAT_WAITING:
      result := TPlatStatus.Waiting;
  else
    // no branch of the tic: the platform does nothing, as before
    result := TPlatStatus.InStasis;
  end;
end;

//==============================================================================
//
// UdmfEngineStatusOf
//
//==============================================================================
function UdmfEngineStatusOf(AStatus: TPlatStatus): plat_e;
begin
  case AStatus of
    TPlatStatus.Up:
      result := PLAT_UP;
    TPlatStatus.Down:
      result := PLAT_DOWN;
  else
    result := PLAT_WAITING;
  end;
end;

//==============================================================================
//
// UdmfPlatLoadState
//
//==============================================================================
procedure UdmfPlatLoadState(APlat: Pplat_t; out AState: TPlatState);
begin
  AState.Speed := APlat.speed;
  AState.Low := APlat.low;
  AState.High := APlat.high;
  AState.Wait := APlat.wait;
  AState.Count := APlat.count;
  AState.Status := UdmfStatusOf(APlat.status);
  AState.OldStatus := UdmfStatusOf(APlat.oldstatus);
  AState.Crush := APlat.crush;
  AState.Tag := APlat.tag;
end;

//==============================================================================
//
// UdmfPlatStoreState
//
//==============================================================================
procedure UdmfPlatStoreState(APlat: Pplat_t; const AState: TPlatState);
begin
  APlat.speed := AState.Speed;
  APlat.low := AState.Low;
  APlat.high := AState.High;
  APlat.wait := AState.Wait;
  APlat.count := AState.Count;
  if AState.Status <> TPlatStatus.InStasis then
    APlat.status := UdmfEngineStatusOf(AState.Status);
  APlat.crush := AState.Crush;
  APlat.tag := AState.Tag;
end;

{$IFNDEF HEXEN}

//==============================================================================
//
// PlatKindOf
//
//==============================================================================
function PlatKindOf(AType: plattype_e): TPlatKind;
begin
  case AType of
    perpetualRaise:
      result := TPlatKind.PerpetualRaise;
    downWaitUpStay:
      result := TPlatKind.DownWaitUpStay;
    raiseAndChange:
      result := TPlatKind.RaiseAndChange;
    raiseToNearestAndChange:
      result := TPlatKind.RaiseToNearestAndChange;
    blazeDWUS:
      result := TPlatKind.BlazeDownWaitUpStay;
{$IFNDEF HERETIC}
    genLift:
      result := TPlatKind.GenericLift;
    genPerpetual:
      result := TPlatKind.GenericPerpetual;
    toggleUpDn:
      result := TPlatKind.ToggleUpDown;
{$ENDIF}
{$IFDEF STRIFE}
    slowDWUS:
      result := TPlatKind.SlowDownWaitUpStay;
    upWaitDownStay:
      result := TPlatKind.UpWaitDownStay;
{$ENDIF}
  else
    // a scripted platform never reaches the classic thinker, and this kind does nothing special
    result := TPlatKind.GenericPerpetual;
  end;
end;

//==============================================================================
//
// PlatStatusOf
//
//==============================================================================
function PlatStatusOf(AStatus: plat_e): TPlatStatus;
begin
  case AStatus of
    up:
      result := TPlatStatus.Up;
    down:
      result := TPlatStatus.Down;
    waiting:
      result := TPlatStatus.Waiting;
  else
    result := TPlatStatus.InStasis;
  end;
end;

//==============================================================================
//
// PlatEngineStatusOf
//
//==============================================================================
function PlatEngineStatusOf(AStatus: TPlatStatus): plat_e;
begin
  case AStatus of
    TPlatStatus.Up:
      result := up;
    TPlatStatus.Down:
      result := down;
    TPlatStatus.Waiting:
      result := waiting;
  else
    result := in_stasis;
  end;
end;

//==============================================================================
//
// PlatLoadState
//
//==============================================================================
procedure PlatLoadState(APlat: Pplat_t; out AState: TPlatState);
begin
  AState.Speed := APlat.speed;
  AState.Low := APlat.low;
  AState.High := APlat.high;
  AState.Wait := APlat.wait;
  AState.Count := APlat.count;
  AState.Status := PlatStatusOf(APlat.status);
  AState.OldStatus := PlatStatusOf(APlat.oldstatus);
  AState.Crush := APlat.crush;
  AState.Tag := APlat.tag;
end;

//==============================================================================
//
// PlatStoreState
//
//==============================================================================
procedure PlatStoreState(APlat: Pplat_t; const AState: TPlatState);
begin
  APlat.speed := AState.Speed;
  APlat.low := AState.Low;
  APlat.high := AState.High;
  APlat.wait := AState.Wait;
  APlat.count := AState.Count;
  APlat.status := PlatEngineStatusOf(AState.Status);
  APlat.oldstatus := PlatEngineStatusOf(AState.OldStatus);
  APlat.crush := AState.Crush;
  APlat.tag := AState.Tag;
end;

{$ENDIF}

end.
