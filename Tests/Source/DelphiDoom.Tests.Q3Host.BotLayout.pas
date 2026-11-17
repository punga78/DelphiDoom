{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the layout in memory of    }
{  the structures the BOTLIB system calls pass by pointer, against the real     }
{  headers (Tools\Verifica\254\botlayout.sh, gcc -m32; Tests\Data\Q3Host\       }
{  botlayout.golden.txt)                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.BotLayout;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, DelphiDoom.Qvm.Intf;

type
  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostBot')]
  TTestQ3HostBotLayout = class
  strict private
    FValues: TDictionary<string, Integer>;
    FMachine: IQvmMachine;
    function Golden(const AName: string): Integer;
    // the memory of the structure is filled with 0xAB bytes first: a field that is not written shows
    procedure Fill(AAddress, ASize: Integer);
    function WordAt(AAddress: Integer; const AName: string): Integer;
    function FloatWord(AAddress: Integer; const AName: string): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
    [Test]
    procedure IlRecordDelleArmiDovrebbeAvereLeStesseMisureEOffsetDelC;
    [Test]
    procedure UnaMetaDiAreaInfoDovrebbeEssereScrittaAgliOffsetDelC;
    [Test]
    procedure LEntityInfoDovrebbeEssereScrittaAgliOffsetDelC;
    [Test]
    procedure IlClientMoveDovrebbeEssereScrittoAgliOffsetDelC;
    [Test]
    procedure IlPredictRouteDovrebbeEssereScrittoAgliOffsetDelC;
    [Test]
    procedure UnAltRouteGoalDovrebbeAvereITreWordEIlPaddingIntatto;
    [Test]
    procedure IlGoalDovrebbeEssereScrittoELettoAgliOffsetDelC;
    [Test]
    procedure LInputDovrebbeEssereScrittoAgliOffsetDelC;
    [Test]
    procedure IlMoveResultDovrebbeEssereScrittoAgliOffsetDelC;
    [Test]
    procedure LInitMoveDovrebbeEssereLettoAgliOffsetDelC;
    [Test]
    procedure LEntityStateDovrebbeEssereLettaAgliOffsetDelC;
    [Test]
    procedure IlMatchDovrebbeEssereLettoEScrittoAgliOffsetDelC;
    [Test]
    procedure UnMessaggioDellaConsoleDovrebbeAvereIPuntatoriANulla;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Factory, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Ea.Types,
  DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Weapon.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Entity.Types, DelphiDoom.Q3Host.Bot.Memory, DelphiDoom.Tests.Qvm.Programs,
  DelphiDoom.Tests.Qvm.Support, DelphiDoom.Tests.Shared.Files;

const
  BASE = 3000;
  PAD = $AB;

procedure TTestQ3HostBotLayout.Setup;
var
  LLines: TStringList;
  LLine: string;
  LSplit: Integer;
  LText: Integer;
begin
  FValues := TDictionary<string, Integer>.Create;
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'botlayout.golden.txt'));
  try
    for LLine in LLines do
    begin
      LSplit := LLine.LastDelimiter(' ');
      FValues.AddOrSetValue(Copy(LLine, 1, LSplit), StrToInt(Copy(LLine, LSplit + 2, MaxInt)));
    end;
  finally
    LLines.Free;
  end;
  FMachine := TQvmFactory.CreateMachine('botlayout', TQvmPrograms.AnySystemCall(LText), TQvmNullHost.Create);
end;

procedure TTestQ3HostBotLayout.TearDown;
begin
  FValues.Free;
end;

function TTestQ3HostBotLayout.Golden(const AName: string): Integer;
begin
  Assert.IsTrue(FValues.TryGetValue(AName, Result), AName);
end;

procedure TTestQ3HostBotLayout.Fill(AAddress, ASize: Integer);
begin
  FMachine.Memory.Fill(AAddress, PAD, ASize + 8);
end;

// the word of a field (the structure is at BASE)
function TTestQ3HostBotLayout.WordAt(AAddress: Integer; const AName: string): Integer;
begin
  Result := FMachine.Memory.ReadInt32(AAddress + Golden(AName));
end;

function TTestQ3HostBotLayout.FloatWord(AAddress: Integer; const AName: string): Single;
begin
  Result := TQ3BotMemory.Float(WordAt(AAddress, AName));
end;

procedure TTestQ3HostBotLayout.LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
begin
  Assert.AreEqual(Golden('sizeof bot_entitystate_t'), TQ3BotMemory.SIZE_ENTITYSTATE);
  Assert.AreEqual(Golden('sizeof bot_input_t'), TQ3BotMemory.SIZE_INPUT);
  Assert.AreEqual(Golden('sizeof bot_goal_t'), TQ3BotMemory.SIZE_GOAL);
  Assert.AreEqual(Golden('sizeof bot_initmove_t'), TQ3BotMemory.SIZE_INITMOVE);
  Assert.AreEqual(Golden('sizeof bot_moveresult_t'), TQ3BotMemory.SIZE_MOVERESULT);
  Assert.AreEqual(Golden('sizeof aas_entityinfo_t'), TQ3BotMemory.SIZE_ENTITYINFO);
  Assert.AreEqual(Golden('sizeof aas_areainfo_t'), TQ3BotMemory.SIZE_AREAINFO);
  Assert.AreEqual(Golden('sizeof aas_clientmove_t'), TQ3BotMemory.SIZE_CLIENTMOVE);
  Assert.AreEqual(Golden('sizeof aas_altroutegoal_t'), TQ3BotMemory.SIZE_ALTROUTEGOAL);
  Assert.AreEqual(Golden('sizeof aas_predictroute_t'), TQ3BotMemory.SIZE_PREDICTROUTE);
  Assert.AreEqual(Golden('sizeof bot_match_t'), TQ3BotMemory.SIZE_MATCH);
  Assert.AreEqual(Golden('sizeof bot_consolemessage_t'), TQ3BotMemory.SIZE_CONSOLEMESSAGE);
  Assert.AreEqual(Golden('sizeof weaponinfo_t'), TQ3BotMemory.SIZE_WEAPONINFO);
  Assert.AreEqual(Golden('const MAX_MESSAGE_SIZE'), TQ3BotMemory.MAX_MESSAGE_SIZE);
  Assert.AreEqual(Golden('const MAX_MATCHVARIABLES'), MAX_MATCHVARIABLES);
  // the library keeps the structures that the memory copies as they are in packed records of the same size
  Assert.AreEqual(Golden('sizeof aas_areainfo_t'), SizeOf(TAasAreaInfo));
  Assert.AreEqual(Golden('sizeof aas_predictroute_t'), SizeOf(TAasPredictRoute));
  Assert.AreEqual(Golden('sizeof aas_altroutegoal_t'), SizeOf(TAasAltRouteGoal));
  Assert.AreEqual(Golden('sizeof bot_goal_t'), SizeOf(TBotGoal));
  Assert.AreEqual(Golden('sizeof bot_input_t'), SizeOf(TBotInput));
  Assert.AreEqual(Golden('sizeof bot_initmove_t'), SizeOf(TBotInitMove));
  Assert.AreEqual(Golden('sizeof bot_entitystate_t'), SizeOf(TBotEntityState));
end;

procedure TTestQ3HostBotLayout.IlRecordDelleArmiDovrebbeAvereLeStesseMisureEOffsetDelC;
var
  LInfo: TBotWeaponInfo;
  LBase: PByte;
begin
  LInfo := Default(TBotWeaponInfo);
  LBase := PByte(@LInfo);
  Assert.AreEqual(Golden('sizeof weaponinfo_t'), SizeOf(LInfo));
  Assert.AreEqual(Golden('sizeof projectileinfo_t'), SizeOf(LInfo.Proj));
  Assert.AreEqual(Golden('weaponinfo_t.name'), Integer(PByte(@LInfo.Name) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.model'), Integer(PByte(@LInfo.Model) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.level'), Integer(PByte(@LInfo.Level) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.projectile'), Integer(PByte(@LInfo.Projectile) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.hspread'), Integer(PByte(@LInfo.HorizontalSpread) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.recoil'), Integer(PByte(@LInfo.Recoil) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.angleoffset'), Integer(PByte(@LInfo.AngleOffset) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.ammoamount'), Integer(PByte(@LInfo.AmmoAmount) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.spindown'), Integer(PByte(@LInfo.SpinDown) - LBase));
  Assert.AreEqual(Golden('weaponinfo_t.proj'), Integer(PByte(@LInfo.Proj) - LBase));
  Assert.AreEqual(Golden('const MAX_STRINGFIELD'), Length(LInfo.Name));
  // and what WriteWeaponInfo writes is the record
  LInfo.Valid := 1;
  LInfo.Number := 7;
  LInfo.Speed := 1.5;
  LInfo.Proj.Damage := 99;
  Fill(BASE, TQ3BotMemory.SIZE_WEAPONINFO);
  TQ3BotMemory.WriteWeaponInfo(FMachine.Memory, BASE, LInfo);
  Assert.AreEqual(1, WordAt(BASE, 'weaponinfo_t.valid'));
  Assert.AreEqual(7, WordAt(BASE, 'weaponinfo_t.number'));
  Assert.AreEqual(Single(1.5), FloatWord(BASE, 'weaponinfo_t.speed'));
  // projectileinfo_t: name, model, flags, gravity, damage
  Assert.AreEqual(99, FMachine.Memory.ReadInt32(BASE + Golden('weaponinfo_t.proj') + 2 * Golden('const MAX_STRINGFIELD') + 8));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + TQ3BotMemory.SIZE_WEAPONINFO)));
end;

procedure TTestQ3HostBotLayout.UnaMetaDiAreaInfoDovrebbeEssereScrittaAgliOffsetDelC;
var
  LInfo: TAasAreaInfo;
begin
  LInfo := Default(TAasAreaInfo);
  LInfo.Contents := 11;
  LInfo.Flags := 12;
  LInfo.PresenceType := 13;
  LInfo.Cluster := 14;
  LInfo.Mins[0] := 1;
  LInfo.Mins[2] := 3;
  LInfo.Maxs[1] := 5;
  LInfo.Center[0] := 7;
  LInfo.Center[2] := 9;
  Fill(BASE, TQ3BotMemory.SIZE_AREAINFO);
  TQ3BotMemory.WriteAreaInfo(FMachine.Memory, BASE, LInfo);
  Assert.AreEqual(11, WordAt(BASE, 'aas_areainfo_t.contents'));
  Assert.AreEqual(12, WordAt(BASE, 'aas_areainfo_t.flags'));
  Assert.AreEqual(13, WordAt(BASE, 'aas_areainfo_t.presencetype'));
  Assert.AreEqual(14, WordAt(BASE, 'aas_areainfo_t.cluster'));
  Assert.AreEqual(Single(1), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_areainfo_t.mins'))));
  Assert.AreEqual(Single(3), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_areainfo_t.mins') + 8)));
  Assert.AreEqual(Single(5), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_areainfo_t.maxs') + 4)));
  Assert.AreEqual(Single(7), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_areainfo_t.center'))));
  Assert.AreEqual(Single(9), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_areainfo_t.center') + 8)));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof aas_areainfo_t'))));
end;

procedure TTestQ3HostBotLayout.LEntityInfoDovrebbeEssereScrittaAgliOffsetDelC;
var
  LInfo: TAasEntityInfo;
begin
  LInfo := Default(TAasEntityInfo);
  LInfo.Valid := True;
  LInfo.EntityType := 21;
  LInfo.Flags := 22;
  LInfo.LocalTime := 2.5;
  LInfo.UpdateTime := 3.5;
  LInfo.Number := 25;
  LInfo.Origin[1] := 26;
  LInfo.Angles[2] := 27;
  LInfo.OldOrigin[0] := 28;
  LInfo.LastVisOrigin[2] := 29;
  LInfo.Mins[1] := 30;
  LInfo.Maxs[0] := 31;
  LInfo.GroundEnt := 32;
  LInfo.Solid := 33;
  LInfo.ModelIndex := 34;
  LInfo.ModelIndex2 := 35;
  LInfo.Frame := 36;
  LInfo.Event := 37;
  LInfo.EventParm := 38;
  LInfo.Powerups := 39;
  LInfo.Weapon := 40;
  LInfo.LegsAnim := 41;
  LInfo.TorsoAnim := 42;
  Fill(BASE, TQ3BotMemory.SIZE_ENTITYINFO);
  TQ3BotMemory.WriteEntityInfo(FMachine.Memory, BASE, LInfo);
  Assert.AreEqual(1, WordAt(BASE, 'aas_entityinfo_t.valid'));
  Assert.AreEqual(21, WordAt(BASE, 'aas_entityinfo_t.type'));
  Assert.AreEqual(22, WordAt(BASE, 'aas_entityinfo_t.flags'));
  Assert.AreEqual(Single(2.5), FloatWord(BASE, 'aas_entityinfo_t.ltime'));
  Assert.AreEqual(Single(3.5), FloatWord(BASE, 'aas_entityinfo_t.update_time'));
  Assert.AreEqual(25, WordAt(BASE, 'aas_entityinfo_t.number'));
  Assert.AreEqual(Single(26), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.origin') + 4)));
  Assert.AreEqual(Single(27), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.angles') + 8)));
  Assert.AreEqual(Single(28), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.old_origin'))));
  Assert.AreEqual(Single(29), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.lastvisorigin') + 8)));
  Assert.AreEqual(Single(30), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.mins') + 4)));
  Assert.AreEqual(Single(31), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_entityinfo_t.maxs'))));
  Assert.AreEqual(32, WordAt(BASE, 'aas_entityinfo_t.groundent'));
  Assert.AreEqual(33, WordAt(BASE, 'aas_entityinfo_t.solid'));
  Assert.AreEqual(34, WordAt(BASE, 'aas_entityinfo_t.modelindex'));
  Assert.AreEqual(35, WordAt(BASE, 'aas_entityinfo_t.modelindex2'));
  Assert.AreEqual(36, WordAt(BASE, 'aas_entityinfo_t.frame'));
  Assert.AreEqual(37, WordAt(BASE, 'aas_entityinfo_t.event'));
  Assert.AreEqual(38, WordAt(BASE, 'aas_entityinfo_t.eventParm'));
  Assert.AreEqual(39, WordAt(BASE, 'aas_entityinfo_t.powerups'));
  Assert.AreEqual(40, WordAt(BASE, 'aas_entityinfo_t.weapon'));
  Assert.AreEqual(41, WordAt(BASE, 'aas_entityinfo_t.legsAnim'));
  Assert.AreEqual(42, WordAt(BASE, 'aas_entityinfo_t.torsoAnim'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof aas_entityinfo_t'))));
end;

procedure TTestQ3HostBotLayout.IlClientMoveDovrebbeEssereScrittoAgliOffsetDelC;
var
  LMove: TAasClientMove;
  LTrace: Integer;
begin
  LMove := Default(TAasClientMove);
  LMove.EndPos[2] := 1;
  LMove.EndArea := 2;
  LMove.Velocity[1] := 3;
  LMove.Trace.StartSolid := True;
  LMove.Trace.Fraction := 0.5;
  LMove.Trace.EndPos[0] := 6;
  LMove.Trace.Ent := 7;
  LMove.Trace.LastArea := 8;
  LMove.Trace.Area := 9;
  LMove.Trace.PlaneNum := 10;
  LMove.PresenceType := 11;
  LMove.StopEvent := 12;
  LMove.EndContents := 13;
  LMove.Time := 1.25;
  LMove.Frames := 15;
  Fill(BASE, TQ3BotMemory.SIZE_CLIENTMOVE);
  TQ3BotMemory.WriteClientMove(FMachine.Memory, BASE, LMove);
  LTrace := BASE + Golden('aas_clientmove_t.trace');
  Assert.AreEqual(Single(1), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_clientmove_t.endpos') + 8)));
  Assert.AreEqual(2, WordAt(BASE, 'aas_clientmove_t.endarea'));
  Assert.AreEqual(Single(3), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_clientmove_t.velocity') + 4)));
  Assert.AreEqual(1, WordAt(LTrace, 'aas_trace_t.startsolid'));
  Assert.AreEqual(Single(0.5), FloatWord(LTrace, 'aas_trace_t.fraction'));
  Assert.AreEqual(Single(6), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(LTrace + Golden('aas_trace_t.endpos'))));
  Assert.AreEqual(7, WordAt(LTrace, 'aas_trace_t.ent'));
  Assert.AreEqual(8, WordAt(LTrace, 'aas_trace_t.lastarea'));
  Assert.AreEqual(9, WordAt(LTrace, 'aas_trace_t.area'));
  Assert.AreEqual(10, WordAt(LTrace, 'aas_trace_t.planenum'));
  Assert.AreEqual(11, WordAt(BASE, 'aas_clientmove_t.presencetype'));
  Assert.AreEqual(12, WordAt(BASE, 'aas_clientmove_t.stopevent'));
  Assert.AreEqual(13, WordAt(BASE, 'aas_clientmove_t.endcontents'));
  Assert.AreEqual(Single(1.25), FloatWord(BASE, 'aas_clientmove_t.time'));
  Assert.AreEqual(15, WordAt(BASE, 'aas_clientmove_t.frames'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof aas_clientmove_t'))));
end;

procedure TTestQ3HostBotLayout.IlPredictRouteDovrebbeEssereScrittoAgliOffsetDelC;
var
  LRoute: TAasPredictRoute;
begin
  LRoute := Default(TAasPredictRoute);
  LRoute.EndPos[1] := 4;
  LRoute.EndArea := 5;
  LRoute.StopEvent := 6;
  LRoute.EndContents := 7;
  LRoute.EndTravelFlags := 8;
  LRoute.NumAreas := 9;
  LRoute.Time := 10;
  Fill(BASE, TQ3BotMemory.SIZE_PREDICTROUTE);
  TQ3BotMemory.WritePredictRoute(FMachine.Memory, BASE, LRoute);
  Assert.AreEqual(Single(4), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_predictroute_t.endpos') + 4)));
  Assert.AreEqual(5, WordAt(BASE, 'aas_predictroute_t.endarea'));
  Assert.AreEqual(6, WordAt(BASE, 'aas_predictroute_t.stopevent'));
  Assert.AreEqual(7, WordAt(BASE, 'aas_predictroute_t.endcontents'));
  Assert.AreEqual(8, WordAt(BASE, 'aas_predictroute_t.endtravelflags'));
  Assert.AreEqual(9, WordAt(BASE, 'aas_predictroute_t.numareas'));
  Assert.AreEqual(10, WordAt(BASE, 'aas_predictroute_t.time'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof aas_predictroute_t'))));
end;

procedure TTestQ3HostBotLayout.UnAltRouteGoalDovrebbeAvereITreWordEIlPaddingIntatto;
var
  LGoal: TAasAltRouteGoal;
  LStart: Integer;
begin
  LGoal := Default(TAasAltRouteGoal);
  LGoal.Origin[2] := 8;
  LGoal.AreaNum := 9;
  LGoal.StartTravelTime := $1234;
  LGoal.GoalTravelTime := $5678;
  LGoal.ExtraTravelTime := $9ABC;
  Fill(BASE, TQ3BotMemory.SIZE_ALTROUTEGOAL);
  TQ3BotMemory.WriteAltRouteGoal(FMachine.Memory, BASE, LGoal);
  Assert.AreEqual(Single(8), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('aas_altroutegoal_t.origin') + 8)));
  Assert.AreEqual(9, WordAt(BASE, 'aas_altroutegoal_t.areanum'));
  LStart := BASE + Golden('aas_altroutegoal_t.starttraveltime');
  Assert.AreEqual($1234, Integer(FMachine.Memory.ReadByte(LStart)) or (Integer(FMachine.Memory.ReadByte(LStart + 1)) shl 8));
  LStart := BASE + Golden('aas_altroutegoal_t.goaltraveltime');
  Assert.AreEqual($5678, Integer(FMachine.Memory.ReadByte(LStart)) or (Integer(FMachine.Memory.ReadByte(LStart + 1)) shl 8));
  LStart := BASE + Golden('aas_altroutegoal_t.extratraveltime');
  Assert.AreEqual($9ABC, Integer(FMachine.Memory.ReadByte(LStart)) or (Integer(FMachine.Memory.ReadByte(LStart + 1)) shl 8));
  // the two bytes of padding are not written, and neither is what follows
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('aas_altroutegoal_t.extratraveltime') + 2)));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof aas_altroutegoal_t'))));
end;

procedure TTestQ3HostBotLayout.IlGoalDovrebbeEssereScrittoELettoAgliOffsetDelC;
var
  LGoal, LRead: TBotGoal;
begin
  LGoal := Default(TBotGoal);
  LGoal.Origin[0] := 1;
  LGoal.Origin[2] := 3;
  LGoal.AreaNum := 4;
  LGoal.Mins[1] := 5;
  LGoal.Maxs[2] := 6;
  LGoal.EntityNum := 7;
  LGoal.Number := 8;
  LGoal.Flags := 9;
  LGoal.ItemInfo := 10;
  Fill(BASE, TQ3BotMemory.SIZE_GOAL);
  TQ3BotMemory.WriteGoal(FMachine.Memory, BASE, LGoal);
  Assert.AreEqual(Single(1), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_goal_t.origin'))));
  Assert.AreEqual(Single(3), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_goal_t.origin') + 8)));
  Assert.AreEqual(4, WordAt(BASE, 'bot_goal_t.areanum'));
  Assert.AreEqual(Single(5), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_goal_t.mins') + 4)));
  Assert.AreEqual(Single(6), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_goal_t.maxs') + 8)));
  Assert.AreEqual(7, WordAt(BASE, 'bot_goal_t.entitynum'));
  Assert.AreEqual(8, WordAt(BASE, 'bot_goal_t.number'));
  Assert.AreEqual(9, WordAt(BASE, 'bot_goal_t.flags'));
  Assert.AreEqual(10, WordAt(BASE, 'bot_goal_t.iteminfo'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof bot_goal_t'))));
  LRead := TQ3BotMemory.ReadGoal(FMachine.Memory, BASE);
  Assert.IsTrue(CompareMem(@LGoal, @LRead, SizeOf(LGoal)));
end;

procedure TTestQ3HostBotLayout.LInputDovrebbeEssereScrittoAgliOffsetDelC;
var
  LInput: TBotInput;
begin
  LInput := Default(TBotInput);
  LInput.ThinkTime := 0.1;
  LInput.Dir[0] := 1;
  LInput.Speed := 400;
  LInput.ViewAngles[2] := 90;
  LInput.ActionFlags := $12345;
  LInput.Weapon := 8;
  Fill(BASE, TQ3BotMemory.SIZE_INPUT);
  TQ3BotMemory.WriteInput(FMachine.Memory, BASE, LInput);
  Assert.AreEqual(Single(0.1), FloatWord(BASE, 'bot_input_t.thinktime'));
  Assert.AreEqual(Single(1), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_input_t.dir'))));
  Assert.AreEqual(Single(400), FloatWord(BASE, 'bot_input_t.speed'));
  Assert.AreEqual(Single(90), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_input_t.viewangles') + 8)));
  Assert.AreEqual($12345, WordAt(BASE, 'bot_input_t.actionflags'));
  Assert.AreEqual(8, WordAt(BASE, 'bot_input_t.weapon'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof bot_input_t'))));
end;

procedure TTestQ3HostBotLayout.IlMoveResultDovrebbeEssereScrittoAgliOffsetDelC;
var
  LResult: TBotMoveResult;
begin
  LResult := Default(TBotMoveResult);
  LResult.Failure := True;
  LResult.ResultType := 2;
  LResult.Blocked := True;
  LResult.BlockEntity := 4;
  LResult.TravelType := 5;
  LResult.Flags := 6;
  LResult.Weapon := 7;
  LResult.MoveDir[1] := 8;
  LResult.IdealViewAngles[2] := 9;
  Fill(BASE, TQ3BotMemory.SIZE_MOVERESULT);
  TQ3BotMemory.WriteMoveResult(FMachine.Memory, BASE, LResult);
  Assert.AreEqual(1, WordAt(BASE, 'bot_moveresult_t.failure'));
  Assert.AreEqual(2, WordAt(BASE, 'bot_moveresult_t.type'));
  Assert.AreEqual(1, WordAt(BASE, 'bot_moveresult_t.blocked'));
  Assert.AreEqual(4, WordAt(BASE, 'bot_moveresult_t.blockentity'));
  Assert.AreEqual(5, WordAt(BASE, 'bot_moveresult_t.traveltype'));
  Assert.AreEqual(6, WordAt(BASE, 'bot_moveresult_t.flags'));
  Assert.AreEqual(7, WordAt(BASE, 'bot_moveresult_t.weapon'));
  Assert.AreEqual(Single(8), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_moveresult_t.movedir') + 4)));
  Assert.AreEqual(Single(9), TQ3BotMemory.Float(FMachine.Memory.ReadInt32(BASE + Golden('bot_moveresult_t.ideal_viewangles') + 8)));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof bot_moveresult_t'))));
end;

procedure TTestQ3HostBotLayout.LInitMoveDovrebbeEssereLettoAgliOffsetDelC;
var
  LIndex: Integer;
  LInit: TBotInitMove;
begin
  // every word of the structure is its own index: the field read at an offset tells the offset
  for LIndex := 0 to TQ3BotMemory.SIZE_INITMOVE div 4 - 1 do
    FMachine.Memory.WriteInt32(BASE + 4 * LIndex, LIndex);
  LInit := TQ3BotMemory.ReadInitMove(FMachine.Memory, BASE);
  Assert.AreEqual(Golden('bot_initmove_t.origin') div 4, TQ3BotMemory.Bits(LInit.Origin[0]));
  Assert.AreEqual(Golden('bot_initmove_t.velocity') div 4, TQ3BotMemory.Bits(LInit.Velocity[0]));
  Assert.AreEqual(Golden('bot_initmove_t.viewoffset') div 4, TQ3BotMemory.Bits(LInit.ViewOffset[0]));
  Assert.AreEqual(Golden('bot_initmove_t.entitynum') div 4, LInit.EntityNum);
  Assert.AreEqual(Golden('bot_initmove_t.client') div 4, LInit.Client);
  Assert.AreEqual(Golden('bot_initmove_t.thinktime') div 4, TQ3BotMemory.Bits(LInit.ThinkTime));
  Assert.AreEqual(Golden('bot_initmove_t.presencetype') div 4, LInit.PresenceType);
  Assert.AreEqual(Golden('bot_initmove_t.viewangles') div 4, TQ3BotMemory.Bits(LInit.ViewAngles[0]));
  Assert.AreEqual(Golden('bot_initmove_t.or_moveflags') div 4, LInit.OrMoveFlags);
end;

procedure TTestQ3HostBotLayout.LEntityStateDovrebbeEssereLettaAgliOffsetDelC;
var
  LIndex: Integer;
  LState: TBotEntityState;
begin
  for LIndex := 0 to TQ3BotMemory.SIZE_ENTITYSTATE div 4 - 1 do
    FMachine.Memory.WriteInt32(BASE + 4 * LIndex, LIndex);
  LState := TQ3BotMemory.ReadEntityState(FMachine.Memory, BASE);
  Assert.AreEqual(Golden('bot_entitystate_t.type') div 4, LState.EntityType);
  Assert.AreEqual(Golden('bot_entitystate_t.flags') div 4, LState.Flags);
  Assert.AreEqual(Golden('bot_entitystate_t.origin') div 4, TQ3BotMemory.Bits(LState.Origin[0]));
  Assert.AreEqual(Golden('bot_entitystate_t.angles') div 4, TQ3BotMemory.Bits(LState.Angles[0]));
  Assert.AreEqual(Golden('bot_entitystate_t.old_origin') div 4, TQ3BotMemory.Bits(LState.OldOrigin[0]));
  Assert.AreEqual(Golden('bot_entitystate_t.mins') div 4, TQ3BotMemory.Bits(LState.Mins[0]));
  Assert.AreEqual(Golden('bot_entitystate_t.maxs') div 4, TQ3BotMemory.Bits(LState.Maxs[0]));
  Assert.AreEqual(Golden('bot_entitystate_t.groundent') div 4, LState.GroundEnt);
  Assert.AreEqual(Golden('bot_entitystate_t.solid') div 4, LState.Solid);
  Assert.AreEqual(Golden('bot_entitystate_t.modelindex') div 4, LState.ModelIndex);
  Assert.AreEqual(Golden('bot_entitystate_t.modelindex2') div 4, LState.ModelIndex2);
  Assert.AreEqual(Golden('bot_entitystate_t.frame') div 4, LState.Frame);
  Assert.AreEqual(Golden('bot_entitystate_t.event') div 4, LState.Event);
  Assert.AreEqual(Golden('bot_entitystate_t.eventParm') div 4, LState.EventParm);
  Assert.AreEqual(Golden('bot_entitystate_t.powerups') div 4, LState.Powerups);
  Assert.AreEqual(Golden('bot_entitystate_t.weapon') div 4, LState.Weapon);
  Assert.AreEqual(Golden('bot_entitystate_t.legsAnim') div 4, LState.LegsAnim);
  Assert.AreEqual(Golden('bot_entitystate_t.torsoAnim') div 4, LState.TorsoAnim);
end;

procedure TTestQ3HostBotLayout.IlMatchDovrebbeEssereLettoEScrittoAgliOffsetDelC;
var
  LMatch, LRead: TBotMatch;
  LIndex: Integer;
begin
  LMatch := Default(TBotMatch);
  LMatch.Text := 'hello world';
  LMatch.MatchType := 5;
  LMatch.SubType := 6;
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    LMatch.Variables[LIndex].Offset := ShortInt(LIndex - 1);
    LMatch.Variables[LIndex].Length := 100 + LIndex;
  end;
  // a negative offset (-1: the variable was not found) and the 'char' of the C is signed
  LMatch.Variables[3].Offset := -1;
  Fill(BASE, TQ3BotMemory.SIZE_MATCH);
  TQ3BotMemory.WriteMatch(FMachine.Memory, BASE, LMatch);
  Assert.AreEqual('hello world', string(FMachine.Memory.ReadString(BASE + Golden('bot_match_t.string'))));
  Assert.AreEqual(5, WordAt(BASE, 'bot_match_t.type'));
  Assert.AreEqual(6, WordAt(BASE, 'bot_match_t.subtype'));
  for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
  begin
    Assert.AreEqual(Integer(Byte(LMatch.Variables[LIndex].Offset)), Integer(FMachine.Memory.ReadByte(
      BASE + Golden('bot_match_t.variables') + LIndex * Golden('sizeof bot_matchvariable_t') +
      Golden('bot_matchvariable_t.offset'))), 'offset');
    Assert.AreEqual(100 + LIndex, FMachine.Memory.ReadInt32(BASE + Golden('bot_match_t.variables') +
      LIndex * Golden('sizeof bot_matchvariable_t') + Golden('bot_matchvariable_t.length')), 'length');
  end;
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof bot_match_t'))));
  LRead := TQ3BotMemory.ReadMatch(FMachine.Memory, BASE);
  Assert.AreEqual(string(LMatch.Text), string(LRead.Text));
  Assert.AreEqual(5, LRead.MatchType);
  Assert.AreEqual(6, LRead.SubType);
  Assert.AreEqual(-1, Integer(LRead.Variables[3].Offset));
  Assert.AreEqual(103, LRead.Variables[3].Length);
end;

procedure TTestQ3HostBotLayout.UnMessaggioDellaConsoleDovrebbeAvereIPuntatoriANulla;
var
  LMessage: TBotConsoleMessage;
begin
  LMessage := Default(TBotConsoleMessage);
  LMessage.Handle := 7;
  LMessage.Time := 3.5;
  LMessage.MessageType := 2;
  LMessage.Text := 'bot said hi';
  Fill(BASE, TQ3BotMemory.SIZE_CONSOLEMESSAGE);
  FMachine.Memory.WriteInt32(BASE + Golden('bot_consolemessage_t.prev'), 12345);
  FMachine.Memory.WriteInt32(BASE + Golden('bot_consolemessage_t.next'), 54321);
  TQ3BotMemory.WriteConsoleMessage(FMachine.Memory, BASE, LMessage);
  Assert.AreEqual(7, WordAt(BASE, 'bot_consolemessage_t.handle'));
  Assert.AreEqual(Single(3.5), FloatWord(BASE, 'bot_consolemessage_t.time'));
  Assert.AreEqual(2, WordAt(BASE, 'bot_consolemessage_t.type'));
  Assert.AreEqual('bot said hi', string(FMachine.Memory.ReadString(BASE + Golden('bot_consolemessage_t.message'))));
  // the pointers of the list are the host's: the C clears them, the bridge writes 0
  Assert.AreEqual(0, WordAt(BASE, 'bot_consolemessage_t.prev'));
  Assert.AreEqual(0, WordAt(BASE, 'bot_consolemessage_t.next'));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(BASE + Golden('sizeof bot_consolemessage_t'))));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3HostBotLayout);

end.
