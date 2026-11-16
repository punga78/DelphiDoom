{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the targets of a goto                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.GotoResolver;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   Turns the text of a goto that was not a label of the definition into the next frame of the
  ///   patch: a state of the engine (by name, or the label of another actor, SUPER:: or SELF::),
  ///   a state of the same definition (by the label that it has), with + or - and a number
  /// </summary>
  TActorDefGotoResolver = class
  private
    FActors: IActorDefActorCatalog;
    FStates: IActorDefStateCatalog;
    FLog: ILog;
    function ActorStateIndex(const AText: string; const AActor: TActorDefActor): Integer;
    function WeaponStateIndex(const AText: string; const AWeapon: TActorDefWeapon): Integer;
    function SaveAliasIndex(const AStates: TActorDefStates; const AUpper: string): Integer;
    function Describe(AState: Integer): string;
    function Resolve(const AGoto: string; AIsWeapon: Boolean; const AActor: TActorDefActor;
      const AWeapon: TActorDefWeapon): string;
  public
    constructor Create(const AActors: IActorDefActorCatalog; const AStates: IActorDefStateCatalog;
      const ALog: ILog);
    /// <summary>'NewFrame n' or 'OriginalFrame n'; a warning and 'OriginalFrame 0' if it is not known</summary>
    function ResolveForActor(const AGoto: string; const AActor: TActorDefActor): string;
    function ResolveForWeapon(const AGoto: string; const AWeapon: TActorDefWeapon): string;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.Text;

{ TActorDefGotoResolver }

constructor TActorDefGotoResolver.Create(const AActors: IActorDefActorCatalog;
  const AStates: IActorDefStateCatalog; const ALog: ILog);
begin
  inherited Create;
  FActors := AActors;
  FStates := AStates;
  FLog := ALog;
end;

function TActorDefGotoResolver.SaveAliasIndex(const AStates: TActorDefStates;
  const AUpper: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AStates) do
    if AUpper = TScannerStrings.Trim(TScannerStrings.UpperAscii(AStates[LIndex].SaveAlias)) then
      Exit(LIndex);
  Result := -1;
end;

function TActorDefGotoResolver.ActorStateIndex(const AText: string;
  const AActor: TActorDefActor): Integer;
var
  LUpper: string;
  LOwner: string;
  LPosition: Integer;
  LDoSelf: Boolean;
  LHasBase: Boolean;
  LBase: TActorDefActor;
  LIndex: Integer;
begin
  Result := FStates.IndexOfToken(AText);
  if Result >= 0 then
    Exit(ACTORDEF_ORIGINAL_STATE_MARKER + Result);

  LUpper := TScannerStrings.UpperAscii(AText);
  LDoSelf := False;
  LHasBase := False;

  LPosition := Pos('::', LUpper);
  if LPosition < 2 then // the old comment says that "goto ::spawn" is allowed: it is not
    LDoSelf := True
  else
  begin
    LOwner := TScannerStrings.Trim(Copy(LUpper, 1, LPosition - 1));
    LUpper := Copy(LUpper, LPosition + 2, Length(LUpper) - LPosition - 1);
    if LOwner = 'SUPER' then
      LHasBase := FActors.Find(AActor.InheritsFrom, LIndex, LBase)
    else if LOwner = 'SELF' then
      LDoSelf := True
    else
      LHasBase := FActors.Find(LOwner, LIndex, LBase);
  end;

  if LHasBase then
  begin
    // the labels of the actor of the engine; there is no HEAL here, as in the old code
    if LUpper = 'SPAWN' then
      Exit(LBase.SpawnState)
    else if LUpper = 'SEE' then
      Exit(LBase.SeeState)
    else if LUpper = 'MELEE' then
      Exit(LBase.MeleeState)
    else if LUpper = 'MISSILE' then
      Exit(LBase.MissileState)
    else if LUpper = 'PAIN' then
      Exit(LBase.PainState)
    else if LUpper = 'DEATH' then
      Exit(LBase.DeathState)
    else if LUpper = 'XDEATH' then
      Exit(LBase.XDeathState)
    else if LUpper = 'RAISE' then
      Exit(LBase.RaiseState)
    else if LUpper = 'CRASH' then
      Exit(LBase.CrashState)
    else if LUpper = 'CRUSH' then
      Exit(LBase.CrushState)
    else if LUpper = 'INTERACT' then
      Exit(LBase.InteractState)
    else
    begin
      Result := FStates.IndexOfToken('S_' + TScannerStrings.UpperAscii(LBase.Name) + '_' + AText);
      if Result >= 0 then
        Exit;
      Result := FStates.IndexOfToken('S_' + TActorDefText.RemoveSpaces(
        TScannerStrings.UpperAscii(LBase.Name)) + '_' + AText);
      if Result >= 0 then
        Exit;
    end;
  end;

  if LDoSelf then
  begin
    if LUpper = 'SPAWN' then
      Exit(AActor.SpawnState)
    else if LUpper = 'SEE' then
      Exit(AActor.SeeState)
    else if LUpper = 'MELEE' then
      Exit(AActor.MeleeState)
    else if LUpper = 'MISSILE' then
      Exit(AActor.MissileState)
    else if LUpper = 'PAIN' then
      Exit(AActor.PainState)
    else if LUpper = 'DEATH' then
      Exit(AActor.DeathState)
    else if LUpper = 'XDEATH' then
      Exit(AActor.XDeathState)
    else if LUpper = 'RAISE' then
      Exit(AActor.RaiseState)
    else if LUpper = 'CRASH' then
      Exit(AActor.CrashState)
    else if LUpper = 'CRUSH' then
      Exit(AActor.CrushState)
    else if LUpper = 'INTERACT' then
      Exit(AActor.InteractState)
    else
    begin
      Result := SaveAliasIndex(AActor.States, LUpper);
      if Result >= 0 then
        Exit;
    end;
  end;

  Result := FStates.IndexOfToken('S_' + TScannerStrings.UpperAscii(AActor.Name) + '_' + AText);
end;

function TActorDefGotoResolver.WeaponStateIndex(const AText: string;
  const AWeapon: TActorDefWeapon): Integer;
var
  LUpper: string;
begin
  Result := FStates.IndexOfToken(AText);
  if Result >= 0 then
    Exit(ACTORDEF_ORIGINAL_STATE_MARKER + Result);

  LUpper := TScannerStrings.UpperAscii(AText);
  if LUpper = 'UP' then
    Exit(AWeapon.UpState)
  else if LUpper = 'DOWN' then
    Exit(AWeapon.DownState)
  else if LUpper = 'READY' then
    Exit(AWeapon.ReadyState)
  else if LUpper = 'ATTACK' then
    Exit(AWeapon.AttackState)
  else if LUpper = 'HOLD' then
    Exit(AWeapon.HoldAttackState)
  else if LUpper = 'FLASH' then
    Exit(AWeapon.FlashState)
  else
  begin
    Result := SaveAliasIndex(AWeapon.States, LUpper);
    if Result >= 0 then
      Exit;
  end;

  Result := FStates.IndexOfToken('S_WEAPON' + IntToStr(AWeapon.WeaponNo) + '_' + AText);
end;

function TActorDefGotoResolver.Describe(AState: Integer): string;
begin
  if AState >= ACTORDEF_ORIGINAL_STATE_MARKER then
    Result := 'OriginalFrame ' + IntToStr(AState - ACTORDEF_ORIGINAL_STATE_MARKER)
  else
    Result := 'NewFrame ' + IntToStr(AState);
end;

function TActorDefGotoResolver.Resolve(const AGoto: string; AIsWeapon: Boolean;
  const AActor: TActorDefActor; const AWeapon: TActorDefWeapon): string;

  function StateIndex(const AText: string): Integer;
  begin
    if AIsWeapon then
      Result := WeaponStateIndex(AText, AWeapon)
    else
      Result := ActorStateIndex(AText, AActor);
  end;

var
  LText: string;
  LFirst: string;
  LSecond: string;
  LPlus: Integer;
  LMinus: Integer;
  LBlank: Integer;
  LResult: Integer;
begin
  LText := TScannerStrings.UpperAscii(TScannerStrings.Trim(AGoto));
  LPlus := Pos('+', LText);
  LMinus := Pos('-', LText);
  LBlank := Pos(' ', LText);
  LResult := -1;
  if (LBlank = 0) and (LMinus = 0) and (LPlus = 0) then
    LResult := StateIndex(LText)
  else
  // small expressions are evaluated (also with spaces)
  begin
    LText := TActorDefText.RemoveSpaces(LText);
    LPlus := Pos('+', LText);
    LMinus := Pos('-', LText);
    if LPlus > 0 then
    begin
      TScannerStrings.SplitAtFirst(LText, LFirst, LSecond, '+');
      LResult := StateIndex(LFirst) + TScannerStrings.ToInteger(LSecond);
    end
    else if LMinus > 0 then
    begin
      TScannerStrings.SplitAtFirst(LText, LFirst, LSecond, '-');
      LResult := StateIndex(LFirst) - TScannerStrings.ToInteger(LSecond);
    end;
  end;

  if LResult = -1 then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('SC_ActordefToDEH(): Unknown label "goto %s"'#13#10, [AGoto]));
    Result := 'OriginalFrame 0';
  end
  else
    Result := Describe(LResult);
end;

function TActorDefGotoResolver.ResolveForActor(const AGoto: string; const AActor: TActorDefActor): string;
var
  LNoWeapon: TActorDefWeapon;
begin
  LNoWeapon := Default(TActorDefWeapon);
  Result := Resolve(AGoto, False, AActor, LNoWeapon);
end;

function TActorDefGotoResolver.ResolveForWeapon(const AGoto: string; const AWeapon: TActorDefWeapon): string;
var
  LNoActor: TActorDefActor;
begin
  LNoActor := Default(TActorDefActor);
  Result := Resolve(AGoto, True, LNoActor, AWeapon);
end;

end.
