{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - what a game says about its patches           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.GameData;

interface

type
  /// <summary>
  ///   The names that the patches of a game use: the fields of each block and the flags. The
  ///   order is the one of the old tables (deh_main.pas of each game): the engine knows a field by
  ///   its position
  /// </summary>
  TDehackedGameData = record
    ThingFields: TArray<string>;
    FrameFields: TArray<string>;
    AmmoFields: TArray<string>;
    WeaponFields: TArray<string>;
    SoundFields: TArray<string>;
    MiscFields: TArray<string>;
    MobjFlags: TArray<string>;
    MobjFlags2: TArray<string>;
    MobjFlagsEx: TArray<string>;
    MobjFlags2Ex: TArray<string>;
    MobjFlags3Ex: TArray<string>;
    MobjFlags4Ex: TArray<string>;
    MobjFlags5Ex: TArray<string>;
    MobjFlags6Ex: TArray<string>;
    MobjFlagsMbf21: TArray<string>;
    StateFlagsEx: TArray<string>;
    StateFlagsMbf21: TArray<string>;
    WeaponFlagsMbf21: TArray<string>;
  end;

implementation

end.
