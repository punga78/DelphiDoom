{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing an .aas file                         }
{                                                                              }
{  Port of idAASFileLocal::Write (AASFile.cpp), Doom 3 GPL Source Code.        }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.FileWriter;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>
  ///   Writes an .aas file through the file system that the caller injects: the id and the
  ///   version, the CRC of the map, the settings, then planes, vertices, edges, edge index,
  ///   faces, face index, areas with their reachabilities, nodes, portals, portal index and
  ///   clusters, as idAASFileLocal::Write does. As in the original, writing gives the file the
  ///   name and the CRC it was written with
  /// </summary>
  TAasFileWriter = class(TInterfacedObject, IAasFileWriter)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
  public
    /// <summary>The file system is needed by Write (not by ToText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Write(const AFile: TAasFile; const AFileName: AnsiString; const ACrc: Cardinal): Boolean;
    function ToText(const AFile: TAasFile; const ACrc: Cardinal): AnsiString;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.SettingsWriter, DelphiDoom.MapFile.Aas.GeometryWriter,
  DelphiDoom.MapFile.Aas.AreaWriter, DelphiDoom.MapFile.Aas.TreeWriter;

resourcestring
  SWriteAas = '[Write AAS]'#10;
  SWriting = 'writing %s'#10;
  SDone = 'done.'#10;
  SCouldNotOpen = 'Error opening %s';

procedure WriteContent(const AOutput: TMapTextWriter; const AFile: TAasFile; const ACrc: Cardinal);
begin
  AOutput.Add(AAS_FILEID + ' "' + AAS_FILEVERSION + '"'#10#10);
  AOutput.Add(AnsiString(UIntToStr(ACrc)) + #10#10);
  AOutput.Add('settings'#10);
  TAasSettingsWriter.Write(AOutput, AFile.Settings);
  TAasGeometryWriter.WritePlanes(AOutput, AFile);
  TAasGeometryWriter.WriteVertices(AOutput, AFile);
  TAasGeometryWriter.WriteEdges(AOutput, AFile);
  TAasGeometryWriter.WriteIndex(AOutput, 'edgeIndex', AFile.EdgeIndex);
  TAasGeometryWriter.WriteFaces(AOutput, AFile);
  TAasGeometryWriter.WriteIndex(AOutput, 'faceIndex', AFile.FaceIndex);
  TAasAreaWriter.Write(AOutput, AFile);
  TAasTreeWriter.WriteNodes(AOutput, AFile);
  TAasTreeWriter.WritePortals(AOutput, AFile);
  TAasGeometryWriter.WriteIndex(AOutput, 'portalIndex', AFile.PortalIndex);
  TAasTreeWriter.WriteClusters(AOutput, AFile);
end;

{ TAasFileWriter }

constructor TAasFileWriter.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TAasFileWriter.ToText(const AFile: TAasFile; const ACrc: Cardinal): AnsiString;
var
  LOutput: TMapTextWriter;
begin
  LOutput := TMapTextWriter.Create;
  try
    WriteContent(LOutput, AFile, ACrc);
    Result := LOutput.GetText;
  finally
    LOutput.Free;
  end;
end;

function TAasFileWriter.Write(const AFile: TAasFile; const AFileName: AnsiString; const ACrc: Cardinal): Boolean;
var
  LOutput: TMapTextWriter;
begin
  if Assigned(FLog) then
  begin
    FLog.Printf(SWriteAas);
    FLog.Printf(Format(SWriting, [string(AFileName)]));
  end;
  AFile.Name := AFileName;
  AFile.Crc := ACrc;
  LOutput := TMapTextWriter.Create;
  try
    WriteContent(LOutput, AFile, ACrc);
    Result := Assigned(FFileSystem) and FFileSystem.WriteFile(AFileName, LOutput.GetBytes);
  finally
    LOutput.Free;
  end;
  if not Result then
    raise EAasFileException.Create(Format(SCouldNotOpen, [string(AFileName)]));
  if Assigned(FLog) then
    FLog.Printf(SDone);
end;

end.
