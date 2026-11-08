{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the kinds of door of the game and of the library       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Door.Kinds;

interface

uses
  p_spec,
  DelphiDoom.Thinkers.Door.Types;

//==============================================================================
//
// DoorKindToNeutral
//
// vldoor_e of the game -> the kind of the library
//
//==============================================================================
function DoorKindToNeutral(AKind: vldoor_e): TDoorKind;

//==============================================================================
//
// DoorKindFromNeutral
//
// The kind of the library -> vldoor_e of the game (a kind that the game does
// not have gives the normal door)
//
//==============================================================================
function DoorKindFromNeutral(AKind: TDoorKind): vldoor_e;

implementation

//==============================================================================
//
// DoorKindToNeutral
//
//==============================================================================
function DoorKindToNeutral(AKind: vldoor_e): TDoorKind;
begin
{$IFDEF HEXEN}
  result := TDoorKind.UdmfNormal;
{$ELSE}
  result := TDoorKind.Normal;
{$ENDIF}
  case AKind of
{$IFDEF STRIFE}
    vld_normal: result := TDoorKind.Normal;
    vld_close30ThenOpen: result := TDoorKind.Close30ThenOpen;
    vld_close: result := TDoorKind.Close;
    vld_open: result := TDoorKind.Open;
    vld_raiseIn5Mins: result := TDoorKind.RaiseIn5Mins;
    vld_blazeRaise: result := TDoorKind.BlazeRaise;
    vld_blazeOpen: result := TDoorKind.BlazeOpen;
    vld_blazeClose: result := TDoorKind.BlazeClose;
    vld_shopClose: result := TDoorKind.ShopClose;
    vld_splitRaiseNearest: result := TDoorKind.SplitRaiseNearest;
    vld_splitOpen: result := TDoorKind.SplitOpen;
    vld_genRaise: result := TDoorKind.GenRaise;
    vld_genBlazeRaise: result := TDoorKind.GenBlazeRaise;
    vld_genOpen: result := TDoorKind.GenOpen;
    vld_genBlazeOpen: result := TDoorKind.GenBlazeOpen;
    vld_genClose: result := TDoorKind.GenClose;
    vld_genBlazeClose: result := TDoorKind.GenBlazeClose;
    vld_genCdO: result := TDoorKind.GenCdO;
    vld_genBlazeCdO: result := TDoorKind.GenBlazeCdO;
{$ENDIF}
{$IFDEF DOOM}
    normal: result := TDoorKind.Normal;
    close30ThenOpen: result := TDoorKind.Close30ThenOpen;
    close: result := TDoorKind.Close;
    open: result := TDoorKind.Open;
    raiseIn5Mins: result := TDoorKind.RaiseIn5Mins;
    blazeRaise: result := TDoorKind.BlazeRaise;
    blazeOpen: result := TDoorKind.BlazeOpen;
    blazeClose: result := TDoorKind.BlazeClose;
    genRaise: result := TDoorKind.GenRaise;
    genBlazeRaise: result := TDoorKind.GenBlazeRaise;
    genOpen: result := TDoorKind.GenOpen;
    genBlazeOpen: result := TDoorKind.GenBlazeOpen;
    genClose: result := TDoorKind.GenClose;
    genBlazeClose: result := TDoorKind.GenBlazeClose;
    genCdO: result := TDoorKind.GenCdO;
    genBlazeCdO: result := TDoorKind.GenBlazeCdO;
{$ENDIF}
{$IFDEF HERETIC}
    normal: result := TDoorKind.Normal;
    close30ThenOpen: result := TDoorKind.Close30ThenOpen;
    close: result := TDoorKind.Close;
    open: result := TDoorKind.Open;
    raiseIn5Mins: result := TDoorKind.RaiseIn5Mins;
{$ENDIF}
    DREV_NORMAL: result := TDoorKind.UdmfNormal;
    DREV_CLOSE30THENOPEN: result := TDoorKind.UdmfClose30ThenOpen;
    DREV_CLOSE: result := TDoorKind.UdmfClose;
    DREV_OPEN: result := TDoorKind.UdmfOpen;
    DREV_RAISEIN5MINS: result := TDoorKind.UdmfRaiseIn5Mins;
    DREV_CLOSEWAITTHENOPEN: result := TDoorKind.UdmfCloseWaitThenOpen;
  end;
end;

//==============================================================================
//
// DoorKindFromNeutral
//
//==============================================================================
function DoorKindFromNeutral(AKind: TDoorKind): vldoor_e;
begin
{$IFDEF HEXEN}
  result := DREV_NORMAL;
{$ENDIF}
{$IFDEF STRIFE}
  result := vld_normal;
{$ENDIF}
{$IFDEF DOOM}
  result := normal;
{$ENDIF}
{$IFDEF HERETIC}
  result := normal;
{$ENDIF}
  case AKind of
{$IFDEF STRIFE}
    TDoorKind.Normal: result := vld_normal;
    TDoorKind.Close30ThenOpen: result := vld_close30ThenOpen;
    TDoorKind.Close: result := vld_close;
    TDoorKind.Open: result := vld_open;
    TDoorKind.RaiseIn5Mins: result := vld_raiseIn5Mins;
    TDoorKind.BlazeRaise: result := vld_blazeRaise;
    TDoorKind.BlazeOpen: result := vld_blazeOpen;
    TDoorKind.BlazeClose: result := vld_blazeClose;
    TDoorKind.ShopClose: result := vld_shopClose;
    TDoorKind.SplitRaiseNearest: result := vld_splitRaiseNearest;
    TDoorKind.SplitOpen: result := vld_splitOpen;
    TDoorKind.GenRaise: result := vld_genRaise;
    TDoorKind.GenBlazeRaise: result := vld_genBlazeRaise;
    TDoorKind.GenOpen: result := vld_genOpen;
    TDoorKind.GenBlazeOpen: result := vld_genBlazeOpen;
    TDoorKind.GenClose: result := vld_genClose;
    TDoorKind.GenBlazeClose: result := vld_genBlazeClose;
    TDoorKind.GenCdO: result := vld_genCdO;
    TDoorKind.GenBlazeCdO: result := vld_genBlazeCdO;
{$ENDIF}
{$IFDEF DOOM}
    TDoorKind.Normal: result := normal;
    TDoorKind.Close30ThenOpen: result := close30ThenOpen;
    TDoorKind.Close: result := close;
    TDoorKind.Open: result := open;
    TDoorKind.RaiseIn5Mins: result := raiseIn5Mins;
    TDoorKind.BlazeRaise: result := blazeRaise;
    TDoorKind.BlazeOpen: result := blazeOpen;
    TDoorKind.BlazeClose: result := blazeClose;
    TDoorKind.GenRaise: result := genRaise;
    TDoorKind.GenBlazeRaise: result := genBlazeRaise;
    TDoorKind.GenOpen: result := genOpen;
    TDoorKind.GenBlazeOpen: result := genBlazeOpen;
    TDoorKind.GenClose: result := genClose;
    TDoorKind.GenBlazeClose: result := genBlazeClose;
    TDoorKind.GenCdO: result := genCdO;
    TDoorKind.GenBlazeCdO: result := genBlazeCdO;
{$ENDIF}
{$IFDEF HERETIC}
    TDoorKind.Normal: result := normal;
    TDoorKind.Close30ThenOpen: result := close30ThenOpen;
    TDoorKind.Close: result := close;
    TDoorKind.Open: result := open;
    TDoorKind.RaiseIn5Mins: result := raiseIn5Mins;
{$ENDIF}
    TDoorKind.UdmfNormal: result := DREV_NORMAL;
    TDoorKind.UdmfClose30ThenOpen: result := DREV_CLOSE30THENOPEN;
    TDoorKind.UdmfClose: result := DREV_CLOSE;
    TDoorKind.UdmfOpen: result := DREV_OPEN;
    TDoorKind.UdmfRaiseIn5Mins: result := DREV_RAISEIN5MINS;
    TDoorKind.UdmfCloseWaitThenOpen: result := DREV_CLOSEWAITTHENOPEN;
  end;
end;

end.
