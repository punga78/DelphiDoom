{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3SourceHandles, the numbered sources that   }
{  the game modules of Quake III Arena read through (PC_LoadSourceHandle...)   }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c. Copyright (C) 1999-2005 Id Software, Inc. Licensed under the   }
{  GNU General Public License, version 2 or later.                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.SourceHandles;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.Q3.Types, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.Source,
  DelphiDoom.Scanner.Q3.ScriptLoader.Intf, DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.Define;

type
  /// <summary>
  ///   The table of 64 sources (handle 0 is never used). It owns the sources and frees the ones still
  ///   open when it is destroyed
  /// </summary>
  TQ3SourceHandles = class sealed
  strict private
    const
      MAX_SOURCEFILES = 64;
    var
      FSources: array[0..MAX_SOURCEFILES - 1] of TQ3Source;
      FLoader: IQ3ScriptLoader;
      FLog: IQ3ScriptLog;
      FGlobalDefines: TQ3GlobalDefines;
      FNow: TQ3NowProvider;
  public
    constructor Create(const ALoader: IQ3ScriptLoader; const ALog: IQ3ScriptLog;
      const AGlobalDefines: TQ3GlobalDefines; const ANow: TQ3NowProvider = nil);
    destructor Destroy; override;
    /// <summary>PC_LoadSourceHandle: the handle, 0 if the table is full or the file is not there</summary>
    function Load(const AFileName: AnsiString): Integer;
    /// <summary>PC_FreeSourceHandle</summary>
    function Release(const AHandle: Integer): Boolean;
    /// <summary>PC_ReadTokenHandle: the token goes out as pc_token_t (a float, the strings without their quotes)</summary>
    function ReadToken(const AHandle: Integer; out AToken: TQ3PcToken): Boolean;
    /// <summary>PC_SourceFileAndLine</summary>
    function SourceFileAndLine(const AHandle: Integer; out AFileName: AnsiString; out ALine: Integer): Boolean;
    /// <summary>PC_CheckOpenSourceHandles: an error in the log for every source that is still open</summary>
    procedure CheckOpen;
    /// <summary>
    ///   PC_AddGlobalDefine: a define from text ("NAME value" or "NAME(a, b) text") that every source opened
    ///   from now on gets. False (and the warning in the log) if the text is not a define. The sources that are
    ///   already open do not get it, as in the C: the copy is made when a source is loaded
    /// </summary>
    function AddGlobalDefine(const AText: AnsiString): Boolean;
    /// <summary>PC_RemoveGlobalDefine (see TQ3GlobalDefines.Remove for the difference from the C)</summary>
    function RemoveGlobalDefine(const AName: AnsiString): Boolean;
    /// <summary>PC_RemoveAllGlobalDefines</summary>
    procedure RemoveAllGlobalDefines;
  end;

implementation

uses
  DelphiDoom.Scanner.Q3.Script;

{ TQ3SourceHandles }

constructor TQ3SourceHandles.Create(const ALoader: IQ3ScriptLoader; const ALog: IQ3ScriptLog;
  const AGlobalDefines: TQ3GlobalDefines; const ANow: TQ3NowProvider);
begin
  inherited Create;
  FLoader := ALoader;
  FLog := ALog;
  FGlobalDefines := AGlobalDefines;
  FNow := ANow;
end;

destructor TQ3SourceHandles.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_SOURCEFILES - 1 do
    FSources[LIndex].Free;
  inherited;
end;

function TQ3SourceHandles.Load(const AFileName: AnsiString): Integer;
var
  LSource: TQ3Source;
begin
  Result := 1;
  while (Result < MAX_SOURCEFILES) and (FSources[Result] <> nil) do
    Inc(Result);
  if Result >= MAX_SOURCEFILES then
    Exit(0);
  FLoader.SetBaseFolder('');
  LSource := TQ3Source.LoadFile(AFileName, FLoader, FLog, FGlobalDefines, FNow);
  if LSource = nil then
    Exit(0);
  FSources[Result] := LSource;
end;

function TQ3SourceHandles.Release(const AHandle: Integer): Boolean;
begin
  if (AHandle < 1) or (AHandle >= MAX_SOURCEFILES) or (FSources[AHandle] = nil) then
    Exit(False);
  FreeAndNil(FSources[AHandle]);
  Result := True;
end;

function TQ3SourceHandles.ReadToken(const AHandle: Integer; out AToken: TQ3PcToken): Boolean;
var
  LToken: TQ3Token;
begin
  AToken := Default(TQ3PcToken);
  if (AHandle < 1) or (AHandle >= MAX_SOURCEFILES) or (FSources[AHandle] = nil) then
    Exit(False);
  LToken := Default(TQ3Token);
  Result := FSources[AHandle].ReadToken(LToken);
  AToken.Text := LToken.Text;
  AToken.TokenType := LToken.TokenType;
  AToken.Subtype := LToken.Subtype;
  AToken.IntValue := Integer(LToken.IntValue);
  AToken.FloatValue := LToken.FloatValue.ToSingle;
  if AToken.TokenType = TT_STRING then
    TQ3Script.StripDoubleQuotes(AToken.Text);
end;

function TQ3SourceHandles.SourceFileAndLine(const AHandle: Integer; out AFileName: AnsiString;
  out ALine: Integer): Boolean;
begin
  AFileName := '';
  ALine := 0;
  if (AHandle < 1) or (AHandle >= MAX_SOURCEFILES) or (FSources[AHandle] = nil) then
    Exit(False);
  AFileName := FSources[AHandle].FileName;
  if FSources[AHandle].CurrentScript <> nil then
    ALine := FSources[AHandle].CurrentScript.Line;
  Result := True;
end;

function TQ3SourceHandles.AddGlobalDefine(const AText: AnsiString): Boolean;
var
  LDefine: TQ3Define;
begin
  LDefine := TQ3Source.DefineFromString(AText, FLoader, FLog, FNow);
  if LDefine = nil then
    Exit(False);
  FGlobalDefines.Add(LDefine);
  Result := True;
end;

function TQ3SourceHandles.RemoveGlobalDefine(const AName: AnsiString): Boolean;
begin
  Result := FGlobalDefines.Remove(AName);
end;

procedure TQ3SourceHandles.RemoveAllGlobalDefines;
begin
  FGlobalDefines.Clear;
end;

procedure TQ3SourceHandles.CheckOpen;
var
  LIndex: Integer;
begin
  for LIndex := 1 to MAX_SOURCEFILES - 1 do
    if (FSources[LIndex] <> nil) and (FLog <> nil) then
      FLog.Print(Q3_PRT_ERROR, 'file ' + FSources[LIndex].CurrentScript.FileName +
        ' still open in precompiler'#10);
end;

end.
