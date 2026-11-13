{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the files that dir and cat show                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.FileLister;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   The disk as the old c_utils saw it: findfiles for the masks, TDStringList.LoadFromFile
  ///   for a text file and GetDir for the current directory
  /// </summary>
  TEngineConsoleFileLister = class(TInterfacedObject, IConsoleFileLister)
  public
    function FindFiles(const AMask: string): TArray<string>;
    function ReadTextLines(const AFileName: string): TArray<string>;
    function CurrentDirectory: string;
  end;

implementation

uses
  d_delphi;

{ TEngineConsoleFileLister }

function TEngineConsoleFileLister.FindFiles(const AMask: string): TArray<string>;
var
  LFiles: TDStringList;
  LIndex: Integer;
begin
  // the method has the name of the global function: qualify it
  LFiles := d_delphi.findfiles(AMask);
  try
    SetLength(Result, LFiles.Count);
    for LIndex := 0 to LFiles.Count - 1 do
      Result[LIndex] := LFiles[LIndex];
  finally
    LFiles.Free;
  end;
end;

function TEngineConsoleFileLister.ReadTextLines(const AFileName: string): TArray<string>;
var
  LLines: TDStringList;
  LIndex: Integer;
begin
  LLines := TDStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    SetLength(Result, LLines.Count);
    for LIndex := 0 to LLines.Count - 1 do
      Result[LIndex] := LLines[LIndex];
  finally
    LLines.Free;
  end;
end;

function TEngineConsoleFileLister.CurrentDirectory: string;
begin
  GetDir(0, Result);
end;

end.
