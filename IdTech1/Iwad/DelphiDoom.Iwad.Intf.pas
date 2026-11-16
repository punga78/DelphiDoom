{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the contracts                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Intf;

interface

uses
  DelphiDoom.Iwad.Types;

type
  /// <summary>The environment variables of the program</summary>
  IIwadEnvironment = interface
    ['{3B7E5A21-94C8-4D0F-A6E3-1F58C2D7B904}']
    /// <summary>The value of a variable, without the spaces around it; empty if it is not set</summary>
    function GetValue(const AName: string): string;
  end;

  /// <summary>The file system, as much as the search needs</summary>
  IIwadFileSystem = interface
    ['{C41F8D06-72A5-4B93-8E1D-5A09F6B3C278}']
    function FileExists(const APath: string): Boolean;
    /// <summary>The complete path of a name: a name without folder is in the current folder</summary>
    function ExpandPath(const APath: string): string;
  end;

  /// <summary>Where Steam put a game</summary>
  IIwadSteam = interface
    ['{8E2A6C95-1D47-4F03-B8A7-9C30E5D1F642}']
    /// <summary>
    ///   The folder where the Steam application is installed, with '\' as separator and at
    ///   the end; empty when it is not installed
    /// </summary>
    function GetInstallDirectory(AApplicationId: Integer): string;
  end;

  /// <summary>
  ///   The settings of the search, read every time because the player may change them
  ///   (they are options of the configuration file)
  /// </summary>
  IIwadOptions = interface
    ['{57D90B34-E6A1-4C28-93F5-A81C7E04D2B6}']
    function GetSearchWadDirectory: Boolean;
    function GetSearchWadPath: Boolean;
    function GetSearchSteamPaths: Boolean;
    function GetAdditionalPaths: string;
    /// <summary>Look in the folders of the variables like DOOMWADDIR</summary>
    property SearchWadDirectory: Boolean read GetSearchWadDirectory;
    /// <summary>Look in the lists of folders of the variables like DOOMWADPATH</summary>
    property SearchWadPath: Boolean read GetSearchWadPath;
    /// <summary>Look in the folders of the Steam applications</summary>
    property SearchSteamPaths: Boolean read GetSearchSteamPaths;
    /// <summary>Folders separated by ';' that the player added</summary>
    property AdditionalPaths: string read GetAdditionalPaths;
  end;

  /// <summary>A source of folders where the files are looked for: a strategy of the locator</summary>
  IIwadSearchPath = interface
    ['{A06C3E78-B2D5-49F1-8734-E5B9D01C6A23}']
    /// <summary>The folders of this source now, in the order to try; empty if it is switched off</summary>
    function GetDirectories: TArray<string>;
  end;

  /// <summary>Finds a file in the search paths: what D_FileInDoomPath does</summary>
  IIwadLocator = interface
    ['{1F8B4D62-3A97-4E05-BC18-6D2E90A7F534}']
    /// <summary>
    ///   The name as it is if the file is there; otherwise the first search path that has a
    ///   file with the same name (the folder of the name is ignored) gives its complete name;
    ///   if nobody has it, the name as it was given
    /// </summary>
    function Locate(const AFileName: string): string;
  end;

  /// <summary>What a game knows: its IWADs and where it looks for them</summary>
  IIwadProfile = interface
    ['{D9035E1A-47B8-4C62-A1F7-02B6C85E3D49}']
    function GetGameName: string;
    function GetEntries: TArray<TIwadEntry>;
    function GetCustomRules: TArray<TIwadCustomRule>;
    function GetDirectoryVariables: TArray<string>;
    function GetPathVariables: TArray<string>;
    function GetSteamApplications: TArray<Integer>;
    function GetDirectPhaseVariable: string;
    property GameName: string read GetGameName;
    /// <summary>The IWADs, the first has the priority</summary>
    property Entries: TArray<TIwadEntry> read GetEntries;
    property CustomRules: TArray<TIwadCustomRule> read GetCustomRules;
    /// <summary>The variables that name a folder, in the order to try (DOOMWADDIR)</summary>
    property DirectoryVariables: TArray<string> read GetDirectoryVariables;
    /// <summary>The variables that name a list of folders (DOOMWADPATH)</summary>
    property PathVariables: TArray<string> read GetPathVariables;
    /// <summary>The Steam applications of the game, in the order to try</summary>
    property SteamApplications: TArray<Integer> read GetSteamApplications;
    /// <summary>
    ///   When it is not empty the IWADs are first looked for by their name joined to the
    ///   folder of this variable (or to the current folder) and only after that in the
    ///   search paths; when it is empty they are looked for directly in the search paths
    /// </summary>
    property DirectPhaseVariable: string read GetDirectPhaseVariable;
  end;

  /// <summary>Chooses the IWAD of a game</summary>
  IIwadIdentifier = interface
    ['{6C47A0D3-85E2-4B19-9F60-3E1D7B52A8C4}']
    /// <summary>
    ///   The file that the player chose (-iwad, -mainwad). False when the name is empty or when
    ///   the file is not there (and it is not an add-on that has its own rule)
    /// </summary>
    function TryIdentifyCustom(const AName: string; out AIdentification: TIwadIdentification): Boolean;
    /// <summary>The first IWAD in the order of the profile that is found in the search paths</summary>
    function IdentifyKnown: TIwadIdentification;
  end;

  /// <summary>What the engine needs from the library, assembled for one game</summary>
  TIwadServices = record
    Locator: IIwadLocator;
    Identifier: IIwadIdentifier;
  end;

implementation

end.
