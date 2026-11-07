{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the contracts of the preprocessor              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Preprocessor.Intf;

interface

type
  /// <summary>Where the files and the lumps named by the #include directives come from</summary>
  IScriptIncludeSource = interface
    ['{4B9D7C21-6E08-4F53-A1D4-8C27E0B5F396}']
    /// <summary>The text of a file; an empty text if there is none</summary>
    function ReadFile(const AName: string): string;
    /// <summary>The text of all the files of that name (#include_all); empty if there are none</summary>
    function ReadAllFiles(const AName: string): string;
    /// <summary>The text of a lump (#include_wad); empty if there is none</summary>
    function ReadLump(const AName: string): string;
  end;

  /// <summary>
  ///   A directive that is not an include (#CVARFORCE, #CREATEPALETTE ...): the preprocessor
  ///   asks each one, in order, until one takes the line
  /// </summary>
  IScriptDirective = interface
    ['{E2A6F418-35B9-4D07-8C6E-91D4B7A3052F}']
    /// <summary>
    ///   AUpperLine is the line without its // comment, trimmed and in upper case. True if
    ///   the line is for this directive: it does not go to the output
    /// </summary>
    function Execute(const AUpperLine: string): Boolean;
  end;

  /// <summary>What #CVARFORCE needs from the engine: to force the value of a console variable</summary>
  ICvarSetter = interface
    ['{7D3C95E0-1A4B-48F2-B6D9-0E58C2A7F143}']
    /// <summary>The meaning of a text as a boolean, ADefault if it is not one</summary>
    function EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
    /// <summary>Each Try gives false if the variable is not of that type</summary>
    function TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
    function TrySetInteger(const AName: string; AValue: Integer): Boolean;
    function TrySetString(const AName: string; const AValue: string): Boolean;
  end;

  /// <summary>What #CREATEPALETTE needs from the engine</summary>
  IPaletteGenerator = interface
    ['{B58E0A73-92D1-4C6F-8F34-D7A1C60E5B28}']
    procedure Generate(const AArgument: string);
  end;

  /// <summary>The names that every script finds defined before its first line (the defines of the game)</summary>
  IScriptDefinesSource = interface
    ['{6F1C2B94-8E37-4A05-9D62-B4E0A71C3D58}']
    /// <summary>Asked at each script: the list can change while the game starts</summary>
    function Defines: TArray<string>;
  end;

  /// <summary>
  ///   Prepares the text of a script: includes, directives and defines. Two calls do not share
  ///   anything (the defines of a script do not stay for the next one)
  /// </summary>
  IScriptTextPreprocessor = interface
    ['{C3A85E17-4D92-4B6F-A0E8-2F71D95B6C04}']
    /// <summary>AAddComment puts a // comment before and after the text of each include</summary>
    function Preprocess(const AText: string; AAddComment: Boolean): string;
  end;

implementation

end.
