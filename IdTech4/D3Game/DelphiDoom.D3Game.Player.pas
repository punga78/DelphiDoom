{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idPlayer (the state only)                  }
{                                                                              }
{  Reduced port of Doom 3 (id Software): game\Player.cpp. Only the state that   }
{  the rest of the game library asks of a player: the health and the damage,    }
{  the spectator flag, the angles of the view (idTrigger_Multi::CheckFacing),   }
{  an inventory of named items (idGameLocal::RequirementMet) and the think      }
{  that touches the triggers (idEntity::TouchTriggers). No movement, weapons,   }
{  view, HUD, armor or script object: those need the engine around the player.  }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Player;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Angles, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.Entity;

type
  /// <summary>
  ///   idPlayer, reduced to its state: it takes damage (<c>fl.takedamage</c>), can be a spectator (it then touches no
  ///   trigger), has the angles of its view and an inventory of items by name. Its think runs the physics and touches
  ///   the triggers it is in.
  /// </summary>
  TD3Player = class(TD3Entity)
  strict private
    FSpectating: Boolean;
    FViewAngles: TIdAngles;
    FInventory: TStringList;
  public
    constructor Create(const AWorld: ID3EntityWorld; const AEventCanceller: ID3EventCanceller = nil);
    destructor Destroy; override;
    /// <summary>idPlayer::Spawn (reduced): the player takes damage and thinks every frame</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    /// <summary>
    ///   idPlayer::Think (reduced): the physics, then <c>TouchTriggers</c> for a player that is alive and is not a
    ///   spectator
    /// </summary>
    procedure Think; override;
    function IsPlayer: Boolean; override;
    function FindInventoryItem(const AName: AnsiString): Boolean; override;
    procedure RemoveInventoryItem(const AName: AnsiString); override;
    /// <summary>The names of the items, each one preceded by a space, in the order of the inventory</summary>
    function ItemsText: string;
    /// <summary>
    ///   idPlayer::SpawnToPoint (reduced): the player is placed at the point and looks along the angles of the spot
    /// </summary>
    procedure SpawnToPoint(const AOrigin: TIdVec3; const AAngles: TIdAngles);
    /// <summary>Puts an item in the inventory (idPlayer::GiveItem, with no weapon, ammo or powerup rules)</summary>
    procedure GiveInventoryItem(const AName: AnsiString);
    property Spectating: Boolean read FSpectating write FSpectating;
    property ViewAngles: TIdAngles read FViewAngles write FViewAngles;
  end;

implementation

uses
  DelphiDoom.D3Game.Types;

constructor TD3Player.Create(const AWorld: ID3EntityWorld; const AEventCanceller: ID3EventCanceller);
begin
  inherited Create(AWorld, AEventCanceller);
  FInventory := TStringList.Create;
  FInventory.CaseSensitive := False;
  FInventory.Duplicates := dupIgnore;
  FInventory.Sorted := True;
end;

destructor TD3Player.Destroy;
begin
  FInventory.Free;
  inherited Destroy;
end;

class procedure TD3Player.SpawnClass(const AInstance: TD3Class);
begin
  TD3Player(AInstance).TakeDamage := True;
  TD3Player(AInstance).BecomeActive(D3_TH_THINK);
end;

procedure TD3Player.Think;
begin
  inherited Think;
  if (not FSpectating) and (Health > 0) then
    TouchTriggers;
end;

function TD3Player.IsPlayer: Boolean;
begin
  Result := True;
end;

function TD3Player.FindInventoryItem(const AName: AnsiString): Boolean;
begin
  Result := FInventory.IndexOf(string(AName)) >= 0;
end;

procedure TD3Player.RemoveInventoryItem(const AName: AnsiString);
var
  LIndex: Integer;
begin
  LIndex := FInventory.IndexOf(string(AName));
  if LIndex >= 0 then
    FInventory.Delete(LIndex);
end;

function TD3Player.ItemsText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FInventory.Count - 1 do
    Result := Result + ' ' + FInventory[LIndex];
end;

procedure TD3Player.SpawnToPoint(const AOrigin: TIdVec3; const AAngles: TIdAngles);
begin
  SetOrigin(AOrigin);
  FViewAngles := AAngles;
end;

procedure TD3Player.GiveInventoryItem(const AName: AnsiString);
begin
  FInventory.Add(string(AName));
end;

end.
