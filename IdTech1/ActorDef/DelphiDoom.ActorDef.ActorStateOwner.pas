{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the states of an actor                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.ActorStateOwner;

interface

uses
  DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.StateOwner;

type
  /// <summary>
  ///   The labels of an actor: spawn, see, melee, missile, pain, death, xdeath, raise, heal,
  ///   crash, interact and crush. The actor is the one that the reader is filling
  /// </summary>
  TActorDefActorStateOwner = class(TInterfacedObject, IActorDefStateOwner)
  private
    FActor: PActorDefActor;
  public
    constructor Create(AActor: PActorDefActor);
    function LabelTokens: TArray<string>;
    function AliasFor(const ALabel: string): string;
    function TryResolveLabel(const AGoto: string; out AState: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.LabelMatcher;

{ TActorDefActorStateOwner }

constructor TActorDefActorStateOwner.Create(AActor: PActorDefActor);
begin
  inherited Create;
  FActor := AActor;
end;

function TActorDefActorStateOwner.LabelTokens: TArray<string>;
begin
  Result := TArray<string>.Create('spawn:', 'see:', 'melee:', 'missile:', 'pain:', 'death:',
    'xdeath:', 'raise:', 'heal:', 'crash:', 'interact:', 'crush:');
end;

function TActorDefActorStateOwner.AliasFor(const ALabel: string): string;
begin
  Result := 'S_' + TScannerStrings.UpperAscii(FActor.Name + '_' + ALabel);
end;

function TActorDefActorStateOwner.TryResolveLabel(const AGoto: string; out AState: Integer): Boolean;
type
  TLabelEntry = record
    Name: string;
    Mask: Cardinal;
  end;
const
  LABELS: array[0..11] of TLabelEntry = (
    (Name: 'SPAWN'; Mask: ACTORDEF_ST_SPAWN),
    (Name: 'SEE'; Mask: ACTORDEF_ST_SEE),
    (Name: 'MELEE'; Mask: ACTORDEF_ST_MELEE),
    (Name: 'MISSILE'; Mask: ACTORDEF_ST_MISSILE),
    (Name: 'PAIN'; Mask: ACTORDEF_ST_PAIN),
    (Name: 'DEATH'; Mask: ACTORDEF_ST_DEATH),
    (Name: 'XDEATH'; Mask: ACTORDEF_ST_XDEATH),
    (Name: 'RAISE'; Mask: ACTORDEF_ST_RAISE),
    (Name: 'HEAL'; Mask: ACTORDEF_ST_HEAL),
    (Name: 'CRASH'; Mask: ACTORDEF_ST_CRASH),
    (Name: 'CRUSH'; Mask: ACTORDEF_ST_CRUSH),
    (Name: 'INTERACT'; Mask: ACTORDEF_ST_INTERACT)
  );
var
  LIndex: Integer;
  LOffset: Integer;
  LBase: Integer;
begin
  for LIndex := Low(LABELS) to High(LABELS) do
  begin
    if (FActor.StatesDefined and LABELS[LIndex].Mask) = 0 then
      Continue;
    if not TActorDefLabelMatcher.Match(AGoto, LABELS[LIndex].Name, LOffset) then
      Continue;
    case LIndex of
      0: LBase := FActor.SpawnState;
      1: LBase := FActor.SeeState;
      2: LBase := FActor.MeleeState;
      3: LBase := FActor.MissileState;
      4: LBase := FActor.PainState;
      5: LBase := FActor.DeathState;
      6: LBase := FActor.XDeathState;
      7: LBase := FActor.RaiseState;
      8: LBase := FActor.HealState;
      9: LBase := FActor.CrashState;
      10: LBase := FActor.CrushState;
    else
      LBase := FActor.InteractState;
    end;
    AState := LBase + LOffset;
    Exit(True);
  end;
  AState := 0;
  Result := False;
end;

end.
