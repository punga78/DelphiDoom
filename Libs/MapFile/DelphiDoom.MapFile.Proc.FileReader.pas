{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a .proc file                         }
{                                                                              }
{  Port of the loop of idRenderWorldLocal::InitFromMap (RenderWorld_load.cpp), }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.FileReader;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.ProcFile,
  DelphiDoom.MapFile.Proc.Intf;

type
  /// <summary>
  ///   Reads .proc files from a file system that the caller injects: the id "mapProcFile003",
  ///   then "model", "shadowModel", "interAreaPortals" and "nodes" sections in any order until
  ///   the end of the text
  /// </summary>
  TProcFileReader = class(TInterfacedObject, IProcFileReader)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    function CreateLexer: TIdLexer;
    procedure ReadSections(const ALexer: TIdLexer; const AFile: TProcFile);
    function ReadAll(const ALexer: TIdLexer; const AName: AnsiString): TProcFile;
  public
    /// <summary>The file system is needed by Parse (not by ParseText); the log may be nil</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Parse(const AFileName: AnsiString): TProcFile;
    function ParseText(const AText, AName: AnsiString): TProcFile;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Token,
  DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.ModelReader,
  DelphiDoom.MapFile.Proc.ShadowModelReader, DelphiDoom.MapFile.Proc.PortalReader,
  DelphiDoom.MapFile.Proc.NodeReader;

resourcestring
  SProcTextNotLoaded = 'The text of the proc file could not be loaded';
  SBadId = 'bad id ''%s'' instead of ''%s''';
  SBadToken = 'idRenderWorldLocal::InitFromMap: bad token "%s"';

{ TProcFileReader }

constructor TProcFileReader.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TProcFileReader.CreateLexer: TIdLexer;
begin
  Result := TIdLexer.Create(PROC_LEXER_FLAGS, FLog, FFileSystem);
end;

procedure TProcFileReader.ReadSections(const ALexer: TIdLexer; const AFile: TProcFile);
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ALexer.ReadToken(LToken) or not SameText(string(LToken.Text), PROC_FILE_ID) then
    raise EProcFileException.Create(Format(SBadId, [string(LToken.Text), PROC_FILE_ID]), ALexer.LineNum);
  while ALexer.ReadToken(LToken) do
  begin
    if LToken.IsText('model') then
      AFile.Models.Add(TProcModelReader.Parse(ALexer))
    else if LToken.IsText('shadowModel') then
      AFile.ShadowModels.Add(TProcShadowModelReader.Parse(ALexer))
    else if LToken.IsText('interAreaPortals') then
      TProcPortalReader.Parse(ALexer, AFile)
    else if LToken.IsText('nodes') then
      TProcNodeReader.Parse(ALexer, AFile)
    else
      ALexer.Error(SBadToken, [string(LToken.Text)]);
  end;
end;

function TProcFileReader.ReadAll(const ALexer: TIdLexer; const AName: AnsiString): TProcFile;
begin
  Result := TProcFile.Create;
  try
    Result.Name := AName;
    ReadSections(ALexer, Result);
  except
    on E: EIdLexerException do
    begin
      Result.Free;
      raise EProcFileException.Create(E.Message, ALexer.LineNum);
    end;
    else
    begin
      Result.Free;
      raise;
    end;
  end;
end;

function TProcFileReader.Parse(const AFileName: AnsiString): TProcFile;
var
  LName, LFullName: TIdStr;
  LLexer: TIdLexer;
begin
  LName := TIdStr.Create(AFileName);
  LName.StripFileExtension;
  LFullName := LName;
  LFullName.SetFileExtension(PROC_FILE_EXT);
  LLexer := CreateLexer;
  try
    if not LLexer.LoadFile(LFullName.Text) then
      Exit(nil);
    Result := ReadAll(LLexer, LName.Text);
  finally
    LLexer.Free;
  end;
end;

function TProcFileReader.ParseText(const AText, AName: AnsiString): TProcFile;
var
  LLexer: TIdLexer;
begin
  LLexer := CreateLexer;
  try
    if not LLexer.LoadMemory(AText, AName) then
      raise EProcFileException.Create(SProcTextNotLoaded);
    Result := ReadAll(LLexer, AName);
  finally
    LLexer.Free;
  end;
end;

end.
