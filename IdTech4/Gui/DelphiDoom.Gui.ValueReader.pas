{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - reading values from a menu file                   }
{                                                                              }
{  Port of PC_Float_Parse, PC_Int_Parse, PC_Color_Parse, PC_Rect_Parse,        }
{  PC_String_Parse, PC_Script_Parse, PC_SourceError and PC_SourceWarning of    }
{  ui_shared.c (Quake III Arena, id Software, GPL v2 or later). Based on the   }
{  Quake III Arena GPL Source Code (id Software).                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.ValueReader;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.StringPool;

type
  /// <summary>
  ///   The PC_*_Parse functions over one open source (the "handle" of the original). As in the original, a
  ///   value that cannot be read leaves its variable as it was.
  /// </summary>
  TGuiValueReader = class
  strict private
    FSource: IGuiTokenSource;
    FLog: IGuiLog;
    FStrings: TGuiStringPool;
  public
    /// <summary>The pool is the caller's (the menu set owns it); the log may be nil</summary>
    constructor Create(const ASource: IGuiTokenSource; const AStrings: TGuiStringPool; const ALog: IGuiLog);
    /// <summary>trap_PC_ReadToken: the string of a token that is a string comes without quotes</summary>
    function ReadToken(out AToken: TGuiToken): Boolean;
    function ReadFloat(var AValue: Single): Boolean;
    function ReadInt(var AValue: Integer): Boolean;
    /// <summary>Four floats in a row (PC_Color_Parse); each one is stored as it is read</summary>
    function ReadColor(var AColor: TGuiColor): Boolean;
    function ReadRect(var ARect: TGuiRect): Boolean;
    /// <summary>Any token, put in the pool (PC_String_Parse)</summary>
    function ReadString(var AText: AnsiString): Boolean;
    /// <summary>
    ///   "{ ... }" as the text of a script: tokens of more than one character in quotes, all followed by a
    ///   space, at most 1023 characters (PC_Script_Parse)
    /// </summary>
    function ReadScript(var AText: AnsiString): Boolean;
    /// <summary>PC_SourceError</summary>
    procedure SourceError(const AText: string);
    procedure SourceWarning(const AText: string);
    property Source: IGuiTokenSource read FSource;
    property Strings: TGuiStringPool read FStrings;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings;

constructor TGuiValueReader.Create(const ASource: IGuiTokenSource; const AStrings: TGuiStringPool;
  const ALog: IGuiLog);
begin
  inherited Create;
  FSource := ASource;
  FStrings := AStrings;
  FLog := ALog;
end;

function TGuiValueReader.ReadToken(out AToken: TGuiToken): Boolean;
begin
  Result := FSource.ReadToken(AToken);
end;

procedure TGuiValueReader.SourceError(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Error(FSource.FileName, FSource.Line, AText);
end;

procedure TGuiValueReader.SourceWarning(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(FSource.FileName, FSource.Line, AText);
end;

function TGuiValueReader.ReadFloat(var AValue: Single): Boolean;
var
  LToken: TGuiToken;
  LNegative: Boolean;
begin
  LNegative := False;
  if not ReadToken(LToken) then
    Exit(False);
  // a token that starts with a minus: "-" but also "--" or "-=", the original looks at the first character only
  if (LToken.Text <> '') and (LToken.Text[1] = '-') then
  begin
    if not ReadToken(LToken) then
      Exit(False);
    LNegative := True;
  end;
  if LToken.TokenType <> TT_NUMBER then
  begin
    SourceError('expected float but found ' + string(LToken.Text) + #10);
    Exit(False);
  end;
  if LNegative then
    AValue := -LToken.FloatValue
  else
    AValue := LToken.FloatValue;
  Result := True;
end;

function TGuiValueReader.ReadInt(var AValue: Integer): Boolean;
var
  LToken: TGuiToken;
  LNegative: Boolean;
begin
  LNegative := False;
  if not ReadToken(LToken) then
    Exit(False);
  if (LToken.Text <> '') and (LToken.Text[1] = '-') then
  begin
    if not ReadToken(LToken) then
      Exit(False);
    LNegative := True;
  end;
  if LToken.TokenType <> TT_NUMBER then
  begin
    SourceError('expected integer but found ' + string(LToken.Text) + #10);
    Exit(False);
  end;
  AValue := LToken.IntValue;
  if LNegative then
    AValue := -AValue;
  Result := True;
end;

function TGuiValueReader.ReadColor(var AColor: TGuiColor): Boolean;
var
  LIndex: Integer;
  LValue: Single;
begin
  LValue := 0;
  for LIndex := 0 to 3 do
  begin
    if not ReadFloat(LValue) then
      Exit(False);
    AColor[LIndex] := LValue;
  end;
  Result := True;
end;

function TGuiValueReader.ReadRect(var ARect: TGuiRect): Boolean;
begin
  Result := ReadFloat(ARect.X) and ReadFloat(ARect.Y) and ReadFloat(ARect.W) and ReadFloat(ARect.H);
end;

function TGuiValueReader.ReadString(var AText: AnsiString): Boolean;
var
  LToken: TGuiToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  AText := FStrings.Alloc(LToken.Text);
  Result := True;
end;

function TGuiValueReader.ReadScript(var AText: AnsiString): Boolean;
var
  LToken: TGuiToken;
  LScript: AnsiString;

  // Q_strcat(script, 1024, text): never more than 1023 characters
  procedure Append(const AAdded: AnsiString);
  begin
    LScript := LScript + Copy(AAdded, 1, GUI_SCRIPT_BUFFER_SIZE - 1 - Length(LScript));
  end;

begin
  LScript := '';
  if not ReadToken(LToken) then
    Exit(False);
  if TIdStrings.Icmp(LToken.Text, '{') <> 0 then
    Exit(False);
  while True do
  begin
    if not ReadToken(LToken) then
      Exit(False);
    if TIdStrings.Icmp(LToken.Text, '}') = 0 then
    begin
      AText := FStrings.Alloc(LScript);
      Exit(True);
    end;
    if Length(LToken.Text) > 1 then
      Append('"' + LToken.Text + '"')
    else
      Append(LToken.Text);
    Append(' ');
  end;
end;

end.
