{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - contracts                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Intf;

interface

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Section;

type
  /// <summary>
  ///   The lines of a patch, as the old DEH_NextLine gave them: comments and blank lines are left
  ///   out and the line is in upper case. A reader can give back the line it has read last
  /// </summary>
  IDehackedLineSource = interface
    ['{5D2A7C41-93B8-4E06-A1F7-0C84E3B96D25}']
    /// <summary>
    ///   The next line; false if there are none. ASkipBlank false keeps the spaces and the blank
    ///   lines (the body of a TEXT block)
    /// </summary>
    function Next(out ALine: string; ASkipBlank: Boolean = True): Boolean;
    /// <summary>There are lines that Next has not given yet (blank and comments too)</summary>
    function HasMoreLines: Boolean;
    /// <summary>The line that Next gave last</summary>
    function LastLine: string;
    /// <summary>The number of the line that Next gave last, from 1</summary>
    function LineNumber: Integer;
    /// <summary>The line that was read last is not for this section: the parser reads it again as a header</summary>
    procedure PushBack;
    /// <summary>True if PushBack was called since the last time; it forgets the request</summary>
    function TakePushBack: Boolean;
  end;

  /// <summary>
  ///   The names of the flags of a field. A value is a number or a list of names; the list is
  ///   written with spaces, bars, commas or plus signs
  /// </summary>
  IDehackedFlagSet = interface
    ['{B4E61A08-2F95-4D37-8C1B-79A03E5D2F64}']
    /// <summary>The names, in the order of the bits</summary>
    function Names: TArray<string>;
    /// <summary>
    ///   False if the value gives no flag at all (the field keeps the value it had). AExtra gets
    ///   the flags that are not in the set but in the engine (the high bits of the flags of the things)
    /// </summary>
    function Resolve(const AText: string; ANumber: Integer; AIsNumber: Boolean;
      out AMask, AExtra: Integer): Boolean;
  end;

  /// <summary>The sets of flags that the fields of a game name, by the name that the table of fields gives</summary>
  IDehackedFlagSets = interface
    ['{E0A3C7B9-5F24-4816-9D7A-1B6C48F20E53}']
    /// <summary>nil if there is no such set</summary>
    function Find(const AName: string): IDehackedFlagSet;
  end;

  /// <summary>Reads one kind of block of a patch, from the line that introduces it</summary>
  IDehackedSectionReader = interface
    ['{7A91D3E5-4C08-4B62-9E1F-25D86B0A7C93}']
    /// <summary>The words that open the block, in upper case</summary>
    function Keywords: TArray<string>;
    /// <summary>
    ///   Reads the block; the first line has been read already. nil if the block is not valid
    ///   (a warning was given): its lines are then read as headers, as the old parser did. The
    ///   reader that finds a line that is not its own calls PushBack of the source
    /// </summary>
    function Read(const AKeyword, ARest: string; const ASource: IDehackedLineSource): TDehackedSection;
  end;

  /// <summary>What changes from a game to another: the blocks that its patches have</summary>
  IDehackedProfile = interface
    ['{C3F58B72-1D09-4A64-B7E3-6F2A81D90C45}']
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    function GameName: string;
    /// <summary>The reader of the block that a word opens; nil if there is none</summary>
    function FindReader(const AKeyword: string): IDehackedSectionReader;
  end;

  /// <summary>What a parser reads out of a patch: the blocks in the order of the file</summary>
  IDehackedPatch = interface
    ['{2E86B1D7-F530-4A9C-8D24-A0C7E39B5168}']
    function SectionCount: Integer;
    function Section(AIndex: Integer): TDehackedSection;
    /// <summary>The value of "Doom version"; -1 if the patch does not say</summary>
    function DoomVersion: Integer;
    /// <summary>The value of "Patch format"; -1 if the patch does not say</summary>
    function PatchFormat: Integer;
    /// <summary>The first line of the patch is "Patch File for DeHackEd"</summary>
    function HasSignature: Boolean;
  end;

  /// <summary>Reads the text of a patch (DEH or BEX)</summary>
  IDehackedParser = interface
    ['{91D4A6F2-83B7-4E15-AC60-D58E2F17B934}']
    function Parse(const AText: string): IDehackedPatch;
    function ParseLines(const ALines: TArray<string>): IDehackedPatch;
  end;

implementation

end.
