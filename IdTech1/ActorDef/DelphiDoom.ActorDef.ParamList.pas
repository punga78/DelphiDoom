{******************************************************************************}
{                                                                              }
{  DelphiDoom: actor definition library - the parameters of an action          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Integer products of the 16.16 fixed point numbers wrap around as in the old code
{$Q-}
{$R-}
unit DelphiDoom.ActorDef.ParamList;

interface

uses
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.Scanner.ContextEvaluator.Intf;

type
  /// <summary>
  ///   The parameters of an action as a state declares them, "(1, 2, RANDOM 3 4, x + 5)":
  ///   the declaration is cut into parameters when the list is made, and every parameter is
  ///   read as an integer, a float, a fixed point number, a boolean or a text when the action
  ///   asks for it (the old TCustomParamList of sc_params)
  /// </summary>
  TActorDefParamList = class sealed
  strict private
    type
      TEntry = record
        Text: string;
        IntValue: Integer;
        IntFirst: Integer;
        IntSecond: Integer;
        FloatValue: Single;
        FloatFirst: Single;
        FloatSecond: Single;
        FixedValue: Integer;
        Kind: TActorDefParamKind;
        Computed: Boolean;
        FloatText: Boolean;
      end;
    const
      FracUnit = 65536;
    var
      FEntries: TArray<TEntry>;
      FDeclaration: string;
      FEvaluator: IContextExpressionEvaluator;
      FRandom: IActorDefParamRandom;
      FContext: Pointer;
    function IsValid(const AIndex: Integer): Boolean;
    function EvaluateText(const AIndex: Integer): string;
    procedure AddNumber(const AText: string);
    procedure AddRandom(const ARest: string);
    procedure AddFloatRandom(const ARest: string);
    procedure ReadDeclaration;
  public
    /// <summary>
    ///   ADeclaration is the text between the parentheses of the state. AEvaluator computes the
    ///   expressions and says which names are functions without arguments; it must be given
    ///   to read anything that is not a plain number. ARandom gives the numbers of RANDOM
    ///   and FRANDOM and may be nil for a list that has none
    /// </summary>
    constructor Create(const ADeclaration: string; const AEvaluator: IContextExpressionEvaluator;
      const ARandom: IActorDefParamRandom);
    /// <summary>
    ///   Adds a parameter. A number (apkNumber) is read at once; RANDOM, FRANDOM and EVAL
    ///   count as such only if the text starts with that word and a space; any other kind
    ///   is an expression
    /// </summary>
    procedure AddParam(const AKind: TActorDefParamKind; const AValue: string);
    /// <summary>How many parameters there are</summary>
    function Count: Integer;
    /// <summary>True if the parameter is a number that is known without an actor</summary>
    function IsComputed(const AIndex: Integer): Boolean;
    function GetInteger(const AIndex: Integer): Integer;
    procedure SetInteger(const AIndex: Integer; const AValue: Integer);
    function GetFloat(const AIndex: Integer): Single;
    procedure SetFloat(const AIndex: Integer; const AValue: Single);
    function GetFixed(const AIndex: Integer): Integer;
    /// <summary>A parameter written as a decimal number is read as fixed point, an integer one is not scaled</summary>
    function GetMBF21Fixed(const AIndex: Integer): Integer;
    function GetBool(const AIndex: Integer): Boolean;
    function GetString(const AIndex: Integer): string;
    function GetEvaluatedString(const AIndex: Integer): string;
    /// <summary>The text the list was made from</summary>
    property Declaration: string read FDeclaration;
    /// <summary>The actor the expressions are computed on (opaque to the library)</summary>
    property Context: Pointer read FContext write FContext;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ActorDef.ParamText,
  DelphiDoom.Scanner.Numbers,
  DelphiDoom.Scanner.Strings,
  DelphiDoom.Scanner.Text;

const
  RandomWord = 'RANDOM';
  FloatRandomWord = 'FRANDOM';
  FloatRandomLongWord = 'FLOATRANDOM';
  EvalWord = 'EVAL';
  // the names that read a map or world variable or a custom parameter: they were
  // never implemented as kinds of their own, they are expressions of the evaluator
  MappedWords: array[0..9] of string = (
    'MAPSTR', 'WORLDSTR', 'MAPINT', 'WORLDINT', 'MAPFLOAT', 'WORLDFLOAT',
    'CUSTOMPARAM', 'TARGETCUSTOMPARAM', 'MASTERCUSTOMPARAM', 'TRACERCUSTOMPARAM');

function WordAt(const AWords: TArray<string>; const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Length(AWords)) then
    Result := AWords[AIndex]
  else
    Result := '';
end;

function IsMappedWord(const AWord: string): Boolean;
var
  LName: string;
begin
  for LName in MappedWords do
    if LName = AWord then
      Exit(True);
  Result := False;
end;

{ TActorDefParamList }

constructor TActorDefParamList.Create(const ADeclaration: string;
  const AEvaluator: IContextExpressionEvaluator; const ARandom: IActorDefParamRandom);
begin
  inherited Create;
  FDeclaration := ADeclaration;
  FEvaluator := AEvaluator;
  FRandom := ARandom;
  ReadDeclaration;
end;

procedure TActorDefParamList.ReadDeclaration;
var
  LParams: TArray<string>;
  LWords: TArray<string>;
  LParam: string;
  LUpper: string;
  LIndex: Integer;
  LAllNumbers: Boolean;
begin
  LParams := TScannerText.ParamsToList(FDeclaration);
  for LParam in LParams do
  begin
    if TActorDefParamText.IsInteger(LParam) then
      AddParam(apkNumber, LParam)
    else if TActorDefParamText.IsFloat(LParam) then
      AddParam(apkNumber, LParam)
    else if TScannerText.IsStringInQuotes(LParam) then
      AddParam(apkNumber, Copy(LParam, 2, Length(LParam) - 2))
    else
    begin
      LWords := TActorDefParamText.WordsToList(LParam, [' ', #13, #10, #9, #7, '(', ',', ')', '[', ']']);
      if Length(LWords) = 0 then
        Continue;
      LUpper := TScannerStrings.UpperAscii(LWords[0]);
      if LUpper = RandomWord then
      begin
        LAllNumbers := Length(LWords) <= 3;
        if LAllNumbers then
          for LIndex := 1 to High(LWords) do
            LAllNumbers := LAllNumbers and TActorDefParamText.IsInteger(LWords[LIndex]);
        if LAllNumbers then
          AddParam(apkRandom, RandomWord + ' ' + WordAt(LWords, 1) + ' ' + WordAt(LWords, 2))
        else
          AddParam(apkEvaluate, LParam);
      end
      else if (LUpper = FloatRandomWord) or (LUpper = FloatRandomLongWord) then
      begin
        LAllNumbers := Length(LWords) <= 3;
        if LAllNumbers then
          for LIndex := 1 to High(LWords) do
            LAllNumbers := LAllNumbers and TActorDefParamText.IsFloat(LWords[LIndex]);
        if LAllNumbers then
          AddParam(apkFloatRandom, FloatRandomWord + ' ' + WordAt(LWords, 1) + ' ' + WordAt(LWords, 2))
        else
          AddParam(apkEvaluate, LParam);
      end
      else if LUpper = EvalWord then
        AddParam(apkForceEvaluate, LParam)
      else if IsMappedWord(LUpper) then
      begin
        if (Length(LWords) = 2) and TScannerText.IsStringInQuotes(LWords[1]) then
          AddParam(apkEvaluate, LUpper + ' ' + TActorDefParamText.RemoveQuotes(LWords[1]))
        else
          AddParam(apkEvaluate, LParam);
      end
      else if (Length(LWords) = 1) and not FEvaluator.IsSingleToken(LWords[0]) then
        AddParam(apkNumber, LWords[0])
      else
        AddParam(apkEvaluate, LParam);
    end;
  end;
end;

procedure TActorDefParamList.AddNumber(const AText: string);
var
  LEntry: TEntry;
  LInteger: Integer;
  LFloat: Single;
begin
  LEntry := Default(TEntry);
  LEntry.Kind := apkNumber;
  LEntry.Text := TActorDefParamText.ToShortText(AText);
  if TActorDefParamText.IsFloat(AText) and not TActorDefParamText.IsInteger(AText) then
    LEntry.FloatText := True;
  LInteger := TActorDefParamText.ToInteger(AText, 0);
  LEntry.IntValue := LInteger;
  LEntry.Computed := TScannerNumbers.IntToText(LInteger) = AText;
  if LEntry.Computed then
  begin
    LEntry.FloatValue := LInteger;
    LEntry.FixedValue := LInteger * FracUnit;
  end
  else
  begin
    LFloat := TActorDefParamText.ToFloat(AText, 0.0);
    LEntry.FloatValue := LFloat;
    LEntry.FixedValue := Round(LFloat * FracUnit);
    LEntry.Computed := TScannerNumbers.FloatToText(LInteger) = AText;
  end;
  FEntries := FEntries + [LEntry];
end;

procedure TActorDefParamList.AddRandom(const ARest: string);
var
  LEntry: TEntry;
  LFirst: string;
  LSecond: string;
begin
  LEntry := Default(TEntry);
  LEntry.Kind := apkRandom;
  if ARest = '' then
  begin
    LEntry.IntFirst := 0;
    LEntry.IntSecond := 255;
  end
  else
  begin
    TScannerStrings.SplitAtFirst(ARest, LFirst, LSecond);
    if LSecond = '' then
    begin
      LEntry.IntFirst := 0;
      LEntry.IntSecond := TActorDefParamText.ToInteger(LFirst, 255);
    end
    else
    begin
      LEntry.IntFirst := TActorDefParamText.ToInteger(LFirst, 0);
      LEntry.IntSecond := TActorDefParamText.ToInteger(LSecond, 255);
    end;
  end;
  FEntries := FEntries + [LEntry];
end;

procedure TActorDefParamList.AddFloatRandom(const ARest: string);
var
  LEntry: TEntry;
  LFirst: string;
  LSecond: string;
begin
  LEntry := Default(TEntry);
  LEntry.Kind := apkFloatRandom;
  if ARest = '' then
  begin
    LEntry.FloatFirst := 0;
    LEntry.FloatSecond := 255;
  end
  else
  begin
    TScannerStrings.SplitAtFirst(ARest, LFirst, LSecond);
    if LSecond = '' then
    begin
      LEntry.FloatFirst := 0;
      LEntry.FloatSecond := TActorDefParamText.ToFloat(LFirst, 255);
    end
    else
    begin
      LEntry.FloatFirst := TActorDefParamText.ToFloat(LFirst, 0);
      LEntry.FloatSecond := TActorDefParamText.ToFloat(LSecond, 255);
    end;
  end;
  FEntries := FEntries + [LEntry];
end;

procedure TActorDefParamList.AddParam(const AKind: TActorDefParamKind; const AValue: string);
var
  LWord: string;
  LRest: string;
  LEntry: TEntry;
begin
  TScannerStrings.SplitAtFirst(AValue, LWord, LRest);
  LWord := TScannerStrings.UpperAscii(LWord);
  if (AKind = apkRandom) and (LWord = RandomWord) then
    AddRandom(LRest)
  else if (AKind = apkFloatRandom) and ((LWord = FloatRandomWord) or (LWord = FloatRandomLongWord)) then
    AddFloatRandom(LRest)
  else if (AKind = apkForceEvaluate) and (LWord = EvalWord) then
  begin
    LEntry := Default(TEntry);
    LEntry.Kind := apkForceEvaluate;
    LEntry.Text := TActorDefParamText.ToShortText(AValue);
    FEntries := FEntries + [LEntry];
  end
  else if AKind = apkNumber then
    AddNumber(AValue)
  else
  begin
    LEntry := Default(TEntry);
    LEntry.Kind := apkEvaluate;
    LEntry.Text := TActorDefParamText.ToShortText(AValue);
    LEntry.FloatText := TActorDefParamText.IsFloat(AValue) and not TActorDefParamText.IsInteger(AValue);
    FEntries := FEntries + [LEntry];
  end;
end;

function TActorDefParamList.IsValid(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FEntries));
end;

function TActorDefParamList.EvaluateText(const AIndex: Integer): string;
begin
  Result := FEvaluator.Evaluate(FContext, FEntries[AIndex].Text);
end;

function TActorDefParamList.Count: Integer;
begin
  Result := Length(FEntries);
end;

function TActorDefParamList.IsComputed(const AIndex: Integer): Boolean;
begin
  Result := IsValid(AIndex) and FEntries[AIndex].Computed;
end;

function TActorDefParamList.GetInteger(const AIndex: Integer): Integer;
begin
  if not IsValid(AIndex) then
    Exit(0);
  case FEntries[AIndex].Kind of
    apkRandom:
      Result := FEntries[AIndex].IntFirst +
        (FRandom.Next * (FEntries[AIndex].IntSecond - FEntries[AIndex].IntFirst + 1)) div 256;
    apkFloatRandom:
      Result := Round(FEntries[AIndex].FloatFirst +
        (FRandom.Next * (FEntries[AIndex].FloatSecond - FEntries[AIndex].FloatFirst + 1)) / 256);
    apkEvaluate, apkForceEvaluate:
      Result := Round(TActorDefParamText.ToFloat(EvaluateText(AIndex), 0.0));
  else
    Result := FEntries[AIndex].IntValue;
  end;
end;

procedure TActorDefParamList.SetInteger(const AIndex: Integer; const AValue: Integer);
begin
  if not IsValid(AIndex) then
    Exit;
  FEntries[AIndex].IntValue := AValue;
  if FEntries[AIndex].Kind = apkNumber then
    FEntries[AIndex].Computed := True;
end;

function TActorDefParamList.GetFloat(const AIndex: Integer): Single;
begin
  if not IsValid(AIndex) then
    Exit(0.0);
  case FEntries[AIndex].Kind of
    apkRandom:
      Result := (FEntries[AIndex].IntFirst * FracUnit +
        FRandom.Next * (FEntries[AIndex].IntSecond - FEntries[AIndex].IntFirst + 1) * 256) / FracUnit;
    apkFloatRandom:
      Result := (FEntries[AIndex].FloatFirst * FracUnit +
        FRandom.Next * (FEntries[AIndex].FloatSecond - FEntries[AIndex].FloatFirst + 1) * 256) / FracUnit;
    apkEvaluate, apkForceEvaluate:
      Result := TActorDefParamText.ToFloat(EvaluateText(AIndex), 0.0);
  else
    Result := FEntries[AIndex].FloatValue;
  end;
end;

procedure TActorDefParamList.SetFloat(const AIndex: Integer; const AValue: Single);
begin
  if not IsValid(AIndex) then
    Exit;
  FEntries[AIndex].FloatValue := AValue;
  FEntries[AIndex].FixedValue := Round(AValue * FracUnit);
  if FEntries[AIndex].Kind = apkNumber then
    FEntries[AIndex].Computed := True;
end;

function TActorDefParamList.GetFixed(const AIndex: Integer): Integer;
begin
  if not IsValid(AIndex) then
    Exit(0);
  case FEntries[AIndex].Kind of
    apkRandom:
      Result := FEntries[AIndex].IntFirst * FracUnit +
        FRandom.Next * (FEntries[AIndex].IntSecond - FEntries[AIndex].IntFirst + 1) * 256;
    apkFloatRandom:
      Result := Round(FEntries[AIndex].FloatFirst * FracUnit +
        FRandom.Next * (FEntries[AIndex].FloatSecond - FEntries[AIndex].FloatFirst + 1) * 256);
    apkEvaluate, apkForceEvaluate:
      Result := Round(TActorDefParamText.ToFloat(EvaluateText(AIndex), 0.0) * FracUnit);
  else
    Result := FEntries[AIndex].FixedValue;
  end;
end;

function TActorDefParamList.GetMBF21Fixed(const AIndex: Integer): Integer;
begin
  if not IsValid(AIndex) then
    Exit(0);
  if FEntries[AIndex].FloatText then
    Result := Round(TActorDefParamText.ToFloat(FEntries[AIndex].Text, 0.0) * FracUnit)
  else
    Result := GetInteger(AIndex);
end;

function TActorDefParamList.GetBool(const AIndex: Integer): Boolean;
begin
  if not IsValid(AIndex) then
    Exit(False);
  Result := TScannerStrings.UpperAscii(TActorDefParamText.RemoveQuotes(EvaluateText(AIndex))) = 'TRUE';
end;

function TActorDefParamList.GetString(const AIndex: Integer): string;
begin
  if not IsValid(AIndex) then
    Exit('');
  if FEntries[AIndex].Kind = apkForceEvaluate then
    Result := TActorDefParamText.RemoveQuotes(EvaluateText(AIndex))
  else
    Result := TActorDefParamText.RemoveQuotes(FEntries[AIndex].Text);
end;

function TActorDefParamList.GetEvaluatedString(const AIndex: Integer): string;
begin
  if not IsValid(AIndex) then
    Exit('');
  if FEntries[AIndex].Kind in [apkEvaluate, apkForceEvaluate] then
    Result := TActorDefParamText.RemoveQuotes(EvaluateText(AIndex))
  else
    Result := TActorDefParamText.RemoveQuotes(FEntries[AIndex].Text);
end;

end.
