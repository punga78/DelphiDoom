{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the hint with the parameters of a function        }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ParameterHints;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Ide.Types;

type
  /// <summary>
  ///   The functions a script can call with the parameters they expect, for the hint that opens
  ///   when the user types "(" after a function name, and the search for the function the caret
  ///   is in the brackets of
  /// </summary>
  TIdeParameterHints = class
  strict private
    FHints: TStringList;
    function BuildParameters(const ADeclaration: string): string;
    function Cleaned(const ADeclaration: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Makes the list from the functions of the units and, for an actor definition, from the
    ///   functions of the actors. An actor function is known with and without its "A_" prefix.
    ///   Names are in upper case; two declarations with the same name give two entries
    /// </summary>
    procedure Rebuild(const AUnits: TArray<TIdeUnitDeclarations>;
      const AActorDefFunctions: TArray<string>);
    /// <summary>The parameters of a function (the name is searched without regard to the case)</summary>
    function TryGetParameters(const AFunctionName: string; out AParameters: string): Boolean;
    /// <summary>
    ///   Looks backwards from the caret for the "(" that is still open and the name before it that
    ///   the list knows, jumping over the brackets that are closed. The index is how many commas
    ///   were passed on the way: the parameter the caret is in. The caret is one based, as in
    ///   the editor
    /// </summary>
    function TryFindCall(const ALineText: string; const ACaretX: Integer;
      const AIsIdentChar: TFunc<Char, Boolean>; out AFunctionName: string;
      out AParameterIndex: Integer; out AParameters: string): Boolean;
    function Count: Integer;
  end;

implementation

uses
  DelphiDoom.Ide.Text;

const
  NO_PARAMETERS = '** No parameters expected';

type
  /// <summary>The parameters of one function, owned by the list</summary>
  TIdeHintText = class
  public
    Text: string;
    constructor Create(const AText: string);
  end;

constructor TIdeHintText.Create(const AText: string);
begin
  inherited Create;
  Text := AText;
end;

{ TIdeParameterHints }

constructor TIdeParameterHints.Create;
begin
  inherited Create;
  FHints := TStringList.Create;
  FHints.OwnsObjects := True;
end;

destructor TIdeParameterHints.Destroy;
begin
  FHints.Free;
  inherited Destroy;
end;

function TIdeParameterHints.Cleaned(const ADeclaration: string): string;
var
  LIndex: Integer;
begin
  Result := ADeclaration;
  for LIndex := 1 to Length(Result) do
    if CharInSet(Result[LIndex], ['(', ';', ':']) then
      Result[LIndex] := ' ';
end;

function TIdeParameterHints.BuildParameters(const ADeclaration: string): string;
var
  LOpen, LClose: Integer;
begin
  Result := '';
  LOpen := Pos('(', ADeclaration);
  LClose := Pos(')', ADeclaration);
  if (LOpen > 1) and (LClose > LOpen) then
  begin
    Result := '"' + Trim(Copy(ADeclaration, LOpen + 1, LClose - LOpen - 1)) + '"';
    if Result = '""' then
      Result := ''
    else
    begin
      Result := StringReplace(Result, ',', ',","', [rfReplaceAll]);
      Result := StringReplace(Result, ';', ',","', [rfReplaceAll]);
    end;
  end;
  if Result = '' then
    Result := NO_PARAMETERS;
end;

procedure TIdeParameterHints.Rebuild(const AUnits: TArray<TIdeUnitDeclarations>;
  const AActorDefFunctions: TArray<string>);
var
  LUnit: TIdeUnitDeclarations;
  LDeclaration, LParameters, LName: string;
begin
  FHints.Sorted := False;
  FHints.Clear;
  for LUnit in AUnits do
    for LDeclaration in LUnit.Declarations do
      FHints.AddObject(
        UpperCase(TIdeText.FirstWord(TIdeText.SecondWord(Cleaned(LDeclaration), ' '), ' ')),
        TIdeHintText.Create(BuildParameters(LDeclaration)));
  for LDeclaration in AActorDefFunctions do
  begin
    LParameters := BuildParameters(LDeclaration);
    LName := Trim(UpperCase(TIdeText.FirstWord(Cleaned(LDeclaration), ' ')));
    if LName <> '' then
    begin
      FHints.AddObject(LName, TIdeHintText.Create(LParameters));
      if Pos('A_', LName) = 1 then
      begin
        LName := Trim(Copy(LName, 3, MaxInt));
        if LName <> '' then
          FHints.AddObject(LName, TIdeHintText.Create(LParameters));
      end;
    end;
  end;
  FHints.Sorted := True;
end;

function TIdeParameterHints.TryGetParameters(const AFunctionName: string;
  out AParameters: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FHints.IndexOf(UpperCase(AFunctionName));
  Result := LIndex >= 0;
  if Result then
    AParameters := (FHints.Objects[LIndex] as TIdeHintText).Text
  else
    AParameters := '';
end;

function TIdeParameterHints.TryFindCall(const ALineText: string; const ACaretX: Integer;
  const AIsIdentChar: TFunc<Char, Boolean>; out AFunctionName: string;
  out AParameterIndex: Integer; out AParameters: string): Boolean;
var
  LPosition, LStart, LSaved, LDepth: Integer;
begin
  AFunctionName := '';
  AParameters := '';
  AParameterIndex := 0;
  Result := False;
  LPosition := ACaretX;
  if LPosition > Length(ALineText) then
    LPosition := Length(ALineText)
  else
    Dec(LPosition);
  while (LPosition > 0) and not Result do
  begin
    if ALineText[LPosition] = ',' then
    begin
      Inc(AParameterIndex);
      Dec(LPosition);
    end
    else if ALineText[LPosition] = ')' then
    begin
      // a closed bracket: jump to the one that opened it
      LDepth := 1;
      Dec(LPosition);
      while (LPosition > 0) and (LDepth > 0) do
      begin
        if ALineText[LPosition] = ')' then
          Inc(LDepth)
        else if ALineText[LPosition] = '(' then
          Dec(LDepth);
        Dec(LPosition);
      end;
      if LPosition > 0 then
        Dec(LPosition);
    end
    else if ALineText[LPosition] = '(' then
    begin
      LStart := LPosition;
      while (LPosition > 0) and not AIsIdentChar(ALineText[LPosition]) do
        Dec(LPosition);
      if LPosition > 0 then
      begin
        LSaved := LPosition;
        while (LPosition > 0) and AIsIdentChar(ALineText[LPosition]) do
          Dec(LPosition);
        Inc(LPosition);
        AFunctionName := UpperCase(Copy(ALineText, LPosition, LSaved - LPosition + 1));
        Result := TryGetParameters(AFunctionName, AParameters);
        if not Result then
        begin
          LPosition := LStart;
          Dec(LPosition);
        end;
      end;
    end
    else
      Dec(LPosition);
  end;
  if not Result then
    AParameters := '';
end;

function TIdeParameterHints.Count: Integer;
begin
  Result := FHints.Count;
end;

end.
