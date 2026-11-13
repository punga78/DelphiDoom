{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing a .proc file                         }
{                                                                              }
{  Port of the sequence of WriteOutputFile (output.cpp of dmap), Doom 3 GPL    }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.FileWriter;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Proc.ProcFile, DelphiDoom.MapFile.Proc.Intf;

type
  /// <summary>
  ///   Writes a .proc file through the file system that the caller injects: the id, the models,
  ///   the portals and the nodes (if the file has those sections), then the shadow models. dmap
  ///   does not write a section for a world of a single area
  /// </summary>
  TProcFileWriter = class(TInterfacedObject, IProcFileWriter)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
  public
    /// <summary>The file system is needed by Write (not by ToText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Write(const AFile: TProcFile; const AFileName: AnsiString): Boolean;
    function ToText(const AFile: TProcFile): AnsiString;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Str, DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Proc.Types,
  DelphiDoom.MapFile.Proc.Model, DelphiDoom.MapFile.Proc.ShadowModel, DelphiDoom.MapFile.Proc.ModelWriter,
  DelphiDoom.MapFile.Proc.ShadowModelWriter, DelphiDoom.MapFile.Proc.PortalWriter,
  DelphiDoom.MapFile.Proc.NodeWriter;

resourcestring
  SWriting = 'writing %s'#10;
  SCouldNotOpen = 'Couldn''t open %s'#10;

procedure WriteContent(const AOutput: TMapTextWriter; const AFile: TProcFile);
var
  LModel: TProcModel;
  LShadowModel: TProcShadowModel;
begin
  AOutput.Add(PROC_FILE_ID + #10#10);
  for LModel in AFile.Models do
    TProcModelWriter.Write(AOutput, LModel);
  if AFile.HasPortalSection then
    TProcPortalWriter.Write(AOutput, AFile);
  if AFile.HasNodeSection then
    TProcNodeWriter.Write(AOutput, AFile);
  for LShadowModel in AFile.ShadowModels do
    TProcShadowModelWriter.Write(AOutput, LShadowModel);
end;

{ TProcFileWriter }

constructor TProcFileWriter.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TProcFileWriter.ToText(const AFile: TProcFile): AnsiString;
var
  LOutput: TMapTextWriter;
begin
  LOutput := TMapTextWriter.Create;
  try
    WriteContent(LOutput, AFile);
    Result := LOutput.GetText;
  finally
    LOutput.Free;
  end;
end;

function TProcFileWriter.Write(const AFile: TProcFile; const AFileName: AnsiString): Boolean;
var
  LOutput: TMapTextWriter;
  LPath: TIdStr;
begin
  LPath := TIdStr.Create(AFileName);
  LPath.SetFileExtension(PROC_FILE_EXT);
  if Assigned(FLog) then
    FLog.Printf(Format(SWriting, [string(LPath.Text)]));
  LOutput := TMapTextWriter.Create;
  try
    WriteContent(LOutput, AFile);
    Result := Assigned(FFileSystem) and FFileSystem.WriteFile(LPath.Text, LOutput.GetBytes);
  finally
    LOutput.Free;
  end;
  if not Result and Assigned(FLog) then
    FLog.Warning(Format(SCouldNotOpen, [string(LPath.Text)]));
end;

end.
