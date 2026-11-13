//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Info.Intf;

interface

uses
  p_mobj_h;

type
  /// <summary>The states that the actions of a script name (P_GetStateFromName and P_GetStateFromNameWithOffsetCheck)</summary>
  IEngineStateNames = interface
    ['{0F6D83B5-A2C1-4E79-B864-D5C19A30E7F2}']
    /// <summary>The state of the name for the actor; -1 if there is none</summary>
    function StateFromName(const AActor: Pmobj_t; const AText: string): Integer;
    /// <summary>As StateFromName, with a number alone read as an offset from the state of the actor</summary>
    function StateFromNameWithOffset(const AActor: Pmobj_t; const AText: string): Integer;
  end;

  /// <summary>The searches on the table of the things that info_common offers (the engine gives them with Info_ConfigureThings)</summary>
  IEngineInfoThings = interface
    ['{A7E4C913-6B20-4D58-9F31-C8D2B05E7A64}']
    /// <summary>Makes the table of editor numbers and the list of aliases (Info_InitDnLookUp)</summary>
    procedure Initialize;
    /// <summary>Forgets them (Info_ShutDownDnLookUp)</summary>
    procedure ShutDown;
    function ThingForDoomedNumber(const ADoomedNum: Integer): Integer;
    function ThingForName(const AName: string): Integer;
    /// <summary>Adds a name that stands for the same thing as another one; False if neither is known</summary>
    function AddAlias(const AAlias1, AAlias2: string): Boolean;
    /// <summary>The first ancestor of the thing at AIndex (itself if it has none)</summary>
    function RootOf(const AIndex: Integer): Integer;
  end;

  /// <summary>The searches on the table of the states</summary>
  IEngineInfoStates = interface
    ['{3D95B0E8-71C4-4A2F-8E67-F1A90C4D6B25}']
    /// <summary>The states of a thing: the chains that start at its states and the ones that list it as an owner</summary>
    function StatesOfThing(const AMobj: Integer): TArray<Integer>;
    /// <summary>The states from which a chain of states without a duration never ends</summary>
    function StatesWithEndlessChain: TArray<Integer>;
    /// <summary>The states that show a sprite (four characters) or one of its frames (five)</summary>
    function StatesFromSprite(const ASprite: string): TArray<Integer>;
  end;

  /// <summary>The names of the MBF21 groups</summary>
  IEngineInfoGroups = interface
    ['{E1B87D40-3C95-4F26-A0D9-5B72F8C3E014}']
    function InfightingToText(const AValue: Integer): string;
    function InfightingToValue(const AText: string): Integer;
    function ProjectileToText(const AValue: Integer): string;
    function ProjectileToValue(const AText: string): Integer;
    function SplashToText(const AValue: Integer): string;
    function SplashToValue(const AText: string): Integer;
  end;

  /// <summary>The things placed at random</summary>
  IEngineInfoRandom = interface
    ['{59C2F6A1-8D03-4B74-91E8-A3047DB5C6F2}']
    procedure Initialize;
    procedure ShutDown;
    function SelectMonster(const AType: Integer): Integer;
    function IsMonster(const AType: Integer): Boolean;
  end;

implementation

end.
