{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the tables as Pascal code                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.PascalWriter;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf, DelphiDoom.TableExport.Profile;

type
  /// <summary>
  ///   Writes mobjinfo[] and states[] as the Pascal code that builds them, to paste in
  ///   the tables of a game (info.pas): assignments, or the constants of a typed array
  /// </summary>
  TExportPascalWriter = class(TInterfacedObject, IExportPascalWriter)
  strict private
    FProfile: TExportProfile;
    FThings: IExportThingSource;
    FBuiltInThings: IExportThingSource;
    FStates: IExportStateSource;
    FEnums: IExportEnumNames;
    FFlags: IExportFlagNames;
    FLookups: IExportLookups;
    function EnumOrdinal(AKind: TExportEnum; const APrefix, ASuffix: string; AOrdinal: Integer;
      const AFallback: string; AUpper: Boolean): string;
    function StateOrd(AValue: Integer): string;
    function StateName(AValue: Integer): string;
    function SoundOrd(AValue: Integer): string;
    function FlagsText(AValue: Integer; ASet: TExportFlagSet): string;
    function FixedText(AValue: Integer): string;
    function ThingValue(const ALine: TExportPascalLine; const AThing: TExportThing): string;
    function StateValue(const ALine: TExportPascalLine; const AState: TExportState): string;
    function Range(AStart, AFinish, ACount: Integer; out AFirst, ALast: Integer): Boolean;
    function EnumHeader(AKind: TExportEnum; AIndex: Integer): string;
  public
    /// <param name="ABuiltInThings">The table that the game had before any patch; nil to use AThings</param>
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AProfile: TExportProfile; const AThings, ABuiltInThings: IExportThingSource;
      const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames;
      const ALookups: IExportLookups);
    function Things(AStart: Integer = 0; AFinish: Integer = -1): string;
    function ThingConstants(AStart: Integer = 0; AFinish: Integer = -1): string;
    function States(AStart: Integer = 0; AFinish: Integer = -1): string;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.TableExport.Text;

const
  RULE = '////////////////////////////////////////////////////////////////////////////////';
  EOL = #13#10;

{ TExportPascalWriter }

constructor TExportPascalWriter.Create(const AProfile: TExportProfile; const AThings,
  ABuiltInThings: IExportThingSource; const AStates: IExportStateSource; const AEnums: IExportEnumNames;
  const AFlags: IExportFlagNames; const ALookups: IExportLookups);
begin
  inherited Create;
  if not Assigned(AThings) then
    raise EArgumentNilException.Create('AThings');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AEnums) then
    raise EArgumentNilException.Create('AEnums');
  if not Assigned(AFlags) then
    raise EArgumentNilException.Create('AFlags');
  if not Assigned(ALookups) then
    raise EArgumentNilException.Create('ALookups');
  FProfile := AProfile;
  FThings := AThings;
  FBuiltInThings := ABuiltInThings;
  FStates := AStates;
  FEnums := AEnums;
  FFlags := AFlags;
  FLookups := ALookups;
end;

function TExportPascalWriter.EnumOrdinal(AKind: TExportEnum; const APrefix, ASuffix: string;
  AOrdinal: Integer; const AFallback: string; AUpper: Boolean): string;
var
  LName: string;
begin
  if AOrdinal >= FEnums.Count(AKind) then
    Exit(AFallback);
  LName := FEnums.Name(AKind, AOrdinal);
  if AUpper then
    LName := UpperCase(LName);
  Result := APrefix + LName + ASuffix;
end;

function TExportPascalWriter.StateOrd(AValue: Integer): string;
begin
  if AValue < 0 then
    Result := 'Ord(S_NULL)'
  else
    Result := EnumOrdinal(eeState, 'Ord(', ')', AValue, IntToStr(AValue), True);
end;

function TExportPascalWriter.StateName(AValue: Integer): string;
begin
  if AValue < 0 then
    Result := 'S_NULL'
  else
    Result := EnumOrdinal(eeState, '', '', AValue, 'statenum_t(' + IntToStr(AValue) + ')', True);
end;

function TExportPascalWriter.SoundOrd(AValue: Integer): string;
begin
  if AValue < 0 then
    Result := 'Ord(sfx_None)'
  else
    Result := EnumOrdinal(eeSound, 'Ord(', ')', AValue, IntToStr(AValue), False);
end;

function TExportPascalWriter.FlagsText(AValue: Integer; ASet: TExportFlagSet): string;
begin
  Result := TExportText.FlagList(AValue, FFlags.Names(ASet), ' or ');
  if Result = '' then
    Result := '0';
end;

function TExportPascalWriter.FixedText(AValue: Integer): string;
begin
  if Abs(AValue) < EXPORT_FRACUNIT then
    Result := IntToStr(AValue)
  else if AValue = EXPORT_FRACUNIT then
    Result := 'FRACUNIT'
  else if AValue = -EXPORT_FRACUNIT then
    Result := '-FRACUNIT'
  else if AValue mod EXPORT_FRACUNIT = 0 then
    Result := IntToStr(AValue div EXPORT_FRACUNIT) + ' * FRACUNIT'
  else
    Result := IntToStr(AValue);
end;

function TExportPascalWriter.ThingValue(const ALine: TExportPascalLine; const AThing: TExportThing): string;
var
  LNumber: Integer;
begin
  if ALine.Kind = pkText then
    Exit('''' + TExportText.PascalEscape(AThing.Texts[TExportThingText(ALine.Index)]) + '''');
  LNumber := AThing.Numbers[TExportThingField(ALine.Index)];
  case ALine.Kind of
    pkFixed:
      Result := FixedText(LNumber);
    pkState:
      Result := StateOrd(LNumber);
    pkSound:
      Result := SoundOrd(LNumber);
    pkFlags:
      Result := FlagsText(LNumber, ALine.FlagSet);
    pkGender:
      Result := EnumOrdinal(eeGender, '', '', Abs(LNumber) * Ord(LNumber > 0), 'gender_t(' + IntToStr(LNumber) + ')', False);
    pkRenderStyle:
      Result := EnumOrdinal(eeRenderStyle, '', '', Abs(LNumber) * Ord(LNumber > 0),
        'mobjrenderstyle_t(' + IntToStr(LNumber) + ')', False);
    pkGroup:
      Result := FLookups.GroupName(ALine.Group, LNumber);
    pkPushFactor:
      if LNumber = EXPORT_DEFAULT_PUSHFACTOR then
        Result := 'DEFPUSHFACTOR'
      else
        Result := IntToStr(LNumber);
    pkFriction:
      if LNumber = EXPORT_ORIGINAL_FRICTION then
        Result := 'ORIG_FRICTION'
      else
        Result := IntToStr(LNumber);
  else
    Result := IntToStr(LNumber);
  end;
end;

function TExportPascalWriter.StateValue(const ALine: TExportPascalLine; const AState: TExportState): string;
var
  LNumber: Integer;
begin
  if ALine.Kind = pkAction then
  begin
    if AState.ActionName = '' then
      Exit('nil');
    Result := '@A_' + TExportText.Capitalize(AState.ActionName);
    if Result = '@A_Null' then
      Result := 'nil';
    Exit;
  end;
  LNumber := AState.Numbers[TExportStateField(ALine.Index)];
  case ALine.Kind of
    pkSprite:
      if LNumber < 0 then
        Result := 'Ord(SPR_NULL)'
      else
        Result := EnumOrdinal(eeSprite, 'Ord(', ')', LNumber, IntToStr(LNumber), False);
    pkNextState:
      Result := StateName(LNumber);
    pkFlags:
      Result := FlagsText(LNumber, ALine.FlagSet);
  else
    Result := IntToStr(LNumber);
  end;
end;

function TExportPascalWriter.Range(AStart, AFinish, ACount: Integer; out AFirst, ALast: Integer): Boolean;
begin
  AFirst := AStart;
  if AFirst < 0 then
    AFirst := 0;
  if AFinish < 0 then
    ALast := ACount - 1
  else
    ALast := AFinish;
  Result := True;
end;

function TExportPascalWriter.EnumHeader(AKind: TExportEnum; AIndex: Integer): string;
begin
  if AIndex < FEnums.Count(AKind) then
    Result := '// ' + UpperCase(FEnums.Name(AKind, AIndex))
  else
    Result := '// #' + IntToStr(AIndex);
end;

function TExportPascalWriter.Things(AStart, AFinish: Integer): string;
var
  LFirst: Integer;
  LLast: Integer;
  LIndex: Integer;
  LName: string;
  LThing: TExportThing;
  LLine: TExportPascalLine;
  LText: string;

  procedure AddLn(const ALine: string);
  begin
    if ALine <> '' then
      LText := LText + '  ' + ALine + EOL
    else
      LText := LText + EOL;
  end;

begin
  LText := '';
  Range(AStart, AFinish, FThings.Count, LFirst, LLast);
  AddLn(RULE);
  AddLn('// mobjinfo');
  AddLn(RULE);
  AddLn('');
  for LIndex := LFirst to LLast do
  begin
    LThing := FThings.Get(LIndex);
    AddLn(RULE);
    AddLn(EnumHeader(eeMobj, LIndex));
    if LIndex < 0 then
      LName := '-1'
    else
      LName := EnumOrdinal(eeMobj, 'Ord(', ')', LIndex, IntToStr(LIndex), True);
    for LLine in FProfile.PascalThingLines do
      AddLn('mobjinfo[' + LName + '].' + LLine.Name + ' := ' + ThingValue(LLine, LThing) + ';');
    AddLn('');
  end;
  Result := LText;
end;

function TExportPascalWriter.ThingConstants(AStart, AFinish: Integer): string;
var
  LFirst: Integer;
  LLast: Integer;
  LIndex: Integer;
  LSource: IExportThingSource;
  LThing: TExportThing;
  LLine: TExportPascalLine;
  LText: string;
  LField: string;

  procedure AddLn(const ALine: string);
  begin
    if ALine <> '' then
      LText := LText + '  ' + ALine + EOL
    else
      LText := LText + EOL;
  end;

begin
  LText := '';
  Range(AStart, AFinish, FThings.Count, LFirst, LLast);
  if Assigned(FBuiltInThings) and (LFirst = 0) and (LLast = FEnums.Count(eeMobj) - 1) then
    LSource := FBuiltInThings
  else
    LSource := FThings;
  AddLn(RULE);
  AddLn('// mobjinfo');
  AddLn(RULE);
  AddLn('');
  AddLn('(');
  AddLn('');
  for LIndex := LFirst to LLast do
  begin
    LThing := LSource.Get(LIndex);
    AddLn(RULE);
    if LIndex < FEnums.Count(eeMobj) then
      AddLn(' ( // ' + UpperCase(FEnums.Name(eeMobj, LIndex)))
    else
      AddLn(' ( // #' + IntToStr(LIndex) + ' (' + EnumOrdinal(eeMobj, 'Ord(', ')', LIndex,
        IntToStr(LIndex), True) + ')');
    for LLine in FProfile.PascalThingLines do
    begin
      LField := '    ' + LLine.Name + ': ' + ThingValue(LLine, LThing) + ';';
      while Length(LField) < 79 do
        LField := LField + ' ';
      LText := LText + LField + ' // ' + LLine.Name + EOL;
    end;
    if LIndex = LLast then
      AddLn(' )')
    else
      AddLn(' ),');
    AddLn('');
  end;
  AddLn(')');
  Result := LText;
end;

function TExportPascalWriter.States(AStart, AFinish: Integer): string;
var
  LFirst: Integer;
  LLast: Integer;
  LIndex: Integer;
  LName: string;
  LState: TExportState;
  LLine: TExportPascalLine;
  LText: string;

  procedure AddLn(const ALine: string);
  begin
    if ALine <> '' then
      LText := LText + '  ' + ALine + EOL
    else
      LText := LText + EOL;
  end;

begin
  LText := '';
  Range(AStart, AFinish, FStates.Count, LFirst, LLast);
  AddLn(RULE);
  AddLn('// states');
  AddLn(RULE);
  AddLn('');
  for LIndex := LFirst to LLast do
  begin
    LState := FStates.Get(LIndex);
    AddLn(RULE);
    AddLn(EnumHeader(eeState, LIndex));
    LName := StateOrd(LIndex);
    for LLine in FProfile.PascalStateLines do
      AddLn('states[' + LName + '].' + LLine.Name + ' := ' + StateValue(LLine, LState) + ';');
    AddLn('');
  end;
  Result := LText;
end;

end.
