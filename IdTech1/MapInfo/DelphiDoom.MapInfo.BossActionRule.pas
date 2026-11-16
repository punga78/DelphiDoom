{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - which bossaction lines a game takes         }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.BossActionRule;

interface

uses
  DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   The rule of a game. Doom and Heretic take a line with a tag, or one whose special is a
  ///   level exit; Strife takes every line
  /// </summary>
  TMapInfoBossActionRule = class(TInterfacedObject, IMapBossActionRule)
  private
    FRequiresTag: Boolean;
    FExitSpecials: TArray<Integer>;
  public
    /// <param name="ARequiresTag">False: every line is taken</param>
    /// <param name="AExitSpecials">The specials that end the level, taken without a tag</param>
    constructor Create(ARequiresTag: Boolean; const AExitSpecials: TArray<Integer>);
    function IsAccepted(ASpecial, ATag: Integer): Boolean;
  end;

implementation

{ TMapInfoBossActionRule }

constructor TMapInfoBossActionRule.Create(ARequiresTag: Boolean; const AExitSpecials: TArray<Integer>);
begin
  inherited Create;
  FRequiresTag := ARequiresTag;
  FExitSpecials := Copy(AExitSpecials);
end;

function TMapInfoBossActionRule.IsAccepted(ASpecial, ATag: Integer): Boolean;
var
  LSpecial: Integer;
begin
  if not FRequiresTag or (ATag <> 0) then
    Exit(True);
  for LSpecial in FExitSpecials do
    if LSpecial = ASpecial then
      Exit(True);
  Result := False;
end;

end.
