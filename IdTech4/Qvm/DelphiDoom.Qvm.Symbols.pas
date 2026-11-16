{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the symbols of a .map file and the profile        }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of VM_LoadSymbols, ParseHex, VM_ValueToSymbol,                         }
{  VM_ValueToFunctionSymbol, VM_SymbolToValue and VM_VmProfile_f               }
{  (code/qcommon/vm.c), Quake III Arena 1.32                                   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Symbols;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types;

type
  /// <summary>
  ///   The symbols of the code segment in the order of the .map file (the original keeps a linked list and
  ///   walks it from the start, so the answers depend on that order when the file is not sorted), each
  ///   with the number of instructions the profile counted on it
  /// </summary>
  TQvmSymbols = class
  strict private
    FInstructionPointers: TArray<Integer>;
    FNames: TArray<AnsiString>;
    FValues: TArray<Integer>;
    FCounts: TArray<Int64>;
    FIncompleteLine: Boolean;
    function GetCount: Integer;
  public
    /// <param name="AInstructionPointers">The offset of every instruction: a symbol is an instruction number in the file</param>
    constructor Create(const AInstructionPointers: TArray<Integer>);
    /// <summary>ParseHex: the hexadecimal digits of a word, anything else is skipped; wraps at 32 bit</summary>
    class function ParseHex(const AText: AnsiString): Integer; static;
    /// <summary>VM_LoadSymbols: returns how many symbols the text has</summary>
    function Load(const AText: AnsiString): Integer;
    function ValueToSymbol(AValue: Integer): AnsiString;
    /// <summary>VM_ValueToFunctionSymbol: the index of the symbol a program counter belongs to, -1 without symbols</summary>
    function FunctionIndex(AValue: Integer): Integer;
    function SymbolToValue(const AName: AnsiString): Integer;
    /// <summary>Adds instructions to the count of a symbol; the index -1 (no symbols) is ignored</summary>
    procedure AddCount(AIndex: Integer; ACount: Int64);
    function TakeProfile: TQvmProfile;
    property Count: Integer read GetCount;
    /// <summary>The last Load met a line without its value or its name ("incomplete line at end of file")</summary>
    property IncompleteLine: Boolean read FIncompleteLine;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.TokenReader;

// ParseHex wraps as the int of the original
{$Q-}
{$R-}

const
  SNoSymbols: AnsiString = 'NO SYMBOLS';

{ TQvmSymbols }

constructor TQvmSymbols.Create(const AInstructionPointers: TArray<Integer>);
begin
  inherited Create;
  FInstructionPointers := AInstructionPointers;
end;

function TQvmSymbols.GetCount: Integer;
begin
  Result := Length(FNames);
end;

class function TQvmSymbols.ParseHex(const AText: AnsiString): Integer;
var
  LIndex, LChar: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AText) do
  begin
    LChar := Ord(AText[LIndex]);
    if (LChar >= Ord('0')) and (LChar <= Ord('9')) then
      Result := Result * 16 + LChar - Ord('0')
    else if (LChar >= Ord('a')) and (LChar <= Ord('f')) then
      Result := Result * 16 + 10 + LChar - Ord('a')
    else if (LChar >= Ord('A')) and (LChar <= Ord('F')) then
      Result := Result * 16 + 10 + LChar - Ord('A');
  end;
end;

function TQvmSymbols.Load(const AText: AnsiString): Integer;
var
  LReader: TQ3TokenReader;
  LToken, LName: AnsiString;
  LValue: Integer;
begin
  FNames := nil;
  FValues := nil;
  FCounts := nil;
  FIncompleteLine := False;
  LReader := TQ3TokenReader.Create(AText);
  try
    while True do
    begin
      LToken := LReader.Next;
      if LToken = '' then
        Break;
      if ParseHex(LToken) <> 0 then
      begin
        // only load code segment values
        LReader.Next;
        LReader.Next;
        Continue;
      end;
      LToken := LReader.Next;
      LName := LReader.Next;
      if (LToken = '') or (LName = '') then
      begin
        FIncompleteLine := True;
        Break;
      end;
      LValue := ParseHex(LToken);
      // convert value from an instruction number to a code offset
      if (LValue >= 0) and (LValue < Length(FInstructionPointers)) then
        LValue := FInstructionPointers[LValue];
      FNames := FNames + [LName];
      FValues := FValues + [LValue];
    end;
  finally
    LReader.Free;
  end;
  SetLength(FCounts, Length(FNames));
  Result := Length(FNames);
end;

function TQvmSymbols.FunctionIndex(AValue: Integer): Integer;
begin
  if Length(FValues) = 0 then
    Exit(-1);
  Result := 0;
  while (Result + 1 < Length(FValues)) and (FValues[Result + 1] <= AValue) do
    Inc(Result);
end;

function TQvmSymbols.ValueToSymbol(AValue: Integer): AnsiString;
var
  LIndex: Integer;
begin
  LIndex := FunctionIndex(AValue);
  if LIndex < 0 then
    Exit(SNoSymbols);
  if AValue = FValues[LIndex] then
    Result := FNames[LIndex]
  else
    Result := FNames[LIndex] + '+' + AnsiString(IntToStr(AValue - FValues[LIndex]));
end;

function TQvmSymbols.SymbolToValue(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FNames) do
    if FNames[LIndex] = AName then
      Exit(FValues[LIndex]);
  Result := 0;
end;

procedure TQvmSymbols.AddCount(AIndex: Integer; ACount: Int64);
begin
  if (AIndex >= 0) and (AIndex < Length(FCounts)) then
    Inc(FCounts[AIndex], ACount);
end;

function TQvmSymbols.TakeProfile: TQvmProfile;
var
  LOrder: TArray<Integer>;
  LIndex, LOther, LKept: Integer;
  LProduct: Single;
  LTotal: Double;
begin
  Result.Total := 0;
  SetLength(LOrder, Length(FNames));
  for LIndex := 0 to High(LOrder) do
  begin
    LOrder[LIndex] := LIndex;
    Inc(Result.Total, FCounts[LIndex]);
  end;
  // the qsort of the original leaves equal counts in any order: here they keep the order of the file
  for LIndex := 1 to High(LOrder) do
  begin
    LKept := LOrder[LIndex];
    LOther := LIndex - 1;
    while (LOther >= 0) and (FCounts[LOrder[LOther]] > FCounts[LKept]) do
    begin
      LOrder[LOther + 1] := LOrder[LOther];
      Dec(LOther);
    end;
    LOrder[LOther + 1] := LKept;
  end;

  LTotal := Result.Total;
  SetLength(Result.Entries, Length(LOrder));
  for LIndex := 0 to High(LOrder) do
  begin
    Result.Entries[LIndex].Name := FNames[LOrder[LIndex]];
    Result.Entries[LIndex].Count := FCounts[LOrder[LIndex]];
    // perc = 100 * (float) sym->profileCount / total; with nothing counted the original divides by zero
    if Result.Total = 0 then
      Result.Entries[LIndex].Percent := 0
    else
    begin
      LProduct := FCounts[LOrder[LIndex]];
      LProduct := 100 * LProduct;
      Result.Entries[LIndex].Percent := Trunc(LProduct / LTotal);
    end;
    FCounts[LOrder[LIndex]] := 0;
  end;
end;

end.
