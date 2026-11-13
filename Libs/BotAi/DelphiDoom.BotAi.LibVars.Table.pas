{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotLibVarTable, the library variables                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\l_libvar.c.                                                     }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.LibVars.Table;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf;

type
  /// <summary>
  ///   The table of library variables of the bot library (l_libvar.c): a variable has a text, a float
  ///   value (LibVarStringValue of the text) and a "modified" flag; the names are compared without
  ///   case as in the original.
  /// </summary>
  TBotLibVarTable = class(TInterfacedObject, IBotLibVars, IBotLibVarStore)
  strict private
    type
      TBotLibVar = record
        Text: AnsiString;
        Modified: Boolean;
      end;
  strict private
    FVariables: TDictionary<string, TBotLibVar>;
    class function Key(const AName: AnsiString): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   LibVarStringValue: digits with at most one point; any other character gives 0. Defects of the
    ///   original that are kept: no sign and no exponent (<c>-1</c> and <c>1e3</c> are 0), and the
    ///   character after the point is converted without being checked (<c>1.x</c> is 1 + ('x' - '0') / 10;
    ///   <c>5.</c> is 5 - 48 / 10: the original then also reads past the end of the text, here it stops).
    /// </summary>
    class function StringValue(const AText: AnsiString): Single; static;
    /// <summary>LibVarSet: creates or changes the variable</summary>
    procedure SetText(const AName, AText: AnsiString);
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
    function GetString(const AName: AnsiString): AnsiString;
    function Changed(const AName: AnsiString): Boolean;
    procedure SetNotModified(const AName: AnsiString);
  end;

implementation

{ TBotLibVarTable }

constructor TBotLibVarTable.Create;
begin
  inherited Create;
  FVariables := TDictionary<string, TBotLibVar>.Create;
end;

destructor TBotLibVarTable.Destroy;
begin
  FVariables.Free;
  inherited Destroy;
end;

class function TBotLibVarTable.Key(const AName: AnsiString): string;
begin
  Result := LowerCase(string(AName));
end;

class function TBotLibVarTable.StringValue(const AText: AnsiString): Single;
var
  LIndex: Integer;
  LDotFound: Integer;
  LCharacter: AnsiChar;
  LDigit: Integer;
  LValue: Single;
  LDouble: Double;
  LNumerator: Single;
  LDenominator: Single;
  LTerm: Single;
begin
  LDotFound := 0;
  LValue := 0;
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    LCharacter := AText[LIndex];
    if (LCharacter < '0') or (LCharacter > '9') then
    begin
      if (LDotFound <> 0) or (LCharacter <> '.') then
        Exit(0);
      LDotFound := 10;
      Inc(LIndex);
    end;
    // after the point the original does not look at the character it converts
    if LIndex > Length(AText) then
      LDigit := -Ord('0')
    else
      LDigit := Ord(AText[LIndex]) - Ord('0');
    if LDotFound <> 0 then
    begin
      LNumerator := LDigit;
      LDenominator := LDotFound;
      LTerm := LNumerator / LDenominator;
      LValue := LValue + LTerm;
      LDotFound := LDotFound * 10;
    end
    else
    begin
      LDouble := LValue;
      LDouble := LDouble * 10.0;
      LDouble := LDouble + LDigit;
      LValue := LDouble;
    end;
    Inc(LIndex);
  end;
  Result := LValue;
end;

procedure TBotLibVarTable.SetText(const AName, AText: AnsiString);
var
  LVariable: TBotLibVar;
begin
  LVariable.Text := AText;
  LVariable.Modified := True;
  FVariables.AddOrSetValue(Key(AName), LVariable);
end;

function TBotLibVarTable.GetValue(const AName: AnsiString): Single;
var
  LVariable: TBotLibVar;
begin
  if FVariables.TryGetValue(Key(AName), LVariable) then
    Result := StringValue(LVariable.Text)
  else
    Result := 0;
end;

function TBotLibVarTable.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := StringValue(GetStringOrCreate(AName, ADefault));
end;

function TBotLibVarTable.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
var
  LVariable: TBotLibVar;
begin
  if not FVariables.TryGetValue(Key(AName), LVariable) then
  begin
    LVariable.Text := ADefault;
    LVariable.Modified := True;
    FVariables.Add(Key(AName), LVariable);
  end;
  Result := LVariable.Text;
end;

function TBotLibVarTable.GetString(const AName: AnsiString): AnsiString;
var
  LVariable: TBotLibVar;
begin
  if FVariables.TryGetValue(Key(AName), LVariable) then
    Result := LVariable.Text
  else
    Result := '';
end;

function TBotLibVarTable.Changed(const AName: AnsiString): Boolean;
var
  LVariable: TBotLibVar;
begin
  Result := FVariables.TryGetValue(Key(AName), LVariable) and LVariable.Modified;
end;

procedure TBotLibVarTable.SetNotModified(const AName: AnsiString);
var
  LVariable: TBotLibVar;
begin
  if FVariables.TryGetValue(Key(AName), LVariable) then
  begin
    LVariable.Modified := False;
    FVariables[Key(AName)] := LVariable;
  end;
end;

end.
