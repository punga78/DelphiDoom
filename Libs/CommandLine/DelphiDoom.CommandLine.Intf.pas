{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - contracts                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Intf;

interface

type
  /// <summary>
  ///   The arguments the program was started with (and those of its default file), as the
  ///   engine reads them: upper case, the name of the program at position 0
  /// </summary>
  ICommandLine = interface
    ['{B7C25E91-3D08-4A6F-9E14-0F8A6D2C73B5}']
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    /// <summary>
    ///   The position of a parameter (case insensitive) after the name of the program, or 0 when
    ///   it is not there: what M_CheckParm answers
    /// </summary>
    function IndexOf(const AName: string): Integer;
    function Has(const AName: string): Boolean;
    /// <summary>
    ///   The arguments after a parameter, up to the end or to the next one that starts with '-'
    ///   (the files after -file); empty when the parameter is not there
    /// </summary>
    function ValuesAfter(const AName: string): TArray<string>;
    /// <summary>The arguments after the name of the program, joined with a space</summary>
    function Text: string;
    /// <summary>The number of arguments, the name of the program included</summary>
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: string read GetItem; default;
  end;

  /// <summary>
  ///   A command line that exists before the arguments are read and that remembers what the
  ///   program asked of it: the engine hands it to every class that reads an option, then
  ///   M_InitArgv attaches the real command line. The names asked so far feed the console
  ///   command "commandlineparams"
  /// </summary>
  IQueriedCommandLine = interface(ICommandLine)
    ['{5A1D83C6-27F4-4E09-B6A2-D84C10E7F953}']
    /// <summary>
    ///   Sets the command line that answers the questions. Until then no parameter is there
    ///   (IndexOf gives 0, Count gives 0), as the old M_CheckParm did before M_InitArgv
    /// </summary>
    procedure Attach(const ACommandLine: ICommandLine);
    /// <summary>
    ///   The parameters asked for by name (IndexOf, Has, ValuesAfter), each once whatever its
    ///   case (the first spelling), in the order they were first asked
    /// </summary>
    function QueriedNames: TArray<string>;
  end;

  /// <summary>
  ///   Where the files of the engine that are not in the folder of the program go: the same
  ///   name, or the name inside the working folder of the CD-ROM when the program runs from
  ///   a CD-ROM or with -cdrom
  /// </summary>
  ISaveFileNames = interface
    ['{C3E75B90-1A4D-4F28-9D61-0B7E5A82F1C4}']
    /// <summary>True when the files go to the working folder of the CD-ROM</summary>
    function IsCdRomMode: Boolean;
    /// <summary>The name in the working folder of the CD-ROM, or the name itself</summary>
    function ResolveName(const AFileName: string): string;
  end;

  /// <summary>Collects the arguments and makes the ICommandLine</summary>
  ICommandLineBuilder = interface
    ['{4E90A1D7-8B26-4C3F-A5D8-72C1E0F9B346}']
    /// <summary>
    ///   Appends an argument (kept upper case; an empty one is skipped). Past the limit of the
    ///   engine the arguments are not kept; the result says whether this one was
    /// </summary>
    function Add(const AArgument: string): Boolean;
    /// <summary>
    ///   Appends the marker of the default file and the arguments of its text (the text
    ///   of the file: comments, arguments separated by spaces)
    /// </summary>
    procedure AddDefaultFile(const AText: string);
    function Count: Integer;
    /// <summary>The command line of what was added; the builder starts again from nothing</summary>
    function Build: ICommandLine;
  end;

  /// <summary>Where the text of a response file (@name on the command line) comes from</summary>
  IResponseFileSource = interface
    ['{6D2B8F14-95A3-4E70-8C1D-3F07A4B6E259}']
    /// <summary>The whole text of the file; false when it cannot be opened</summary>
    function TryRead(const AFileName: string; out AText: string): Boolean;
  end;

  /// <summary>
  ///   Replaces each argument that starts with '@' by the arguments written in the file it names
  ///   (separated by spaces or line breaks): the old FindResponseFile of the four d_main
  /// </summary>
  IResponseFileExpander = interface
    ['{0B94E3C7-1A58-4D26-B7F0-82C5D19A6E43}']
    /// <summary>
    ///   The arguments with the response files expanded: the program name stays first, empty
    ///   arguments are dropped and no more than AMaxArguments are kept. A file that cannot be
    ///   read is reported to the log and its argument is dropped
    /// </summary>
    function Expand(const AArguments: TArray<string>; AMaxArguments: Integer): TArray<string>;
  end;

implementation

end.
