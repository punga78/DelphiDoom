{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the states of a weapon                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.WeaponStateOwner;

interface

uses
  DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.StateOwner;

type
  /// <summary>The labels of a weapon: up, down, ready, attack, hold and flash</summary>
  TActorDefWeaponStateOwner = class(TInterfacedObject, IActorDefStateOwner)
  private
    FWeapon: PActorDefWeapon;
  public
    constructor Create(AWeapon: PActorDefWeapon);
    function LabelTokens: TArray<string>;
    function AliasFor(const ALabel: string): string;
    function TryResolveLabel(const AGoto: string; out AState: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.LabelMatcher;

{ TActorDefWeaponStateOwner }

constructor TActorDefWeaponStateOwner.Create(AWeapon: PActorDefWeapon);
begin
  inherited Create;
  FWeapon := AWeapon;
end;

function TActorDefWeaponStateOwner.LabelTokens: TArray<string>;
begin
  Result := TArray<string>.Create('up:', 'down:', 'ready:', 'attack:', 'hold:', 'flash:');
end;

function TActorDefWeaponStateOwner.AliasFor(const ALabel: string): string;
begin
  Result := 'S_WEAPON' + IntToStr(FWeapon.WeaponNo) + '_' + TScannerStrings.UpperAscii(ALabel);
end;

function TActorDefWeaponStateOwner.TryResolveLabel(const AGoto: string; out AState: Integer): Boolean;
type
  TLabelEntry = record
    Name: string;
    Mask: Cardinal;
  end;
const
  LABELS: array[0..5] of TLabelEntry = (
    (Name: 'UP'; Mask: ACTORDEF_WT_UP),
    (Name: 'DOWN'; Mask: ACTORDEF_WT_DOWN),
    (Name: 'READY'; Mask: ACTORDEF_WT_READY),
    (Name: 'ATTACK'; Mask: ACTORDEF_WT_ATTACK),
    (Name: 'HOLD'; Mask: ACTORDEF_WT_HOLDATTACK),
    (Name: 'FLASH'; Mask: ACTORDEF_WT_FLASH)
  );
var
  LIndex: Integer;
  LOffset: Integer;
  LBase: Integer;
begin
  for LIndex := Low(LABELS) to High(LABELS) do
  begin
    if (FWeapon.StatesDefined and LABELS[LIndex].Mask) = 0 then
      Continue;
    if not TActorDefLabelMatcher.Match(AGoto, LABELS[LIndex].Name, LOffset) then
      Continue;
    case LIndex of
      0: LBase := FWeapon.UpState;
      1: LBase := FWeapon.DownState;
      2: LBase := FWeapon.ReadyState;
      3: LBase := FWeapon.AttackState;
      4: LBase := FWeapon.HoldAttackState;
    else
      LBase := FWeapon.FlashState;
    end;
    AState := LBase + LOffset;
    Exit(True);
  end;
  AState := 0;
  Result := False;
end;

end.
