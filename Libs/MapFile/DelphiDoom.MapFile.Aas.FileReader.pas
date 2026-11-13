{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading an .aas file                         }
{                                                                              }
{  Port of idAASFileLocal::Load and FinishAreas (AASFile.cpp), Doom 3 GPL      }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.FileReader;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>
  ///   Reads .aas files from a file system that the caller injects: the id "DewmAAS", the
  ///   version "1.07", the CRC of the map and the sections in any order. As in the original,
  ///   each area gets its bounds and its travel flags after the read, and a tree deeper than
  ///   MAX_AAS_TREE_DEPTH is only a warning in the log
  /// </summary>
  TAasFileReader = class(TInterfacedObject, IAasFileReader)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    function CreateLexer: TIdLexer;
    procedure ReadHeader(const ALexer: TIdLexer; const AFile: TAasFile; const ACrc: Cardinal);
    procedure ReadSections(const ALexer: TIdLexer; const AFile: TAasFile);
    procedure FinishAreas(const AFile: TAasFile);
    function ReadAll(const ALexer: TIdLexer; const AName: AnsiString; const ACrc: Cardinal): TAasFile;
  public
    /// <summary>The file system is needed by Parse (not by ParseText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Parse(const AFileName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
    function ParseText(const AText, AName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Geometry, DelphiDoom.MapFile.Aas.SettingsReader,
  DelphiDoom.MapFile.Aas.GeometryReader, DelphiDoom.MapFile.Aas.AreaReader, DelphiDoom.MapFile.Aas.TreeReader;

resourcestring
  SAasTextNotLoaded = 'The text of the AAS file could not be loaded';
  SNotAnAasFile = 'Not an AAS file: ''%s''';
  SBadVersion = 'AAS file ''%s'' has version %s instead of %s';
  SOutOfDate = 'AAS file ''%s'' is out of date';
  SBadToken = 'idAASFileLocal::Load: bad token "%s"';
  STreeDepth = 'idAASFileLocal::Load: tree depth = %d'#10;
  SFailure = 'file %s, line %d: %s';

{ TAasFileReader }

constructor TAasFileReader.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TAasFileReader.CreateLexer: TIdLexer;
begin
  Result := TIdLexer.Create(AAS_LEXER_FLAGS, FLog, FFileSystem);
end;

procedure TAasFileReader.ReadHeader(const ALexer: TIdLexer; const AFile: TAasFile; const ACrc: Cardinal);
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ALexer.ReadToken(LToken) or not LToken.IsText(AAS_FILEID) then
    raise EAasFileException.Create(Format(SNotAnAasFile, [string(AFile.Name)]), ALexer.LineNum);
  if not ALexer.ReadToken(LToken) or not LToken.IsText(AAS_FILEVERSION) then
    raise EAasFileException.Create(Format(SBadVersion, [string(AFile.Name), string(LToken.Text),
      AAS_FILEVERSION]), ALexer.LineNum);
  ALexer.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
  AFile.Crc := LToken.GetUnsignedLongValue;
  if (ACrc <> 0) and (AFile.Crc <> ACrc) then
    raise EAasFileOutOfDateException.Create(Format(SOutOfDate, [string(AFile.Name)]), ALexer.LineNum);
end;

procedure TAasFileReader.ReadSections(const ALexer: TIdLexer; const AFile: TAasFile);
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  while ALexer.ReadToken(LToken) do
  begin
    if LToken.IsText('settings') then
      TAasSettingsReader.Parse(ALexer, AFile.Settings)
    else if LToken.IsText('planes') then
      AFile.Planes := TAasGeometryReader.ReadPlanes(ALexer)
    else if LToken.IsText('vertices') then
      AFile.Vertices := TAasGeometryReader.ReadVertices(ALexer)
    else if LToken.IsText('edges') then
      AFile.Edges := TAasGeometryReader.ReadEdges(ALexer)
    else if LToken.IsText('edgeIndex') then
      AFile.EdgeIndex := TAasGeometryReader.ReadIndex(ALexer, 'edge indexes')
    else if LToken.IsText('faces') then
      AFile.Faces := TAasGeometryReader.ReadFaces(ALexer)
    else if LToken.IsText('faceIndex') then
      AFile.FaceIndex := TAasGeometryReader.ReadIndex(ALexer, 'face indexes')
    else if LToken.IsText('areas') then
      TAasAreaReader.Parse(ALexer, AFile)
    else if LToken.IsText('nodes') then
      AFile.Nodes := TAasTreeReader.ReadNodes(ALexer)
    else if LToken.IsText('portals') then
      AFile.Portals := TAasTreeReader.ReadPortals(ALexer)
    else if LToken.IsText('portalIndex') then
      AFile.PortalIndex := TAasGeometryReader.ReadIndex(ALexer, 'portal indexes')
    else if LToken.IsText('clusters') then
      AFile.Clusters := TAasTreeReader.ReadClusters(ALexer)
    else
      ALexer.Error(SBadToken, [string(LToken.Text)]);
  end;
end;

procedure TAasFileReader.FinishAreas(const AFile: TAasFile);
var
  LIndex, LDepth: Integer;
begin
  for LIndex := 0 to AFile.NumAreas - 1 do
    AFile.Areas[LIndex].Bounds := TAasGeometry.AreaBounds(AFile, LIndex);
  LDepth := TAasGeometry.MaxTreeDepth(AFile);
  if (LDepth > MAX_AAS_TREE_DEPTH) and Assigned(FLog) then
    FLog.Warning(Format(STreeDepth, [LDepth]));
end;

function TAasFileReader.ReadAll(const ALexer: TIdLexer; const AName: AnsiString;
  const ACrc: Cardinal): TAasFile;
begin
  Result := TAasFile.Create;
  try
    Result.Name := AName;
    ReadHeader(ALexer, Result, ACrc);
    ReadSections(ALexer, Result);
    FinishAreas(Result);
  except
    on E: EAasFileOutOfDateException do
    begin
      Result.Free;
      raise;
    end;
    on E: EIdLexerException do
    begin
      Result.Free;
      raise EAasFileException.Create(E.Message, ALexer.LineNum);
    end;
    on E: EAasFileException do
    begin
      Result.Free;
      if E.Line > 0 then
        raise;
      raise EAasFileException.Create(Format(SFailure, [string(AName), ALexer.LineNum, E.Message]), ALexer.LineNum);
    end;
    else
    begin
      Result.Free;
      raise;
    end;
  end;
end;

function TAasFileReader.Parse(const AFileName: AnsiString; const ACrc: Cardinal): TAasFile;
var
  LLexer: TIdLexer;
begin
  LLexer := CreateLexer;
  try
    if not LLexer.LoadFile(AFileName) then
      Exit(nil);
    Result := ReadAll(LLexer, AFileName, ACrc);
  finally
    LLexer.Free;
  end;
end;

function TAasFileReader.ParseText(const AText, AName: AnsiString; const ACrc: Cardinal): TAasFile;
var
  LLexer: TIdLexer;
begin
  LLexer := CreateLexer;
  try
    if not LLexer.LoadMemory(AText, AName) then
      raise EAasFileException.Create(SAasTextNotLoaded);
    Result := ReadAll(LLexer, AName, ACrc);
  finally
    LLexer.Free;
  end;
end;

end.
