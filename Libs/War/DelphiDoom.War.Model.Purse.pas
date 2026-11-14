{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the gold and the lumber of a player                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_entities.c (we_enoughPlayerResources,      }
{  we_decreasePlayerResources, we_increasePlayerResources), (c) 2019           }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Purse;

interface

uses
  DelphiDoom.War.Model.Context;

type
  /// <summary>
  ///   Buying and refunding, as functions with no state: TWarEconomy gives them to the game, and the states of
  ///   training, upgrading, building and repairing (which only see the context) pay and refund with the same code
  /// </summary>
  TWarPurse = class
  public
    /// <summary>we_enoughPlayerResources</summary>
    class function Enough(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean; static;
    /// <summary>
    ///   we_decreasePlayerResources: all or nothing; the gold is checked first and the message of the status bar is the one of the
    ///   first that is missing
    /// </summary>
    class function Decrease(AContext: TWarModelContext; APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean; static;
    /// <summary>we_increasePlayerResources</summary>
    class procedure Increase(APlayer: PWarPlayerInfo; AGold, AWood: Integer); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types;

{ TWarPurse }

class function TWarPurse.Enough(APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
begin
  Result := (APlayer^.Gold >= AGold) and (APlayer^.Wood >= AWood);
end;

class function TWarPurse.Decrease(AContext: TWarModelContext; APlayer: PWarPlayerInfo; AGold, AWood: Integer): Boolean;
begin
  if APlayer^.Gold < AGold then
  begin
    AContext.Events.FlashStatus(wsmNotEnoughGold);
    Exit(False);
  end;
  if APlayer^.Wood < AWood then
  begin
    AContext.Events.FlashStatus(wsmNotEnoughLumber);
    Exit(False);
  end;
  APlayer^.Gold := APlayer^.Gold - AGold;
  APlayer^.Wood := APlayer^.Wood - AWood;
  Result := True;
end;

class procedure TWarPurse.Increase(APlayer: PWarPlayerInfo; AGold, AWood: Integer);
begin
  APlayer^.Gold := APlayer^.Gold + AGold;
  APlayer^.Wood := APlayer^.Wood + AWood;
end;

end.
