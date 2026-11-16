{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the areas a bot may weapon jump to                }
{                                                                              }
{  Port of AAS_SetWeaponJumpAreaFlags of be_aas_reach.c: the areas of the      }
{  powerful items and the jump pad areas get the flag AREA_WEAPONJUMP. Based   }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.WeaponFlags;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Context, DelphiDoom.Aas.Reach.Part, DelphiDoom.Aas.Reach.BestReachable;

type
  /// <summary>Sets the area flags for weapon jumping</summary>
  TAasReachWeaponFlags = class(TAasReachPart)
  strict private
    FBest: TAasReachBest;
  public
    /// <summary>The best reachable area part is not owned</summary>
    constructor Create(const AContext: TAasReachContext; const ABest: TAasReachBest); reintroduce;
    /// <summary>AAS_SetWeaponJumpAreaFlags</summary>
    procedure Calculate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Printer,
  DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Format;

const
  ITEMS: array[0..11] of AnsiString = ('item_armor_body', 'item_armor_combat', 'item_health_mega',
    'weapon_grenadelauncher', 'weapon_rocketlauncher', 'weapon_lightning', 'weapon_plasmagun', 'weapon_railgun',
    'weapon_bfg', 'item_quad', 'item_regen', 'item_invulnerability');

{ TAasReachWeaponFlags }

constructor TAasReachWeaponFlags.Create(const AContext: TAasReachContext; const ABest: TAasReachBest);
begin
  inherited Create(AContext);
  FBest := ABest;
end;

procedure TAasReachWeaponFlags.Calculate;
var
  LEnt, LAreaNum, LWeaponJumpAreas, LSpawnFlags, LIndex: Integer;
  LMins, LMaxs, LOrigin: TVec3;
  LClassName: AnsiString;
  LIsItem: Boolean;
begin
  LMins[0] := -15; LMins[1] := -15; LMins[2] := -15;
  LMaxs[0] := 15; LMaxs[1] := 15; LMaxs[2] := 15;
  LWeaponJumpAreas := 0;
  LEnt := Context.Entities.NextEntity(0);
  while LEnt <> 0 do
  begin
    if Context.Entities.ValueForKey(LEnt, 'classname', LClassName) then
    begin
      LIsItem := False;
      for LIndex := Low(ITEMS) to High(ITEMS) do
        if LClassName = ITEMS[LIndex] then
          LIsItem := True;
      if LIsItem and Context.Entities.VectorForKey(LEnt, 'origin', LOrigin) then
      begin
        LSpawnFlags := 0;
        Context.Entities.IntForKey(LEnt, 'spawnflags', LSpawnFlags);
        // if not a stationary item
        if (LSpawnFlags and 1) = 0 then
          if not Context.Movement.DropToFloor(LOrigin, LMins, LMaxs) then
            TAasPrinter.Print(Context.Import, PRT_MESSAGE, string(LClassName) + ' in solid at (' +
              TAasReachFormat.Fixed(LOrigin[0], 1) + ' ' + TAasReachFormat.Fixed(LOrigin[1], 1) + ' ' +
              TAasReachFormat.Fixed(LOrigin[2], 1) + ')'#10);
        LAreaNum := FBest.BestReachableAreaInPlace(LOrigin, LMins, LMaxs);
        // the bot may rocket jump towards this area
        Context.AreaSettings[LAreaNum].AreaFlags := Context.AreaSettings[LAreaNum].AreaFlags or AREA_WEAPONJUMP;
        Inc(LWeaponJumpAreas);
      end;
    end;
    LEnt := Context.Entities.NextEntity(LEnt);
  end;
  for LIndex := 1 to Context.NumAreas - 1 do
    if (Context.AreaSettings[LIndex].Contents and AREACONTENTS_JUMPPAD) <> 0 then
    begin
      Context.AreaSettings[LIndex].AreaFlags := Context.AreaSettings[LIndex].AreaFlags or AREA_WEAPONJUMP;
      Inc(LWeaponJumpAreas);
    end;
  TAasPrinter.Print(Context.Import, PRT_MESSAGE, IntToStr(LWeaponJumpAreas) + ' weapon jump areas'#10);
end;

end.
