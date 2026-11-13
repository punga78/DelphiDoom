{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the states that the scripts name          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.StateNames;

interface

uses
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types;

type
  /// <summary>
  ///   The state that a name written in a script stands for, as an action of an actor asks for it
  ///   (the old P_GetStateFromName and P_GetStateFromNameWithOffsetCheck): a name of the table,
  ///   a name of a thing's own states ("SPAWN", "SUPER::SEE", "SELF::DEATH"), a number, or
  ///   one of them with an offset ("SPAWN + 2")
  /// </summary>
  TInfoStateNames = class sealed
  strict private
    FTokens: IInfoStateTokens;
    FMobjs: IInfoMobjSource;
    FLookup: IInfoThingNames;
    FText: IInfoStateText;
    function ByLabel(const AMobj: TInfoMobj; const ALabel: string; out AState: Integer): Boolean;
    function IndexOfName(const AActor: TInfoMobj; const AName, AOriginal: string): Integer;
  public
    /// <summary>ALookup finds the things named in "THING::LABEL"</summary>
    constructor Create(const ATokens: IInfoStateTokens; const AMobjs: IInfoMobjSource;
      const ALookup: IInfoThingNames; const AText: IInfoStateText);
    /// <summary>
    ///   The state of the text for the actor, whose thing is AActor; -1 if there is none. The
    ///   text goes through AText first (RANDOMPICK, RANDOM). A "+" or "-" with a number moves the
    ///   state by that many places
    /// </summary>
    function StateFromName(const AActor: TInfoMobj; const AText: string): Integer;
    /// <summary>
    ///   As StateFromName, but a text that is only a number, with or without a sign, is an
    ///   offset from ACurrentState (the state the actor is in); an empty text is state 0
    /// </summary>
    function StateFromNameWithOffset(const AActor: TInfoMobj; const ACurrentState: Integer;
      const AText: string): Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TInfoStateNames }

constructor TInfoStateNames.Create(const ATokens: IInfoStateTokens; const AMobjs: IInfoMobjSource;
  const ALookup: IInfoThingNames; const AText: IInfoStateText);
begin
  inherited Create;
  if not Assigned(ATokens) then
    raise EArgumentNilException.Create('ATokens');
  if not Assigned(AMobjs) then
    raise EArgumentNilException.Create('AMobjs');
  if not Assigned(ALookup) then
    raise EArgumentNilException.Create('ALookup');
  if not Assigned(AText) then
    raise EArgumentNilException.Create('AText');
  FTokens := ATokens;
  FMobjs := AMobjs;
  FLookup := ALookup;
  FText := AText;
end;

function TInfoStateNames.ByLabel(const AMobj: TInfoMobj; const ALabel: string; out AState: Integer): Boolean;
begin
  Result := True;
  if ALabel = 'SPAWN' then
    AState := AMobj.SpawnState
  else if ALabel = 'SEE' then
    AState := AMobj.SeeState
  else if ALabel = 'MELEE' then
    AState := AMobj.MeleeState
  else if ALabel = 'MISSILE' then
    AState := AMobj.MissileState
  else if ALabel = 'PAIN' then
    AState := AMobj.PainState
  else if ALabel = 'DEATH' then
    AState := AMobj.DeathState
  else if ALabel = 'XDEATH' then
    AState := AMobj.XDeathState
  else if ALabel = 'RAISE' then
    AState := AMobj.RaiseState
  else if ALabel = 'CRASH' then
    AState := AMobj.CrashState
  else if ALabel = 'CRUSH' then
    AState := AMobj.CrushState
  else if ALabel = 'INTERACT' then
    AState := AMobj.InteractState
  else
  begin
    AState := 0;
    Result := False;
  end;
end;

// A name without an offset: the table, then THING::LABEL or a label of the actor's own thing,
// then the name of the table made of the thing and the label (S_THING_LABEL), then a number
function TInfoStateNames.IndexOfName(const AActor: TInfoMobj; const AName, AOriginal: string): Integer;
var
  LLabel: string;
  LThing: string;
  LPosition: Integer;
  LIndex: Integer;
  LOwner: TInfoMobj;
  LHasOwner: Boolean;
begin
  LOwner := Default(TInfoMobj);
  Result := FTokens.IndexOfToken(AName);
  if Result >= 0 then
    Exit;

  LLabel := TScannerStrings.UpperAscii(AName);

  LPosition := Pos('::', LLabel);
  if LPosition < 2 then
  begin
    // "::spawn" is allowed
    LOwner := AActor;
    LHasOwner := True;
  end
  else
  begin
    LThing := TScannerStrings.Trim(Copy(LLabel, 1, LPosition - 1));
    // The label loses its last two characters: kept as the old code had it
    LLabel := Copy(LLabel, LPosition + 2, Length(LLabel) - LPosition - 3);
    if LThing = 'SUPER' then
      LIndex := AActor.InheritsFrom
    else
      LIndex := FLookup.NumForName(LThing);
    LHasOwner := (LIndex >= 0) and (LIndex < FMobjs.Count);
    if LHasOwner then
      LOwner := FMobjs.Get(LIndex)
    else if LThing = 'SELF' then
    begin
      LOwner := AActor;
      LHasOwner := True;
    end;
  end;

  if LHasOwner then
    if ByLabel(LOwner, LLabel, Result) then
      Exit;

  Result := FTokens.IndexOfToken('S_' + TScannerStrings.UpperAscii(AActor.Name) + '_' + AName);
  if Result < 0 then
    if TScannerStrings.IsDigits(AOriginal) then
      Result := TScannerStrings.ToInteger(AOriginal);
end;

function TInfoStateNames.StateFromName(const AActor: TInfoMobj; const AText: string): Integer;
var
  LText: string;
  LUpper: string;
  LFirst: string;
  LSecond: string;
begin
  LText := FText.Evaluate(AText);
  LUpper := TScannerStrings.UpperAscii(TScannerStrings.Trim(LText));
  if (Pos('+', LUpper) = 0) and (Pos('-', LUpper) = 0) and (Pos(' ', LUpper) = 0) then
    Exit(IndexOfName(AActor, LUpper, AText));

  LUpper := LUpper.Replace(' ', '');
  if Pos('+', LUpper) > 0 then
  begin
    TScannerStrings.SplitAtFirst(LUpper, LFirst, LSecond, '+');
    Exit(IndexOfName(AActor, LFirst, AText) + TScannerStrings.ToInteger(LSecond, 0));
  end;
  if Pos('-', LUpper) > 0 then
  begin
    TScannerStrings.SplitAtFirst(LUpper, LFirst, LSecond, '-');
    Exit(IndexOfName(AActor, LFirst, AText) - TScannerStrings.ToInteger(LSecond, 0));
  end;
  Result := -1;
end;

function TInfoStateNames.StateFromNameWithOffset(const AActor: TInfoMobj; const ACurrentState: Integer;
  const AText: string): Integer;
var
  LText: string;
  LCheck: string;
begin
  LText := FText.Evaluate(AText);
  LCheck := LText;
  if LCheck = '' then
    Exit(0);

  if (LCheck[1] = '-') or (LCheck[1] = '+') then
    Delete(LCheck, 1, 1);

  if TScannerStrings.IsDigits(LCheck) then
    Result := ACurrentState + TScannerStrings.ToInteger(LText)
  else
    Result := StateFromName(AActor, LText);
end;

end.
