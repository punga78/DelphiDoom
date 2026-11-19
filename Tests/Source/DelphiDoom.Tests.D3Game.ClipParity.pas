{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - parity of the clip with the  }
{  real C++ (idClip, idClipModel, idEntity::TouchTriggers) and the entity      }
{  classes that use it (triggers, doors, damage)                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.ClipParity;

interface

uses
  System.Classes, DUnitX.TestFramework, DelphiDoom.D3Game.Entity, DelphiDoom.Tests.D3Game.WorldRig,
  DelphiDoom.Tests.D3Game.ClipRig;

type
  /// <summary>
  ///   Every scenario of Tests\Data\D3Clip\scenarios runs on the Delphi classes and must write the golden file that the
  ///   real C++ wrote (Tools\Verifica\255\Build-Harness-Clip.ps1: the real Clip.h and Clip.cpp, the real collision model
  ///   manager and the real bodies of idEntity::TouchTriggers and idPhysics_Static)
  /// </summary>
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameClipParity = class
  strict private
    const
      /// <summary>
      ///   The tolerance on the floats of a TRACE line, in units in the last place: the collision library (already
      ///   proven against the C++ in IdTech4\Collision) differs from the x87 code of bcc32c in the last bits of the
      ///   fraction and of the contact point on some rays. Everything else (contacts, entities, ids, bounds, matrices
      ///   and the lines of TouchTriggers) is compared bit for bit.
      /// </summary>
      MAX_ULPS = 4;
    procedure AssertSameLines(const AGolden, AActual: TStrings);
    class function IsNearFloat(const AGolden, AActual: string): Boolean; static;
  public
    [Test]
    [TestCase('TraslazioneEContatti', 'clip_translation')]
    [TestCase('RotazioneEMoto', 'clip_rotation')]
    [TestCase('TouchTriggers', 'clip_touch')]
    procedure LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
  end;

  /// <summary>
  ///   The entity classes on the clip: the touch of a trigger, the trigger of a door, the damage of a hurt trigger
  ///   (a game with the clip of the room of <c>room.cm</c>; the expected values are worked out by hand)
  /// </summary>
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameClipEntities = class
  strict private
    FWorld: TD3ClipWorld;
    FRig: TD3WorldRig;
    function Walker(const AX, AY: Single): TD3Entity;
    procedure MoveTo(const AEntity: TD3Entity; const AX, AY: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaPortaDovrebbeAvereIlClipModelDelTrigger;
    [Test]
    procedure UnaPortaDovrebbeAprirsiQuandoUnaEntitaEntraNelSuoTrigger;
    [Test]
    procedure UnaPortaNonDovrebbeAprirsiSeLEntitaEFuoriDalTrigger;
    [Test]
    procedure UnaPortaNoTouchNonDovrebbeAprirsiAlTocco;
    [Test]
    procedure UnaPortaChiusaAChiaveNonDovrebbeAprirsiAlTocco;
    [Test]
    procedure UnTriggerMultiDovrebbeAttivareIlBersaglioAlTocco;
    [Test]
    procedure UnTriggerDisabilitatoNonDovrebbeEssereToccato;
    [Test]
    procedure UnTriggerHurtDovrebbeTogliereLaSaluteDelDefDiDanno;
    [Test]
    procedure UnaEntitaCheNonPrendeDannoNonDovrebbePerderSalute;
    [Test]
    procedure UnaEntitaSenzaDimensioniNonDovrebbeAvereIlClipModel;
    [Test]
    procedure UnMoverDovrebbeSpostareIlSuoClipModel;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Collision.Types,
  DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.Door, DelphiDoom.D3Game.MoverBinary,
  DelphiDoom.D3Game.Trigger, DelphiDoom.D3Game.Trigger.Hurt, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.D3Game.ClipScenario;

{ TTestD3GameClipParity }

procedure TTestD3GameClipParity.AssertSameLines(const AGolden, AActual: TStrings);
var
  LIndex: Integer;
  LGoldenWords: TArray<string>;
  LActualWords: TArray<string>;
  LWord: Integer;
begin
  Assert.AreEqual<Integer>(AGolden.Count, AActual.Count, 'number of lines');
  for LIndex := 0 to AGolden.Count - 1 do
  begin
    if AGolden[LIndex] = AActual[LIndex] then
      Continue;
    // only the answers of the collision model have a tolerance: the last bits of its floats (see the header)
    if not AGolden[LIndex].StartsWith('TRACE ') then
      Assert.AreEqual<string>(AGolden[LIndex], AActual[LIndex], Format('line %d', [LIndex + 1]));
    LGoldenWords := AGolden[LIndex].Split([' ']);
    LActualWords := AActual[LIndex].Split([' ']);
    Assert.AreEqual<Integer>(Length(LGoldenWords), Length(LActualWords), Format('line %d: words', [LIndex + 1]));
    for LWord := 0 to High(LGoldenWords) do
      if LGoldenWords[LWord] <> LActualWords[LWord] then
        Assert.IsTrue(IsNearFloat(LGoldenWords[LWord], LActualWords[LWord]),
          Format('line %d: expected "%s" got "%s"', [LIndex + 1, AGolden[LIndex], AActual[LIndex]]));
  end;
end;

class function TTestD3GameClipParity.IsNearFloat(const AGolden, AActual: string): Boolean;
  function Ordered(const AText: string; out AOk: Boolean): Integer;
  var
    LBits: Cardinal;
    LIndex: Integer;
  begin
    AOk := Length(AText) = 8;
    for LIndex := 1 to Length(AText) do
      if not CharInSet(AText[LIndex], ['0'..'9', 'A'..'F']) then
        AOk := False;
    if not AOk then
      Exit(0);
    LBits := Cardinal(StrToUInt('$' + AText));
    if (LBits and $80000000) <> 0 then
      Result := -Integer(LBits and $7FFFFFFF)
    else
      Result := Integer(LBits);
  end;
var
  LGoldenOk: Boolean;
  LActualOk: Boolean;
  LGolden: Integer;
  LActual: Integer;
begin
  LGolden := Ordered(AGolden, LGoldenOk);
  LActual := Ordered(AActual, LActualOk);
  Result := LGoldenOk and LActualOk and (Abs(LGolden - LActual) <= MAX_ULPS);
end;

procedure TTestD3GameClipParity.LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
var
  LWorld: TD3ClipWorld;
  LRig: TD3WorldRig;
  LRunner: TD3ClipScenarioRunner;
  LScenario: TStringList;
  LGolden: TStringList;
  LTraceFolder: string;
begin
  LScenario := TTestFiles.Lines(TTestFiles.DataFile('D3Clip', 'scenarios\' + AScenario + '.scn'));
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('D3Clip', 'golden\' + AScenario + '.golden.txt'));
  LWorld := TD3ClipWorld.Create;
  try
    LRig := TD3WorldRig.Create(LWorld.Clip);
    try
      LRunner := TD3ClipScenarioRunner.Create(LWorld, LRig);
      try
        LRunner.Run(LScenario);
        // DD_D3GAME_TRACE=<folder>: keeps the whole trace of the run, to compare it with the golden by hand
        LTraceFolder := GetEnvironmentVariable('DD_D3GAME_TRACE');
        if LTraceFolder <> '' then
          LRig.World.Trace.SaveToFile(IncludeTrailingPathDelimiter(LTraceFolder) + AScenario + '.clip.trace.txt');
        AssertSameLines(LGolden, LRig.World.Trace);
      finally
        LRunner.Free;
      end;
    finally
      LRig.Free;
    end;
  finally
    LWorld.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

{ TTestD3GameClipEntities }

procedure TTestD3GameClipEntities.Setup;
begin
  FWorld := TD3ClipWorld.Create;
  FRig := TD3WorldRig.Create(FWorld.Clip);
  FWorld.Clip.Init;
  FRig.World.AddDef('func_door', ['spawnclass', 'idDoor']);
  FRig.World.AddDef('trigger_multi', ['spawnclass', 'idTrigger_Multi']);
  FRig.World.AddDef('trigger_hurt', ['spawnclass', 'idTrigger_Hurt']);
  FRig.World.AddDef('walker', ['spawnclass', 'idTouchRecorder', 'size', '32 32 72']);
  FRig.World.AddDef('target', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('damage_painTrigger', ['damage', '10']);
  FRig.World.AddDef('damageable', ['spawnclass', 'idDamageable']);
  FRig.World.AddDef('plainbody', ['spawnclass', 'idPlainBody']);
end;

procedure TTestD3GameClipEntities.TearDown;
begin
  // the entities go before the clip they are linked in
  FRig.Free;
  FWorld.Free;
end;

function TTestD3GameClipEntities.Walker(const AX, AY: Single): TD3Entity;
begin
  Result := FRig.Spawn(['classname', 'walker', 'name', 'walker1', 'origin',
    AnsiString(Format('%g %g 0', [AX, AY], TFormatSettings.Invariant))]);
end;

procedure TTestD3GameClipEntities.MoveTo(const AEntity: TD3Entity; const AX, AY: Single);
begin
  AEntity.GetPhysics.SetOrigin(TIdVec3.Create(AX, AY, 0));
end;

procedure TTestD3GameClipEntities.UnaEntitaSenzaDimensioniNonDovrebbeAvereIlClipModel;
var
  LTarget: TD3Entity;
begin
  LTarget := FRig.Spawn(['classname', 'target', 'name', 'a1']);
  Assert.AreEqual(0, LTarget.GetPhysics.GetNumClipModels);
end;

procedure TTestD3GameClipEntities.UnaPortaDovrebbeAvereIlClipModelDelTrigger;
var
  LDoor: TD3Door;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1']));
  Assert.AreEqual(1, LDoor.GetPhysics.GetNumClipModels, 'the door has its clip model');
  Assert.IsFalse(Assigned(LDoor.Trigger), 'the trigger comes with the first frame (<spawnDoorTrigger> is posted)');
  FRig.Frame(1);
  Assert.IsTrue(Assigned(LDoor.Trigger));
  Assert.AreEqual(255, LDoor.Trigger.Id);
  Assert.AreEqual(CONTENTS_TRIGGER, LDoor.Trigger.Contents);
  Assert.IsTrue(LDoor.Trigger.IsLinked);
  // the thinnest axis of the door (x: 8 + 2 of the epsilon) is the one the trigger grows along: 120 each way. The
  // "angle" of the entity turns the door by -1 degree (idGameEdit::ParseSpawnArgsToRenderEntity: the axis of the yaw),
  // so its absolute bounds are 5 * cos(1) + 32 * sin(1) = 5.5578 on x
  Assert.AreEqual(0, LDoor.NormalAxisIndex);
  Assert.AreEqual(-125.5578, Double(LDoor.Trigger.Bounds.Mins.X), 0.001);
  Assert.AreEqual(125.5578, Double(LDoor.Trigger.Bounds.Maxs.X), 0.001);
end;

procedure TTestD3GameClipEntities.UnaPortaDovrebbeAprirsiQuandoUnaEntitaEntraNelSuoTrigger;
var
  LDoor: TD3Door;
  LWalker: TD3Entity;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1']));
  FRig.Frame(1);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
  LWalker := Walker(200, 0);
  Assert.IsFalse(LWalker.TouchTriggers, 'outside the trigger (120 units beyond the door)');
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
  MoveTo(LWalker, 100, 0);
  Assert.IsTrue(LWalker.TouchTriggers);
  Assert.AreEqual(Ord(ms1To2), Ord(LDoor.MoverState), 'the door opens');
  FRig.Frame(100);
  Assert.AreEqual(Ord(msPos2), Ord(LDoor.MoverState), 'and gets to the open position');
  Assert.IsTrue(LDoor.GetPhysics.GetOrigin.Z > 100, 'the door went up');
end;

procedure TTestD3GameClipEntities.UnaPortaNonDovrebbeAprirsiSeLEntitaEFuoriDalTrigger;
var
  LDoor: TD3Door;
  LWalker: TD3Entity;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1']));
  FRig.Frame(1);
  LWalker := Walker(300, 300);
  Assert.IsFalse(LWalker.TouchTriggers);
  FRig.Frame(100);
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
end;

procedure TTestD3GameClipEntities.UnaPortaNoTouchNonDovrebbeAprirsiAlTocco;
var
  LDoor: TD3Door;
  LWalker: TD3Entity;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'no_touch', '1']));
  FRig.Frame(1);
  LWalker := Walker(100, 0);
  LWalker.TouchTriggers;
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
end;

procedure TTestD3GameClipEntities.UnaPortaChiusaAChiaveNonDovrebbeAprirsiAlTocco;
var
  LDoor: TD3Door;
  LWalker: TD3Entity;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1',
    'locked', '1']));
  FRig.Frame(2);
  LWalker := Walker(100, 0);
  LWalker.TouchTriggers;
  Assert.AreEqual(Ord(msPos1), Ord(LDoor.MoverState));
  Assert.AreEqual(1, LDoor.IsLocked);
end;

procedure TTestD3GameClipEntities.UnTriggerMultiDovrebbeAttivareIlBersaglioAlTocco;
var
  LWalker: TD3Entity;
begin
  FRig.Spawn(['classname', 'target', 'name', 'goal']);
  // anyTouch: a trigger answers only to a player by default, and there is no player yet
  FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'target', 'goal', 'size', '64 64 64', 'origin', '0 0 0',
    'wait', '0.5', 'anyTouch', '1']);
  FRig.Frame(1);
  LWalker := Walker(300, 300);
  Assert.IsFalse(LWalker.TouchTriggers);
  Assert.AreEqual(0, FRig.Log.Count);
  MoveTo(LWalker, 10, 10);
  Assert.IsTrue(LWalker.TouchTriggers);
  FRig.Frame(1);
  Assert.AreEqual(1, FRig.Log.Count, 'the target was activated once');
  Assert.IsTrue(Pos('ACTIVATE goal by walker1', FRig.Log[0]) = 1, FRig.Log[0]);
end;

procedure TTestD3GameClipEntities.UnTriggerDisabilitatoNonDovrebbeEssereToccato;
var
  LWalker: TD3Entity;
  LTrigger: TD3Entity;
begin
  FRig.Spawn(['classname', 'target', 'name', 'goal']);
  LTrigger := FRig.Spawn(['classname', 'trigger_multi', 'name', 't1', 'target', 'goal', 'size', '64 64 64',
    'anyTouch', '1']);
  FRig.Frame(1);
  TD3Trigger(LTrigger).Disable;
  LWalker := Walker(10, 10);
  Assert.IsFalse(LWalker.TouchTriggers);
  TD3Trigger(LTrigger).Enable;
  Assert.IsTrue(LWalker.TouchTriggers);
  TD3Trigger(LTrigger).Disable;
  Assert.IsFalse(LWalker.TouchTriggers);
end;

procedure TTestD3GameClipEntities.UnTriggerHurtDovrebbeTogliereLaSaluteDelDefDiDanno;
var
  LWalker: TD3Entity;
begin
  FRig.Spawn(['classname', 'trigger_hurt', 'name', 'hurt1', 'size', '64 64 64']);
  FRig.Frame(1);
  LWalker := FRig.Spawn(['classname', 'damageable', 'name', 'victim', 'size', '32 32 72', 'health', '100']);
  Assert.IsTrue(LWalker.TouchTriggers);
  Assert.AreEqual(90, LWalker.Health);
  // the trigger waits a second before it hurts again
  FRig.Frame(10);
  LWalker.TouchTriggers;
  Assert.AreEqual(90, LWalker.Health);
  FRig.Frame(80);
  LWalker.TouchTriggers;
  Assert.AreEqual(80, LWalker.Health);
end;

procedure TTestD3GameClipEntities.UnaEntitaCheNonPrendeDannoNonDovrebbePerderSalute;
var
  LWalker: TD3Entity;
begin
  FRig.Spawn(['classname', 'trigger_hurt', 'name', 'hurt1', 'size', '64 64 64']);
  FRig.Frame(1);
  LWalker := FRig.Spawn(['classname', 'plainbody', 'name', 'victim', 'size', '32 32 72', 'health', '100']);
  LWalker.TouchTriggers;
  Assert.AreEqual(100, LWalker.Health);
end;

procedure TTestD3GameClipEntities.UnMoverDovrebbeSpostareIlSuoClipModel;
var
  LDoor: TD3Door;
  LZBefore: Single;
begin
  LDoor := TD3Door(FRig.Spawn(['classname', 'func_door', 'name', 'door1', 'size', '8 64 128', 'angle', '-1']));
  FRig.Frame(1);
  LZBefore := LDoor.GetPhysics.GetClipModel.AbsBounds.Mins.Z;
  LDoor.Open;
  FRig.Frame(100);
  Assert.IsTrue(LDoor.GetPhysics.GetClipModel.AbsBounds.Mins.Z > LZBefore + 100, 'the clip model follows the door');
  Assert.IsTrue(LDoor.GetPhysics.GetClipModel.IsLinked);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameClipParity);
  TDUnitX.RegisterTestFixture(TTestD3GameClipEntities);

end.
