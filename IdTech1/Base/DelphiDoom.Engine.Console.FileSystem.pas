{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the files of the console command files                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.FileSystem;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   The disk as the old C_ExecCommandFile saw it: fexpand, fexists and a text file read line
  ///   by line until the end or the first I/O error
  /// </summary>
  TEngineConsoleFileSystem = class(TInterfacedObject, IConsoleFileSystem)
  public
    function ExpandFileName(const AFileName: string): string;
    function FileExists(const AFileName: string): Boolean;
    function ReadLines(const AFileName: string): TArray<string>;
  end;

implementation

uses
  System.Generics.Collections,
  d_delphi;

{ TEngineConsoleFileSystem }

function TEngineConsoleFileSystem.ExpandFileName(const AFileName: string): string;
begin
  Result := fexpand(AFileName);
end;

function TEngineConsoleFileSystem.FileExists(const AFileName: string): Boolean;
begin
  Result := fexists(AFileName);
end;

function TEngineConsoleFileSystem.ReadLines(const AFileName: string): TArray<string>;
var
  LLines: TList<string>;
  LFile: TextFile;
  LLine: string;
begin
  LLines := TList<string>.Create;
  try
    {$I-}
    AssignFile(LFile, AFileName);
    FileMode := 0;
    Reset(LFile);
    while not Eof(LFile) and (IOResult = 0) do
    begin
      Readln(LFile, LLine);
      LLines.Add(LLine);
    end;
    CloseFile(LFile);
    {$I+}
    Result := LLines.ToArray;
  finally
    LLines.Free;
  end;
end;

end.
