{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the WEAPON definitions                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.WeaponReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf, DelphiDoom.ActorDef.StateOwner, DelphiDoom.ActorDef.StateReader,
  DelphiDoom.ActorDef.FlagReader;

type
  /// <summary>
  ///   Reads a WEAPON: the number (or the name) of the weapon, its ammo, the flags, and the states
  ///   up, down, ready, attack, hold and flash
  /// </summary>
  TActorDefWeaponReader = class
  private
    FScanner: TScriptScanner;
    FLog: ILog;
    FProfile: TActorDefProfile;
    FFlags: TActorDefFlagReader;
    FNames: IActorDefNameCatalog;
    FStates: TActorDefStateReader;
    FSink: IActorDefDefinitionSink;
    FOwner: IActorDefStateOwner;
    FWeapon: TActorDefWeapon;
    FPending: Boolean;
    procedure Warn(const AMessage: string);
    function IsDefinitionKeyword(const AToken: string): Boolean;
    procedure ReadStates;
  public
    constructor Create(AScanner: TScriptScanner; const ALog: ILog; const AProfile: TActorDefProfile;
      AFlags: TActorDefFlagReader; const ANames: IActorDefNameCatalog; AStates: TActorDefStateReader;
      const ASink: IActorDefDefinitionSink);
    /// <summary>WEAPON is the current word. False if the text ended while reading the head</summary>
    function Read: Boolean;
    /// <summary>The weapon is over: it goes to the sink (nothing happens if there is none)</summary>
    procedure Submit;
    property Pending: Boolean read FPending;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.Text, DelphiDoom.ActorDef.WeaponStateOwner;

{ TActorDefWeaponReader }

constructor TActorDefWeaponReader.Create(AScanner: TScriptScanner; const ALog: ILog;
  const AProfile: TActorDefProfile; AFlags: TActorDefFlagReader; const ANames: IActorDefNameCatalog;
  AStates: TActorDefStateReader; const ASink: IActorDefDefinitionSink);
begin
  inherited Create;
  FScanner := AScanner;
  FLog := ALog;
  FProfile := AProfile;
  FFlags := AFlags;
  FNames := ANames;
  FStates := AStates;
  FSink := ASink;
  FOwner := TActorDefWeaponStateOwner.Create(@FWeapon);
end;

procedure TActorDefWeaponReader.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TActorDefWeaponReader.IsDefinitionKeyword(const AToken: string): Boolean;
begin
  Result := (AToken = 'ACTOR') or
    (AToken = 'WEAPON') or
    (AToken = 'ACTORALIAS') or
    (AToken = 'DEH_PARSE') or
    (AToken = 'DEH_PARSE_ALL') or
    (AToken = 'COMPILED') or
    (AToken = 'PRECOMPILED') or
    (AToken = 'EXTERNAL') or
    (AToken = 'SCRIPT') or
    (AToken = 'THINKER') or
    (AToken = 'GLOBAL');
end;

function TActorDefWeaponReader.Read: Boolean;
var
  LToken: string;
  LFoundStates: Boolean;
  LText: string;
begin
  Result := True;
  FPending := True;
  FWeapon := Default(TActorDefWeapon);
  FWeapon.WeaponNo := -1;
  FWeapon.Level := FProfile.WeaponDefaultLevel;
  FWeapon.UpState := -1;
  FWeapon.DownState := -1;
  FWeapon.ReadyState := -1;
  FWeapon.AttackState := -1;
  FWeapon.HoldAttackState := -1;
  FWeapon.FlashState := -1;
  FWeapon.Flags := '';
  // the states of the thing before are not the ones of this weapon if the text ends in its head
  FStates.Start(FOwner);

  if not FScanner.GetString then
    Exit(False);
  if TActorDefText.IsInteger(FScanner.AsString) then
    FWeapon.WeaponNo := TScannerStrings.ToInteger(FScanner.AsString)
  else
  begin
    FWeapon.WeaponNo := FNames.WeaponType(FScanner.AsString);
    if FWeapon.WeaponNo < 0 then
      FScanner.UnGet;
  end;

  FScanner.GetString;

  LFoundStates := False;
  repeat
    if FScanner.MatchString('ammo') or
      (FProfile.WeaponHasPlayerClass and FScanner.MatchString('mana')) then
    begin
      FScanner.GetString;
      FWeapon.Ammo := FNames.AmmoType(FScanner.AsString);
      FScanner.GetString;
    end
    else if FProfile.WeaponHasLevel and FScanner.MatchString('level') then
    begin
      FScanner.GetString;
      if TScannerStrings.UpperAscii(FScanner.AsString) = 'LEVEL1' then
        FWeapon.Level := 1
      else if TScannerStrings.UpperAscii(FScanner.AsString) = 'LEVEL2' then
        FWeapon.Level := 2
      else
        FWeapon.Level := TScannerStrings.ToInteger(FScanner.AsString);
      FScanner.GetString;
    end
    else if FProfile.WeaponHasPlayerClass and
      (FScanner.MatchString('class') or FScanner.MatchString('playerclass')) then
    begin
      FScanner.GetString;
      FWeapon.PlayerClass := FNames.PlayerClass(FScanner.AsString);
      FScanner.GetString;
    end
    else if FScanner.MatchString('ammopershot') then
    begin
      FScanner.MustGetInteger;
      FWeapon.AmmoPerShot := FScanner.AsInteger;
      FScanner.GetString;
    end
    else if FFlags.TryAddWeapon(FWeapon.Flags) then
      FScanner.GetString
    else if FFlags.TryRemoveWeapon(FWeapon.Flags) then
      FScanner.GetString
    else if FScanner.MatchString('states') then
      LFoundStates := True
    else
    begin
      LToken := TScannerStrings.UpperAscii(FScanner.AsString);
      if IsDefinitionKeyword(LToken) then
      begin
        FScanner.UnGet;
        Break;
      end
      else
      begin
        if FWeapon.WeaponNo >= 0 then
          LText := ' while parsing weapon "' + IntToStr(FWeapon.WeaponNo) + '"'
        else
          LText := '';
        Warn(Format('SC_ActordefToDEH(): Unknown token "%s" found%s'#13#10,
          [FScanner.AsString, LText]));
        FScanner.GetString;
      end;
    end;
  until LFoundStates or FScanner.Finished;

  ReadStates;
end;

procedure TActorDefWeaponReader.ReadStates;
var
  LToken: string;
begin
  FStates.Start(FOwner);
  while FScanner.GetString do
  begin
    LToken := TScannerStrings.UpperAscii(FScanner.AsString);
    if IsDefinitionKeyword(LToken) then
    begin
      FScanner.UnGet;
      Break;
    end;
    if FScanner.MatchString('up:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_UP;
      FWeapon.UpState := FStates.Count;
      repeat until not FStates.Read(FWeapon.UpState);
    end
    else if FScanner.MatchString('down:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_DOWN;
      FWeapon.DownState := FStates.Count;
      repeat until not FStates.Read(FWeapon.DownState);
    end
    else if FScanner.MatchString('ready:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_READY;
      FWeapon.ReadyState := FStates.Count;
      repeat until not FStates.Read(FWeapon.ReadyState);
    end
    else if FScanner.MatchString('attack:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_ATTACK;
      FWeapon.AttackState := FStates.Count;
      repeat until not FStates.Read(FWeapon.AttackState);
    end
    else if FScanner.MatchString('hold:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_HOLDATTACK;
      FWeapon.HoldAttackState := FStates.Count;
      repeat until not FStates.Read(FWeapon.HoldAttackState);
    end
    else if FScanner.MatchString('flash:') then
    begin
      FWeapon.StatesDefined := FWeapon.StatesDefined or ACTORDEF_WT_FLASH;
      FWeapon.FlashState := FStates.Count;
      repeat until not FStates.Read(FWeapon.FlashState);
    end;
  end;
end;

procedure TActorDefWeaponReader.Submit;
begin
  if not FPending then
    Exit;
  FPending := False;
  FStates.CloseLastState;
  FWeapon.States := FStates.States;
  if Assigned(FSink) then
    FSink.SubmitWeapon(FWeapon);
end;

end.
