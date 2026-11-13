{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a .map file                          }
{                                                                              }
{  Port of idMapFile::Parse (MapFile.cpp, idlib), Doom 3 GPL Source Code.      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.FileReader;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf;

type
  /// <summary>
  ///   Reads .map files (versions 1 and 2: the old brushes with three points, brushDef, brushDef2,
  ///   brushDef3, patchDef2, patchDef3 and the brushes of Quake 3) from a file system that the
  ///   caller injects, and applies the directives of the worldspawn
  /// </summary>
  TMapFileReader = class(TInterfacedObject, IMapFileReader)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    function CreateLexer: TIdLexer;
    function ReadMap(const ALexer: TIdLexer; const AMap: TMapFile): TMapFile;
    function ReadAll(const ALexer: TIdLexer; const AName: AnsiString): TMapFile;
  public
    /// <summary>The file system is needed by Parse (not by ParseText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Parse(const AFileName: AnsiString; const AIgnoreRegion: Boolean = False;
      const AIsOsPath: Boolean = False): TMapFile;
    function ParseText(const AText, AName: AnsiString): TMapFile;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Types, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.EntityReader,
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Directives;

resourcestring
  SMapTextNotLoaded = 'The text of the map could not be loaded';

const
  // no string concatenation for epairs and allow path names for materials
  MAP_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES;
  VERSION_KEYWORD: AnsiString = 'Version';

{ TMapFileReader }

constructor TMapFileReader.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TMapFileReader.CreateLexer: TIdLexer;
begin
  Result := TIdLexer.Create(MAP_LEXER_FLAGS, FLog, FFileSystem);
end;

function TMapFileReader.ReadMap(const ALexer: TIdLexer; const AMap: TMapFile): TMapFile;
var
  LToken: TIdToken;
  LEntity: TMapEntity;
begin
  AMap.Version := OLD_MAP_VERSION;
  AMap.FileTime := ALexer.FileTime;
  LToken := TIdToken.Create;
  if ALexer.CheckTokenString(VERSION_KEYWORD) then
  begin
    ALexer.ReadTokenOnLine(LToken);
    AMap.Version := LToken.GetFloatValue;
  end;

  repeat
    LEntity := TMapEntityReader.Parse(ALexer, AMap.Version);
    if Assigned(LEntity) then
      AMap.AddEntity(LEntity);
  until not Assigned(LEntity);

  AMap.UpdateGeometryCrc;
  TMapDirectives.Apply(AMap);
  AMap.HasPrimitiveData := True;
  Result := AMap;
end;

function TMapFileReader.Parse(const AFileName: AnsiString; const AIgnoreRegion: Boolean;
  const AIsOsPath: Boolean): TMapFile;
var
  LLexer: TIdLexer;
  LName, LFullName: TIdStr;
begin
  LName := TIdStr.Create(AFileName);
  LName.StripFileExtension;
  LFullName := LName;
  LLexer := CreateLexer;
  try
    if not AIgnoreRegion then
    begin
      // try loading a .reg file first
      LFullName.SetFileExtension(REGION_EXTENSION);
      LLexer.LoadFile(LFullName.Text, AIsOsPath);
    end;
    if not LLexer.IsLoaded then
    begin
      // now try a .map file
      LFullName.SetFileExtension(MAP_EXTENSION);
      LLexer.LoadFile(LFullName.Text, AIsOsPath);
      if not LLexer.IsLoaded then
        // didn't get anything at all
        Exit(nil);
    end;
    Result := ReadAll(LLexer, LName.Text);
  finally
    LLexer.Free;
  end;
end;

function TMapFileReader.ReadAll(const ALexer: TIdLexer; const AName: AnsiString): TMapFile;
begin
  Result := TMapFile.Create;
  try
    Result.Name := AName;
    ReadMap(ALexer, Result);
  except
    on E: EIdLexerException do
    begin
      Result.Free;
      raise EMapFileException.Create(E.Message, ALexer.LineNum);
    end;
    else
    begin
      Result.Free;
      raise;
    end;
  end;
end;

function TMapFileReader.ParseText(const AText, AName: AnsiString): TMapFile;
var
  LLexer: TIdLexer;
begin
  LLexer := CreateLexer;
  try
    if not LLexer.LoadMemory(AText, AName) then
      raise EMapFileException.Create(SMapTextNotLoaded);
    Result := ReadAll(LLexer, AName);
  finally
    LLexer.Free;
  end;
end;

end.
