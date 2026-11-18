{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lists of names of the tables of DEHACKED           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Dehacked.TokenLists;

interface

uses
  d_delphi;

type
  /// <summary>
  ///   Fills the lists of names of deh_main (mobj_tokens, state_tokens, the flags...) from the names of the
  ///   library of the game (TDehackedGameData): the library is the one source of the names, the order of the
  ///   names is the index of a field. Issue #185, wave 11b: DEH_Init of the four games added them one by one
  /// </summary>
  TEngineDehackedTokenLists = class sealed
  public
    /// <summary>Adds the names, in order, at the end of the list</summary>
    /// <remarks>Raises EArgumentNilException if AList is nil</remarks>
    class procedure Fill(const AList: TDTextList; const AItems: TArray<string>); static;
  end;

implementation

uses
  System.SysUtils;

const
  SListMissing = 'TEngineDehackedTokenLists.Fill: the list is nil';

{ TEngineDehackedTokenLists }

class procedure TEngineDehackedTokenLists.Fill(const AList: TDTextList; const AItems: TArray<string>);
var
  LIndex: Integer;
begin
  if not Assigned(AList) then
    raise EArgumentNilException.Create(SListMissing);
  for LIndex := 0 to Length(AItems) - 1 do
    AList.Add(AItems[LIndex]);
end;

end.
