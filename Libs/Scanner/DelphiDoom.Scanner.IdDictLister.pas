{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdDictLister, the listing commands of idDict }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Dict.cpp                 }
{  (idDict::ListKeys_f, idDict::ListValues_f).                                 }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdDictLister;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict;

type
  /// <summary>
  ///   The commands <c>listDictKeys</c> and <c>listDictValues</c> of idTech 4 (<c>idDict::ListKeys_f</c> and
  ///   <c>ListValues_f</c>), which print every distinct key and value of all dictionaries. In the original
  ///   they read the global string pools; here each dictionary owns its strings, so the lister is given the
  ///   dictionaries whose strings the pools would hold. Keys are distinct without regard to case (the first
  ///   spelling is kept, as the key pool does), values with regard to it; both are sorted without regard
  ///   to case (<c>idStr::Icmp</c>). The output goes to the injected log, one line per string and a count
  ///   <c>%5d keys</c> or <c>%5d values</c>.
  ///   <para>Differences: <c>ShowMemoryUsage_f</c> (the sizes of the pools) is not ported, there are no pools;
  ///   the original sorts with <c>qsort</c>, which is not stable: values that differ only in case come out
  ///   here in the order they were first met; the command registration (<c>cmdSystem</c>) is the caller's.</para>
  /// </summary>
  TIdDictLister = class
  strict private
    FLog: IIdLibLog;
    procedure Print(const AStrings: TArray<AnsiString>; const ACountFormat: string);
    class function AsciiLower(const AText: AnsiString): AnsiString; static;
    procedure SortWithoutCase(var AStrings: TArray<AnsiString>);
    function Distinct(const ADictionaries: array of TIdDict; const AKeys: Boolean): TArray<AnsiString>;
  public
    /// <summary>The log gets the output (nil: nothing is printed)</summary>
    constructor Create(const ALog: IIdLibLog);
    /// <summary>idDict::ListKeys_f</summary>
    procedure ListKeys(const ADictionaries: array of TIdDict);
    /// <summary>idDict::ListValues_f</summary>
    procedure ListValues(const ADictionaries: array of TIdDict);
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.IdLib.Text.Strings;

{ TIdDictLister }

constructor TIdDictLister.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

class function TIdDictLister.AsciiLower(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] in ['A'..'Z'] then
      Result[LIndex] := AnsiChar(Ord(Result[LIndex]) + 32);
end;

procedure TIdDictLister.SortWithoutCase(var AStrings: TArray<AnsiString>);
type
  TEntry = record
    Text: AnsiString;
    Order: Integer;
  end;
var
  LEntries: TArray<TEntry>;
  LIndex: Integer;
begin
  SetLength(LEntries, Length(AStrings));
  for LIndex := 0 to High(AStrings) do
  begin
    LEntries[LIndex].Text := AStrings[LIndex];
    LEntries[LIndex].Order := LIndex;
  end;
  // the order of meeting breaks the ties, so the result does not depend on the sort algorithm
  TArray.Sort<TEntry>(LEntries, TComparer<TEntry>.Construct(
    function(const ALeft, ARight: TEntry): Integer
    begin
      Result := TIdStrings.Icmp(ALeft.Text, ARight.Text);
      if Result = 0 then
        Result := ALeft.Order - ARight.Order;
    end));
  for LIndex := 0 to High(LEntries) do
    AStrings[LIndex] := LEntries[LIndex].Text;
end;

function TIdDictLister.Distinct(const ADictionaries: array of TIdDict; const AKeys: Boolean): TArray<AnsiString>;
var
  LList: TList<AnsiString>;
  LSeen: TDictionary<AnsiString, Boolean>;
  LDictionary: Integer;
  LIndex: Integer;
  LPair: TIdKeyValue;
  LText: AnsiString;
  LKey: AnsiString;
begin
  LList := TList<AnsiString>.Create;
  LSeen := TDictionary<AnsiString, Boolean>.Create;
  try
    for LDictionary := 0 to High(ADictionaries) do
      for LIndex := 0 to ADictionaries[LDictionary].GetNumKeyVals - 1 do
      begin
        ADictionaries[LDictionary].TryGetKeyVal(LIndex, LPair);
        if AKeys then
          LText := LPair.Key
        else
          LText := LPair.Value;
        // the key pool is case insensitive: the lookup key is the lower case text
        if AKeys then
          LKey := AsciiLower(LText)
        else
          LKey := LText;
        if not LSeen.ContainsKey(LKey) then
        begin
          LSeen.Add(LKey, True);
          LList.Add(LText);
        end;
      end;
    Result := LList.ToArray;
  finally
    LSeen.Free;
    LList.Free;
  end;
end;

procedure TIdDictLister.Print(const AStrings: TArray<AnsiString>; const ACountFormat: string);
var
  LIndex: Integer;
begin
  if not Assigned(FLog) then
    Exit;
  for LIndex := 0 to High(AStrings) do
    FLog.Printf(string(AStrings[LIndex]) + #10);
  FLog.Printf(Format(ACountFormat, [Length(AStrings)]) + #10);
end;

procedure TIdDictLister.ListKeys(const ADictionaries: array of TIdDict);
var
  LStrings: TArray<AnsiString>;
begin
  LStrings := Distinct(ADictionaries, True);
  SortWithoutCase(LStrings);
  Print(LStrings, '%5d keys');
end;

procedure TIdDictLister.ListValues(const ADictionaries: array of TIdDict);
var
  LStrings: TArray<AnsiString>;
begin
  LStrings := Distinct(ADictionaries, False);
  SortWithoutCase(LStrings);
  Print(LStrings, '%5d values');
end;

end.
