{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the old list of p_tick          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldList;

// The list of the thinkers as it was in Base\p_tick.pas before TThinkerList (commit c57fbf77),
// copied as it was. Only what the engine gave is replaced: mobj_t has the two fields that the
// frozen turn reads, mobjlist is an object that tells the test what it was asked, Z_Free and
// P_MobjThinker call a procedure of the test.

interface

type
  actionf_v = procedure;
  actionf_p1 = procedure(p1: pointer);
  actionf_p2 = procedure(p1, p2: pointer);

  actionf_t = record
    case integer of
      0: (acp1: actionf_p1);
      1: (acv: actionf_v);
      2: (acp2: actionf_p2);
    end;

  think_t = actionf_t;

  Pthinker_t = ^thinker_t;
  thinker_t = record
    prev: Pthinker_t;
    next: Pthinker_t;
    _function: think_t;
  end;

  Pmobj_t = ^mobj_t;
  mobj_t = record
    thinker: thinker_t;
    player: pointer;
    flags3_ex: integer;
  end;

  TOldMobjProc = procedure(m: Pmobj_t);
  TOldProc = procedure;
  TOldPointerProc = procedure(ptr: pointer);

  TOldMobjList = class(TObject)
  public
    OnClear: TOldProc;
    OnAdd: TOldMobjProc;
    OnRemove: TOldMobjProc;
    procedure Clear;
    procedure Add(const m: Pmobj_t);
    procedure Remove(const m: Pmobj_t);
  end;

const
  MF3_EX_NOTIMEFREEZE = $1000;

var
// Both the head and tail of the thinker list.
  thinkercap: thinker_t;
  isgamefreezed: boolean = false;

  mobjlist: TOldMobjList;
  // what the test does in place of Z_Free and of the thinker of a map object
  OldZFree: TOldPointerProc;
  OldMobjThink: TOldMobjProc;

procedure P_MobjThinker(mobj: Pmobj_t);

procedure P_InitThinkers;

procedure P_AddThinker(thinker: Pthinker_t);

procedure P_RemoveThinker(thinker: Pthinker_t);

function P_ThinkerIsRemoved(thinker: Pthinker_t): boolean;

procedure P_RunThinkers;

implementation

{ TOldMobjList }

procedure TOldMobjList.Clear;
begin
  OnClear;
end;

procedure TOldMobjList.Add(const m: Pmobj_t);
begin
  OnAdd(m);
end;

procedure TOldMobjList.Remove(const m: Pmobj_t);
begin
  OnRemove(m);
end;

procedure Z_Free(ptr: pointer);
begin
  OldZFree(ptr);
end;

procedure P_MobjThinker(mobj: Pmobj_t);
begin
  OldMobjThink(mobj);
end;

//==============================================================================
//
// P_InitThinkers
//
//==============================================================================
procedure P_InitThinkers;
begin
  mobjlist.Clear;
  thinkercap.prev := @thinkercap;
  thinkercap.next := @thinkercap;
end;

//==============================================================================
//
// P_AddThinker
// Adds a new thinker at the end of the list.
//
//==============================================================================
procedure P_AddThinker(thinker: Pthinker_t);
begin
  if @thinker._function.acp1 = @P_MobjThinker then
    mobjlist.Add(Pmobj_t(thinker));

  thinkercap.prev.next := thinker;
  thinker.next := @thinkercap;
  thinker.prev := thinkercap.prev;
  thinkercap.prev := thinker;
end;

//==============================================================================
//
// P_RemoveThinker
// Deallocation is lazy -- it will not actually be freed
// until its thinking turn comes up.
//
//==============================================================================
procedure _removethinker;
begin
// JVAL 20191203 - Fixed non working plats & ceilings thanks to slayermbm
//                 https://www.doomworld.com/forum/topic/98789-fpcdoom-1124117-updated-dec-2-2019/?do=findComment&comment=2050845
end;

//==============================================================================
//
// P_RemoveThinker
//
//==============================================================================
procedure P_RemoveThinker(thinker: Pthinker_t);
begin
  if @thinker._function.acp1 = @P_MobjThinker then
    mobjlist.Remove(Pmobj_t(thinker));
  // FIXME: NOP.
  @thinker._function.acv := @_removethinker;
end;

//==============================================================================
//
// P_ThinkerIsRemoved
//
//==============================================================================
function P_ThinkerIsRemoved(thinker: Pthinker_t): boolean;
begin
  Result := (@thinker._function.acv = @_removethinker) or not Assigned(thinker._function.acv);
end;

//==============================================================================
//
// P_RunThinkers
//
//==============================================================================
procedure P_RunThinkers;
var
  currentthinker: Pthinker_t;
  nextthinker: Pthinker_t;
begin
  currentthinker := thinkercap.next;
  if isgamefreezed then
  begin
    while currentthinker <> @thinkercap do
    begin
      if @currentthinker._function.acv = @_removethinker then
      begin
        // time to remove it
        currentthinker.next.prev := currentthinker.prev;
        currentthinker.prev.next := currentthinker.next;
        nextthinker := currentthinker.next;
        Z_Free(currentthinker);
        currentthinker := nextthinker;
      end
      else
      begin
        if Assigned(currentthinker._function.acp1) then
          if @currentthinker._function.acp1 = @P_MobjThinker then
            if (Pmobj_t(currentthinker).player <> nil) or (Pmobj_t(currentthinker).flags3_ex and MF3_EX_NOTIMEFREEZE <> 0) then
              currentthinker._function.acp1(currentthinker);
        currentthinker := currentthinker.next;
      end;
    end;
  end
  else
  begin
    while currentthinker <> @thinkercap do
    begin
      if @currentthinker._function.acv = @_removethinker then
      begin
        // time to remove it
        currentthinker.next.prev := currentthinker.prev;
        currentthinker.prev.next := currentthinker.next;
        nextthinker := currentthinker.next;
        Z_Free(currentthinker);
        currentthinker := nextthinker;
      end
      else
      begin
        if Assigned(currentthinker._function.acp1) then
          currentthinker._function.acp1(currentthinker);
        currentthinker := currentthinker.next;
      end;
    end;
  end;
end;

initialization
  mobjlist := TOldMobjList.Create;

finalization
  mobjlist.Free;

end.
