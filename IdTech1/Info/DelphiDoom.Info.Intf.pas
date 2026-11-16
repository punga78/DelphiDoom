{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the contracts towards the tables of the   }
{  game                                                                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.Intf;

interface

uses
  DelphiDoom.Info.Types;

type
  /// <summary>The table of the things (mobjinfo[]): the engine gives it, the tables stay data</summary>
  IInfoMobjSource = interface
    ['{6E0B2D84-1A73-4C95-B8F6-0D49E7A3C512}']
    /// <summary>How many things there are (the ones of the game and the custom ones)</summary>
    function Count: Integer;
    /// <summary>How many of them are in the game as it was shipped: the others come from patches</summary>
    function BuiltInCount: Integer;
    function Get(const AIndex: Integer): TInfoMobj;
    /// <summary>The name of the thing: its characters up to the first zero</summary>
    function Name(const AIndex: Integer): string;
    function DoomedNum(const AIndex: Integer): Integer;
    function InheritsFrom(const AIndex: Integer): Integer;
  end;

  /// <summary>The table of the states (states[])</summary>
  IInfoStateSource = interface
    ['{B3F52A19-84D7-4E60-9C21-A5E8D07B3F46}']
    function Count: Integer;
    function Get(const AIndex: Integer): TInfoState;
    /// <summary>True if the state lists the thing as one of its owners</summary>
    function IsOwnedBy(const AState, AMobj: Integer): Boolean;
  end;

  /// <summary>The things found by their name</summary>
  IInfoThingNames = interface
    ['{C4F0A98D-27B1-4E63-B5D2-6A81E9073C5F}']
    /// <summary>The thing with the name (or the number written as the name); -1 if none</summary>
    function NumForName(const AName: string): Integer;
  end;

  /// <summary>The table of the codes of the sprite names (sprnames[])</summary>
  IInfoSpriteSource = interface
    ['{8A1D6F30-C752-4E94-B0A8-1F3E9D5C7B62}']
    function Count: Integer;
    function Code(const AIndex: Integer): Integer;
  end;

  /// <summary>The names of the states that the scripts use (statenames): one position for every state</summary>
  IInfoStateTokens = interface
    ['{D0A14C67-3B92-4F58-A6E3-7C85B1F9024D}']
    /// <summary>The state that is, or lists, the name; -1 if there is none</summary>
    function IndexOfToken(const AToken: string): Integer;
  end;

  /// <summary>The text of a parameter of a script with RANDOMPICK and RANDOM computed (SC_EvalString)</summary>
  IInfoStateText = interface
    ['{47C9E5B2-0D18-4A73-95F4-E26B8C3D1A07}']
    function Evaluate(const AText: string): string;
  end;

  /// <summary>The list of the names of a group that patches and scripts add to</summary>
  IInfoNameList = interface
    ['{91E3A7C5-2F64-4B08-AD19-5C70E4B8D236}']
    function Count: Integer;
    function Name(const AIndex: Integer): string;
    /// <summary>The position of the name, exactly as it was added; -1 if it is not there</summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>Adds a name and gives its position</summary>
    function Add(const AName: string): Integer;
  end;

  /// <summary>Where the names of the groups that are added while a patch is read become constants of the scripts</summary>
  IInfoConstSink = interface
    ['{2C58D1F3-A604-4E97-8B25-F0937E1C6A84}']
    procedure AddConst(const AName: string; const AValue: Integer);
  end;

  /// <summary>What changes from game to game in the choice of a thing placed at random</summary>
  IInfoRandomRules = interface
    ['{5B9C0E27-D381-4A6F-8C14-72E5A0B3F9D8}']
    /// <summary>
    ///   The health that ends each of the four first classes of monster (a monster with less
    ///   than the first value is of the first class...); the fifth class takes all the rest
    /// </summary>
    function Thresholds: TArray<Integer>;
    /// <summary>True if the thing is a monster that can be chosen</summary>
    function IsMonster(const AMobj: TInfoMobj): Boolean;
    /// <summary>True if the game has a thing with this editor number placed in its maps</summary>
    function IsValidThing(const ADoomedNum: Integer): Boolean;
    /// <summary>How many random numbers are thrown away before the one that chooses</summary>
    function DiscardCount: Integer;
  end;

  /// <summary>The random numbers of the things placed at random (N_Random)</summary>
  IInfoRandom = interface
    ['{F6A2B093-5E81-4D47-A1C8-3B74D09E52F1}']
    function Next: Integer;
  end;

implementation

end.
