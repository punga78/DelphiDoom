{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a .map file in the format of         }
{  Quake III Arena                                                             }
{                                                                              }
{  Written for this library (the inverse of the reading of the brushes of      }
{  Quake III in idMapFile::Parse, MapFile.cpp, Doom 3 GPL Source Code).        }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Q3FileWriter;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf;

type
  /// <summary>
  ///   Writes a map the way the tools of Quake III read it: no "Version" line (a file without it
  ///   is version 1, so that the reader adds "textures/" to the materials), entities with the
  ///   pairs, brushes of three points per side and patchDef2. A file that this writes is read back
  ///   by <c>TMapFileReader</c> with the same planes (exactly for those of the axes), materials
  ///   and patch points; lost for good are the texture matrices of Doom 3 (Quake III brushes have
  ///   shift, rotation and scale, which the model does not keep), the pairs of the brushes and the
  ///   explicit subdivisions of a patch
  /// </summary>
  TMapQ3FileWriter = class(TInterfacedObject, IMapFileWriter)
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
  System.SysUtils, DelphiDoom.IdLib.Text.Str, DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Q3EntityWriter;

resourcestring
  SWriting = 'writing %s...'#10;
  SCouldNotOpen = 'Couldn''t open %s'#10;

procedure WriteMap(const AOutput: TMapTextWriter; const AMap: TMapFile);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AMap.GetNumEntities - 1 do
    TMapQ3EntityWriter.Write(AOutput, AMap.GetEntity(LIndex), LIndex);
end;

{ TMapQ3FileWriter }

constructor TMapQ3FileWriter.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TMapQ3FileWriter.ToText(const AMap: TMapFile): AnsiString;
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

function TMapQ3FileWriter.Write(const AMap: TMapFile; const AFileName, AExtension: AnsiString): Boolean;
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
