{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a .map file                          }
{                                                                              }
{  Port of idMapFile::Write (MapFile.cpp, idlib), Doom 3 GPL Source Code.      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.FileWriter;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf;

type
  /// <summary>
  ///   Writes a map in the format of version 2 (brushDef3, patchDef2, patchDef3), through the file
  ///   system that the caller injects. The original picks the base path ("fs_devpath") or an
  ///   explicit path; here that choice belongs to the file system
  /// </summary>
  TMapFileWriter = class(TInterfacedObject, IMapFileWriter)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
  public
    /// <summary>The file system is needed by Write (not by ToText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Write(const AMap: TMapFile; const AFileName, AExtension: AnsiString): Boolean;
    function ToText(const AMap: TMapFile): AnsiString;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Str, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.TextWriter,
  DelphiDoom.MapFile.EntityWriter;

resourcestring
  SWriting = 'writing %s...'#10;
  SCouldNotOpen = 'Couldn''t open %s'#10;

procedure WriteMap(const AOutput: TMapTextWriter; const AMap: TMapFile);
var
  LIndex: Integer;
begin
  // (float) CURRENT_MAP_VERSION written with %f
  AOutput.Add('Version ');
  AOutput.AddFloat(CURRENT_MAP_VERSION);
  AOutput.Add(#10);
  for LIndex := 0 to AMap.GetNumEntities - 1 do
    TMapEntityWriter.Write(AOutput, AMap.GetEntity(LIndex), LIndex);
end;

{ TMapFileWriter }

constructor TMapFileWriter.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TMapFileWriter.ToText(const AMap: TMapFile): AnsiString;
var
  LOutput: TMapTextWriter;
begin
  LOutput := TMapTextWriter.Create;
  try
    WriteMap(LOutput, AMap);
    Result := LOutput.GetText;
  finally
    LOutput.Free;
  end;
end;

function TMapFileWriter.Write(const AMap: TMapFile; const AFileName, AExtension: AnsiString): Boolean;
var
  LOutput: TMapTextWriter;
  LPath: TIdStr;
begin
  LPath := TIdStr.Create(AFileName);
  LPath.SetFileExtension(AExtension);
  if Assigned(FLog) then
    FLog.Printf(Format(SWriting, [string(LPath.Text)]));
  LOutput := TMapTextWriter.Create;
  try
    WriteMap(LOutput, AMap);
    Result := Assigned(FFileSystem) and FFileSystem.WriteFile(LPath.Text, LOutput.GetBytes);
  finally
    LOutput.Free;
  end;
  if not Result and Assigned(FLog) then
    FLog.Warning(Format(SCouldNotOpen, [string(LPath.Text)]));
end;

end.
