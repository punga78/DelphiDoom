{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3ScriptLoader, LoadScriptFile and           }
{  LoadScriptMemory of Quake III Arena                                         }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_script.c. Copyright (C) 1999-2005 Id Software, Inc. Licensed under the    }
{  GNU General Public License, version 2 or later.                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.ScriptLoader;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.Script,
  DelphiDoom.Scanner.Q3.ScriptLoader.Intf;

type
  /// <summary>
  ///   Reads the scripts through IQ3ScriptFiles. A file is compressed (COM_Compress) and its end_p is the
  ///   length of the file before that; a script from memory is as it is. The base folder, a global of the
  ///   C, belongs to the loader
  /// </summary>
  TQ3ScriptLoader = class(TInterfacedObject, IQ3ScriptLoader)
  strict private
    const
      MaxQuakePath = 64;
    var
      FFiles: IQ3ScriptFiles;
      FLog: IQ3ScriptLog;
      FBaseFolder: AnsiString;
  public
    constructor Create(const AFiles: IQ3ScriptFiles; const ALog: IQ3ScriptLog);
    function LoadFile(const AFileName: AnsiString): TQ3Script;
    function LoadMemory(const AText: TBytes; const AName: AnsiString): TQ3Script;
    procedure SetBaseFolder(const APath: AnsiString);
  end;

implementation

uses
  DelphiDoom.Scanner.Q3.Compressor;

{ TQ3ScriptLoader }

constructor TQ3ScriptLoader.Create(const AFiles: IQ3ScriptFiles; const ALog: IQ3ScriptLog);
begin
  inherited Create;
  FFiles := AFiles;
  FLog := ALog;
end;

procedure TQ3ScriptLoader.SetBaseFolder(const APath: AnsiString);
begin
  // Com_sprintf(basefolder, MAX_QPATH, "%s", path)
  FBaseFolder := Copy(APath, 1, MaxQuakePath - 1);
end;

function TQ3ScriptLoader.LoadFile(const AFileName: AnsiString): TQ3Script;
var
  LPath: AnsiString;
  LData: TBytes;
  LText: AnsiString;
  LCompressed: AnsiString;
  LBytes: TBytes;
begin
  if FBaseFolder <> '' then
    LPath := FBaseFolder + '/' + AFileName
  else
    LPath := AFileName;
  // Com_sprintf into a pathname of MAX_QPATH characters
  LPath := Copy(LPath, 1, MaxQuakePath - 1);
  if (FFiles = nil) or not FFiles.TryRead(LPath, LData) then
    Exit(nil);
  SetLength(LText, Length(LData));
  if Length(LData) > 0 then
    Move(LData[0], LText[1], Length(LData));
  LCompressed := TQ3ScriptCompressor.Compress(LText);
  SetLength(LBytes, Length(LCompressed));
  if Length(LCompressed) > 0 then
    Move(LCompressed[1], LBytes[0], Length(LCompressed));
  Result := TQ3Script.Create(FLog, AFileName, LBytes, Length(LData));
end;

function TQ3ScriptLoader.LoadMemory(const AText: TBytes; const AName: AnsiString): TQ3Script;
begin
  Result := TQ3Script.Create(FLog, AName, AText, Length(AText));
end;

end.
