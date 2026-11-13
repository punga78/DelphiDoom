{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotScriptFileSystem, the file system the script       }
{  parser reads the files of the bots from                                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  LoadScriptFile of code\botlib\l_script.c and PC_Directive_include of        }
{  l_precomp.c. Licensed under the GNU General Public License, version 2 or    }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ScriptFileSystem;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>
  ///   The file system of TIdParser for the files of the bots: the path is read from the base folder
  ///   ("botfiles/"), the text is compressed as LoadScriptFile does, and the name of the script stays the
  ///   one asked for (the messages say "file syn.c"). A path that starts with a separator is not found, so
  ///   the first guess of the parser for an include (relative to the current file) falls to the second.
  /// </summary>
  TBotScriptFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FFiles: IBotFileSource;
    FBaseFolder: AnsiString;
    class function ConvertPath(const AName: AnsiString): AnsiString; static;
  public
    constructor Create(const AFiles: IBotFileSource; const ABaseFolder: AnsiString);
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.ScriptCompressor;

{ TBotScriptFileSystem }

constructor TBotScriptFileSystem.Create(const AFiles: IBotFileSource; const ABaseFolder: AnsiString);
begin
  inherited Create;
  FFiles := AFiles;
  FBaseFolder := ABaseFolder;
end;

// PC_ConvertPath: no double separators, forward slashes
class function TBotScriptFileSystem.ConvertPath(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
  LChar: AnsiChar;
begin
  Result := '';
  for LIndex := 1 to Length(AName) do
  begin
    LChar := AName[LIndex];
    if LChar = '\' then
      LChar := '/';
    if (LChar = '/') and (Result <> '') and (Result[Length(Result)] = '/') then
      Continue;
    Result := Result + LChar;
  end;
end;

function TBotScriptFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LPath: AnsiString;
  LData: TBytes;
  LText: AnsiString;
  LCompressed: AnsiString;
begin
  Result := False;
  if (AName = '') or (AName[1] in ['/', '\']) then
    Exit;
  LPath := ConvertPath(AName);
  if FBaseFolder <> '' then
    LPath := FBaseFolder + '/' + LPath;
  if not FFiles.TryReadFile(LPath, LData) then
    Exit;
  SetLength(LText, Length(LData));
  if Length(LData) > 0 then
    Move(LData[0], LText[1], Length(LData));
  LCompressed := TBotScriptCompressor.Compress(LText);
  SetLength(AFile.Data, Length(LCompressed));
  if Length(LCompressed) > 0 then
    Move(LCompressed[1], AFile.Data[0], Length(LCompressed));
  AFile.FullPath := AName;
  AFile.Timestamp := 0;
  Result := True;
end;

function TBotScriptFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  // the bot library only reads
  Result := False;
end;

end.
