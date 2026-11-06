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

implementation

end.
