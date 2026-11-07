{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the shared types                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when a profile of a game is built with data that cannot work</summary>
  EIwadException = class(Exception);

  /// <summary>
  ///   The game mode that an IWAD tells (the gamemode of the engine). Unchanged means that the
  ///   IWAD says nothing and the engine keeps what it has; Indetermined means that the engine
  ///   decides later, from the lumps (for example registered or retail Doom)
  /// </summary>
  TIwadGameMode = (igmUnchanged, igmIndetermined, igmShareware, igmRegistered, igmRetail,
    igmCommercial);

  /// <summary>The mission that an IWAD tells (the gamemission of the engine)</summary>
  TIwadMission = (imsUnchanged, imsDoom, imsDoom2, imsPlutonia, imsTnt);

  /// <summary>An IWAD that a game knows by its file name</summary>
  TIwadEntry = record
    /// <summary>The name of the file, for example doom2.wad</summary>
    FileName: string;
    Mode: TIwadGameMode;
    Mission: TIwadMission;
    /// <summary>The French edition of Doom II: the engine switches its language</summary>
    IsFrench: Boolean;
    /// <summary>The BFG edition of Doom II</summary>
    IsBfg2: Boolean;
    /// <summary>
    ///   False when the file is looked for only where it is named (the current folder or the
    ///   folder of the WAD directory variable), never in the other search paths
    /// </summary>
    Searchable: Boolean;
    /// <summary>A second file that goes with this one when it is there (the voices of Strife); empty if none</summary>
    CompanionFileName: string;
    class function Make(const AFileName: string; AMode: TIwadGameMode;
      AMission: TIwadMission = imsUnchanged): TIwadEntry; static;
  end;

  /// <summary>What a rule about a file chosen by the player (-iwad) does</summary>
  TIwadCustomRuleKind = (
    /// <summary>The file is an add-on: another IWAD (FileName) has to be added first</summary>
    icrPrerequisite,
    /// <summary>When the file is there, another file (FileName) next to it goes with it</summary>
    icrCompanion);

  /// <summary>A rule on the files that the player may choose with -iwad or -mainwad</summary>
  TIwadCustomRule = record
    /// <summary>The name of the chosen file, in upper case, that triggers the rule</summary>
    Trigger: string;
    Kind: TIwadCustomRuleKind;
    FileName: string;
    class function Make(const ATrigger: string; AKind: TIwadCustomRuleKind;
      const AFileName: string): TIwadCustomRule; static;
  end;

  /// <summary>The answer of the identification: what the engine has to add and to set</summary>
  TIwadIdentification = record
    /// <summary>False when no IWAD was found: the mode is Indetermined and there are no files</summary>
    Found: Boolean;
    /// <summary>True when the file is the one that the player chose</summary>
    Custom: Boolean;
    /// <summary>The path of the file that the player chose, when it was accepted; otherwise empty</summary>
    CustomPath: string;
    /// <summary>The files to add, in order (the last is the IWAD itself, before it come the files it needs)</summary>
    Files: TArray<string>;
    /// <summary>The companion file that exists, or empty (the voices of Strife)</summary>
    VoicesPath: string;
    Mode: TIwadGameMode;
    Mission: TIwadMission;
    IsFrench: Boolean;
    IsBfg2: Boolean;
  end;

implementation

{ TIwadEntry }

class function TIwadEntry.Make(const AFileName: string; AMode: TIwadGameMode;
  AMission: TIwadMission): TIwadEntry;
begin
  Result.FileName := AFileName;
  Result.Mode := AMode;
  Result.Mission := AMission;
  Result.IsFrench := False;
  Result.IsBfg2 := False;
  Result.Searchable := True;
  Result.CompanionFileName := '';
end;

{ TIwadCustomRule }

class function TIwadCustomRule.Make(const ATrigger: string; AKind: TIwadCustomRuleKind;
  const AFileName: string): TIwadCustomRule;
begin
  Result.Trigger := ATrigger;
  Result.Kind := AKind;
  Result.FileName := AFileName;
end;

end.
