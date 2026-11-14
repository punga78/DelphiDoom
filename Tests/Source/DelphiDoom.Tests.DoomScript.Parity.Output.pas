{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - output of the parity    }
{  driver                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.Output;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>
  ///   The lines of a run of the parity driver, in the format of the goldens of the C++ harness
  ///   (Tools\Verifica\110\main.cpp): one fact per line, floats as bits, text escaped, printed text
  ///   collected until its end of line. It is the log of the script machine. Not reference counted: the
  ///   scenario owns it and frees it after the machine.
  /// </summary>
  TDoomScriptParityOutput = class(TNoRefCountObject, IIdLibLog)
  strict private
    FLines: TStringList;
    // 0 = Printf, 1 = DPrintf
    FPending: array[0..1] of AnsiString;
    procedure Printed(const AKind: Integer; const AText: AnsiString);
    class function ReplaceNumbers(const AText: AnsiString; const AFrom: Integer): AnsiString; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>gameLocal.Printf / common->Printf</summary>
    procedure Printf(const AMessage: string);
    /// <summary>gameLocal.Warning and the like: one call, one WARN line</summary>
    procedure Warning(const AMessage: string);
    /// <summary>gameLocal.DPrintf</summary>
    procedure DebugPrintf(const AMessage: string);
    /// <summary>A whole line of the output; printed text that is still waiting for its end of line goes first</summary>
    procedure Line(const AText: AnsiString);
    /// <summary>Writes the printed text that has no end of line yet as PRINT+ / DPRINT+</summary>
    procedure FlushPending;
    /// <summary>
    ///   The normalization of the harness: the time of "Compiled '..': N ms" and the sizes of the memory
    ///   lines of the compile statistics become "?"
    /// </summary>
    class function Normalize(const AText: AnsiString): AnsiString; static;
    class function Esc(const AText: AnsiString): AnsiString; static;
    class function Quoted(const AText: AnsiString): AnsiString; static;
    class function FloatBits(const AValue: Single): AnsiString; static;
    class function Vec3(const AValue: TIdVec3): AnsiString; static;
    class function Vec4(const AValue: TIdVec3; const AW: Single): AnsiString; static;
    class function Num(const AValue: Integer): AnsiString; static;
    class function Hex(const AData: PByte; const ASize: Integer): AnsiString; overload; static;
    class function Hex(const AData: TBytes): AnsiString; overload; static;
    class function EntityRef(const ANumber: Integer): AnsiString; static;
    property Lines: TStringList read FLines;
  end;

implementation

const
  PendingTags: array[0..1] of AnsiString = ('PRINT', 'DPRINT');
  MemoryLines: array[0..6] of AnsiString = ('     Strings:', '  Statements:', '   Functions:', '    Mem used:',
    ' Static data:', '   Allocated:', ' Thread size:');

constructor TDoomScriptParityOutput.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TDoomScriptParityOutput.Destroy;
begin
  FLines.Free;
  inherited;
end;

class function TDoomScriptParityOutput.Esc(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
  LChar: AnsiChar;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LChar := AText[LIndex];
    case LChar of
      '\': Result := Result + '\\';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #9: Result := Result + '\t';
      '"': Result := Result + '\"';
    else
      if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
        Result := Result + '\x' + AnsiString(IntToHex(Ord(LChar), 2))
      else
        Result := Result + LChar;
    end;
  end;
end;

class function TDoomScriptParityOutput.Quoted(const AText: AnsiString): AnsiString;
begin
  Result := '"' + Esc(AText) + '"';
end;

class function TDoomScriptParityOutput.FloatBits(const AValue: Single): AnsiString;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, 4);
  Result := '#' + AnsiString(IntToHex(LBits, 8));
end;

class function TDoomScriptParityOutput.Vec3(const AValue: TIdVec3): AnsiString;
begin
  Result := FloatBits(AValue.X) + ',' + FloatBits(AValue.Y) + ',' + FloatBits(AValue.Z);
end;

class function TDoomScriptParityOutput.Vec4(const AValue: TIdVec3; const AW: Single): AnsiString;
begin
  Result := Vec3(AValue) + ',' + FloatBits(AW);
end;

class function TDoomScriptParityOutput.Num(const AValue: Integer): AnsiString;
begin
  Result := AnsiString(IntToStr(AValue));
end;

class function TDoomScriptParityOutput.Hex(const AData: PByte; const ASize: Integer): AnsiString;
const
  Digits: array[0..15] of AnsiChar = '0123456789ABCDEF';
var
  LIndex: Integer;
begin
  SetLength(Result, ASize * 2);
  for LIndex := 0 to ASize - 1 do
  begin
    Result[LIndex * 2 + 1] := Digits[AData[LIndex] shr 4];
    Result[LIndex * 2 + 2] := Digits[AData[LIndex] and 15];
  end;
end;

class function TDoomScriptParityOutput.Hex(const AData: TBytes): AnsiString;
begin
  if Length(AData) = 0 then
    Result := ''
  else
    Result := Hex(@AData[0], Length(AData));
end;

class function TDoomScriptParityOutput.EntityRef(const ANumber: Integer): AnsiString;
begin
  if ANumber < 0 then
    Result := 'null'
  else
    Result := 'ent:' + Num(ANumber);
end;

class function TDoomScriptParityOutput.ReplaceNumbers(const AText: AnsiString; const AFrom: Integer): AnsiString;
var
  LIndex: Integer;
begin
  // AFrom is a zero based position, as in the harness
  Result := Copy(AText, 1, AFrom);
  LIndex := AFrom + 1;
  while LIndex <= Length(AText) do
    if AText[LIndex] in ['0'..'9'] then
    begin
      while (LIndex <= Length(AText)) and (AText[LIndex] in ['0'..'9', '.']) do
        Inc(LIndex);
      Result := Result + '?';
    end
    else
    begin
      Result := Result + AText[LIndex];
      Inc(LIndex);
    end;
end;

class function TDoomScriptParityOutput.Normalize(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
  LPos: Integer;
  LLast: Integer;
begin
  if Copy(AText, 1, 10) = 'Compiled ''' then
  begin
    LLast := 0;
    LPos := Pos(AnsiString(''': '), AText);
    while LPos > 0 do
    begin
      LLast := LPos;
      LPos := Pos(AnsiString(''': '), AText, LPos + 1);
    end;
    if LLast > 0 then
      Exit(ReplaceNumbers(AText, LLast - 1 + 3));
  end;
  for LIndex := Low(MemoryLines) to High(MemoryLines) do
    if Copy(AText, 1, Length(MemoryLines[LIndex])) = MemoryLines[LIndex] then
    begin
      LPos := Pos(AnsiChar(','), AText);
      if LPos = 0 then
        Exit(ReplaceNumbers(AText, Length(MemoryLines[LIndex])));
      Exit(ReplaceNumbers(AText, LPos - 1));
    end;
  Result := AText;
end;

procedure TDoomScriptParityOutput.FlushPending;
var
  LKind: Integer;
begin
  for LKind := 0 to 1 do
    if FPending[LKind] <> '' then
    begin
      FLines.Add(string(PendingTags[LKind] + '+ ' + Esc(FPending[LKind])));
      FPending[LKind] := '';
    end;
end;

procedure TDoomScriptParityOutput.Line(const AText: AnsiString);
begin
  FlushPending;
  FLines.Add(string(AText));
end;

procedure TDoomScriptParityOutput.Printed(const AKind: Integer; const AText: AnsiString);
var
  LPos: Integer;
  LLine: AnsiString;
begin
  if FPending[1 - AKind] <> '' then
    FlushPending;
  FPending[AKind] := FPending[AKind] + AText;
  LPos := Pos(AnsiChar(#10), FPending[AKind]);
  while LPos > 0 do
  begin
    LLine := Normalize(Copy(FPending[AKind], 1, LPos - 1));
    Delete(FPending[AKind], 1, LPos);
    FLines.Add(string(PendingTags[AKind] + ' ' + Esc(LLine)));
    LPos := Pos(AnsiChar(#10), FPending[AKind]);
  end;
end;

procedure TDoomScriptParityOutput.Printf(const AMessage: string);
begin
  Printed(0, AnsiString(AMessage));
end;

procedure TDoomScriptParityOutput.DebugPrintf(const AMessage: string);
begin
  Printed(1, AnsiString(AMessage));
end;

procedure TDoomScriptParityOutput.Warning(const AMessage: string);
begin
  Line('WARN ' + Esc(AnsiString(AMessage)));
end;

end.
