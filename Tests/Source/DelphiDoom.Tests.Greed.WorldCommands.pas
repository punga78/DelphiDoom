{******************************************************************************}
{                                                                              }
{  DelphiDoom: the commands of a game of Greed made from a seed                 }
{                                                                              }
{  The same unit is compiled in the harness of the original (Tools\Verifica\    }
{  175-world) and in the tests of the library: the two games get the same       }
{  keys at the same readings                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WorldCommands;

// the generator of the numbers wraps on purpose
{$Q-}
{$R-}

interface

type
  /// <summary>The keys that a generated game presses (the default keys of the original are in the comments)</summary>
  TWorldKey = (
    wkNorth,          // up arrow
    wkSouth,          // down arrow
    wkEast,           // right arrow: turns right
    wkWest,           // left arrow: turns left
    wkFire,           // Ctrl
    wkSpace,          // Space: use, and start again when dead
    wkShift,          // left Shift: run
    wkSlideLeft,      // comma
    wkSlideRight,     // period
    wkJump,           // Z
    wkUseItem,        // X
    wkInventoryLeft,  // Insert
    wkInventoryRight, // Delete
    wkLookUp,         // Page Up
    wkLookDown,       // Page Down
    wkCenterView,     // Home
    wkWeapon1,        // 1
    wkWeapon2);       // 2
  TWorldKeys = set of TWorldKey;

  /// <summary>
  ///   A player that walks mostly forward, turns, shoots in bursts, uses what is in front of it, and now and then
  ///   runs, steps aside, jumps, looks, changes weapon and uses the inventory. Each key is held for a while and
  ///   then left for a while, with lengths taken from a linear congruential generator: the sequence depends only
  ///   on the seed
  /// </summary>
  TWorldCommands = class
  strict private
    FState: Cardinal;
    FDown: TWorldKeys;
    FLeft: array[TWorldKey] of Integer;
    function Roll(ALow, AHigh: Integer): Integer;
  public
    constructor Create(ASeed: Cardinal);
    /// <summary>The keys that are down at the next reading of the controls</summary>
    function Next: TWorldKeys;
  end;

implementation

type
  TKeyHabit = record
    HoldLow, HoldHigh, RestLow, RestHigh: Integer;
  end;

const
  HABITS: array[TWorldKey] of TKeyHabit = (
    (HoldLow: 20; HoldHigh: 120; RestLow: 2; RestHigh: 30),     // north
    (HoldLow: 5; HoldHigh: 25; RestLow: 60; RestHigh: 300),     // south
    (HoldLow: 3; HoldHigh: 25; RestLow: 5; RestHigh: 80),       // east
    (HoldLow: 3; HoldHigh: 25; RestLow: 5; RestHigh: 80),       // west
    (HoldLow: 5; HoldHigh: 40; RestLow: 10; RestHigh: 100),     // fire
    (HoldLow: 2; HoldHigh: 4; RestLow: 15; RestHigh: 60),       // space
    (HoldLow: 20; HoldHigh: 100; RestLow: 50; RestHigh: 200),   // shift
    (HoldLow: 5; HoldHigh: 30; RestLow: 80; RestHigh: 300),     // slide left
    (HoldLow: 5; HoldHigh: 30; RestLow: 80; RestHigh: 300),     // slide right
    (HoldLow: 2; HoldHigh: 3; RestLow: 100; RestHigh: 400),     // jump
    (HoldLow: 2; HoldHigh: 3; RestLow: 200; RestHigh: 600),     // use item
    (HoldLow: 2; HoldHigh: 3; RestLow: 150; RestHigh: 500),     // inventory left
    (HoldLow: 2; HoldHigh: 3; RestLow: 150; RestHigh: 500),     // inventory right
    (HoldLow: 3; HoldHigh: 15; RestLow: 200; RestHigh: 500),    // look up
    (HoldLow: 3; HoldHigh: 15; RestLow: 200; RestHigh: 500),    // look down
    (HoldLow: 2; HoldHigh: 3; RestLow: 300; RestHigh: 600),     // center view
    (HoldLow: 2; HoldHigh: 3; RestLow: 200; RestHigh: 600),     // weapon 1
    (HoldLow: 2; HoldHigh: 3; RestLow: 200; RestHigh: 600));    // weapon 2

{ TWorldCommands }

constructor TWorldCommands.Create(ASeed: Cardinal);
var
  LKey: TWorldKey;
begin
  inherited Create;
  FState := ASeed * 2654435761 + 12345;
  // every key starts in its rest, at a different point of it
  for LKey := Low(TWorldKey) to High(TWorldKey) do
    FLeft[LKey] := Roll(1, HABITS[LKey].RestHigh);
  // the game starts walking
  FLeft[wkNorth] := 1;
end;

function TWorldCommands.Roll(ALow, AHigh: Integer): Integer;
begin
  FState := FState * 1664525 + 1013904223;
  Result := ALow + Integer((FState shr 8) mod Cardinal(AHigh - ALow + 1));
end;

function TWorldCommands.Next: TWorldKeys;
var
  LKey: TWorldKey;
begin
  for LKey := Low(TWorldKey) to High(TWorldKey) do
  begin
    Dec(FLeft[LKey]);
    if FLeft[LKey] > 0 then
      Continue;
    if LKey in FDown then
    begin
      Exclude(FDown, LKey);
      FLeft[LKey] := Roll(HABITS[LKey].RestLow, HABITS[LKey].RestHigh);
    end
    else
    begin
      Include(FDown, LKey);
      FLeft[LKey] := Roll(HABITS[LKey].HoldLow, HABITS[LKey].HoldHigh);
    end;
  end;
  Result := FDown;
end;

end.
