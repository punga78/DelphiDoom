{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - the movement on the collision      }
{  model of Quake III: a small BSP built in memory, and the maps of OpenArena  }
{  0.8.8 (GPL v2) read where they are, ignored when they are not               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Collision;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf;

type
  /// <summary>IPmoveTrace on the room of Tests.Collision.Q3Support: a floor (top at 0) and a pillar at x 100 to 132</summary>
  [TestFixture]
  [Category('Pmove')]
  TTestPmoveCollisionTrace = class
  strict private
    FModel: IQ3CollisionModel;
    FTrace: IPmoveTrace;
    function Walk(const ACommands: Integer): TPmove;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSegnareIlMondoComeEntitaDiUnaCollisione;
    [Test]
    procedure DovrebbeSegnareNessunaEntitaSeLaScatolaNonColpisceNulla;
    [Test]
    procedure DovrebbeDareIContenutiDiUnPunto;
    [Test]
    procedure DovrebbeCadereSulPavimentoEStarciSopra;
    [Test]
    procedure DovrebbeFermarsiControIlPilastroSenzaAttraversarlo;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoOgniVolta;
    [Test]
    procedure DovrebbeCrearsiSuUnaMappa;
  end;

  /// <summary>
  ///   The maps of pak1-maps.pk3 (DELPHIDOOM_OPENARENA = the baseoa folder or a pk3 in it, or
  ///   Reference\openarena\openarena-0.8.8\baseoa): the player is put on the deathmatch spawns and moved with
  ///   commands that run, turn and jump; it never ends inside a wall and the result is the same every time
  /// </summary>
  [TestFixture]
  [Category('Pmove')]
  [Category('OpenArena')]
  TTestPmoveOpenArena = class
  strict private
    function FindPak: string;
    procedure Visit(const AVisit: TProc<string, TBytes>);
    function Spawns(const AEntities: AnsiString): TArray<TQ3Vec3>;
    function Run(const AModel: IQ3CollisionModel; const ASpawn: TQ3Vec3; const AMapIndex: Integer;
      out AFinal: TQ3PlayerState): Integer;
  public
    [Test]
    procedure DovrebbeMuoversiNelleMappeSenzaFinireDentroIMuri;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoSuUnaMappaPiuVolte;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Zip, DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Factory,
  DelphiDoom.Pmove.Factory, DelphiDoom.Pmove.CollisionTrace,
  DelphiDoom.Tests.Collision.Q3Support, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Fnv;

const
  MAPS_TO_TRY = 6;
  MAPS_TO_LOOK_AT = 40;
  SPAWNS_PER_MAP = 3;
  COMMANDS_PER_SPAWN = 500;

{ TTestPmoveCollisionTrace }

procedure TTestPmoveCollisionTrace.Setup;
begin
  FModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, BuildRoomBsp, 'room.bsp');
  FTrace := TPmoveCollisionTrace.Create(FModel);
end;

function TTestPmoveCollisionTrace.Walk(const ACommands: Integer): TPmove;
var
  LMover: IPmove;
  LIndex: Integer;
begin
  LMover := TPmoveFactory.CreateForMap(FModel);
  Result := Default(TPmove);
  Result.TraceMask := Q3_MASK_PLAYERSOLID;
  Result.Ps.CommandTime := 1000;
  Result.Ps.Gravity := 800;
  Result.Ps.Speed := 320;
  Result.Ps.ViewHeight := Q3_DEFAULT_VIEWHEIGHT;
  Result.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  Result.Ps.Stats[Q3_STAT_HEALTH] := 100;
  Result.Ps.Stats[Q3_STAT_MAX_HEALTH] := 100;
  Result.Ps.Origin[0] := 0;
  Result.Ps.Origin[1] := 0;
  Result.Ps.Origin[2] := 60;
  for LIndex := 1 to ACommands do
  begin
    Result.Cmd.ServerTime := Result.Ps.CommandTime + 16;
    // falls first, then runs along +x (yaw 0)
    if LIndex > 20 then
      Result.Cmd.ForwardMove := 127;
    LMover.Execute(Result);
  end;
end;

procedure TTestPmoveCollisionTrace.DovrebbeSegnareIlMondoComeEntitaDiUnaCollisione;
var
  LTrace: TQ3Trace;
  LStart, LEnd, LMins, LMaxs: TQ3Vec3;
begin
  LStart := Vec(0, 0, 50);
  LEnd := Vec(0, 0, -10);
  LMins := Vec(0, 0, 0);
  LMaxs := Vec(0, 0, 0);
  LTrace := FTrace.Trace(LStart, LMins, LMaxs, LEnd, 0, Q3_MASK_PLAYERSOLID);
  Assert.IsTrue(LTrace.Fraction < 1, 'colpisce');
  Assert.AreEqual(Q3_ENTITYNUM_WORLD, LTrace.EntityNum, 'il mondo');
  Assert.AreEqual<Single>(1, LTrace.Plane.Normal[2], 'normale');
end;

procedure TTestPmoveCollisionTrace.DovrebbeSegnareNessunaEntitaSeLaScatolaNonColpisceNulla;
var
  LTrace: TQ3Trace;
  LStart, LEnd, LMins, LMaxs: TQ3Vec3;
begin
  LStart := Vec(0, 0, 50);
  LEnd := Vec(0, 0, 80);
  LMins := Vec(-15, -15, -24);
  LMaxs := Vec(15, 15, 32);
  LTrace := FTrace.Trace(LStart, LMins, LMaxs, LEnd, 0, Q3_MASK_PLAYERSOLID);
  Assert.AreEqual<Single>(1, LTrace.Fraction);
  Assert.AreEqual(Q3_ENTITYNUM_NONE, LTrace.EntityNum, 'nessuna');
end;

procedure TTestPmoveCollisionTrace.DovrebbeDareIContenutiDiUnPunto;
begin
  Assert.IsTrue((FTrace.PointContents(Vec(0, 0, -10), 0) and Q3_CONTENTS_SOLID) <> 0, 'dentro il pavimento');
  Assert.AreEqual(0, FTrace.PointContents(Vec(0, 0, 10), 0), 'in aria');
end;

procedure TTestPmoveCollisionTrace.DovrebbeCadereSulPavimentoEStarciSopra;
var
  LPmove: TPmove;
begin
  LPmove := Walk(40);
  Assert.AreEqual(Q3_ENTITYNUM_WORLD, LPmove.Ps.GroundEntityNum, 'a terra');
  // the box is 24 under the origin: the origin rests at 24 over the floor, the trace epsilon apart
  Assert.IsTrue(Abs(LPmove.Ps.Origin[2] - 24) < 0.3, Format('altezza %g', [LPmove.Ps.Origin[2]]));
  Assert.AreEqual<Single>(0, LPmove.Ps.Velocity[2]);
end;

procedure TTestPmoveCollisionTrace.DovrebbeFermarsiControIlPilastroSenzaAttraversarlo;
var
  LPmove: TPmove;
begin
  LPmove := Walk(300);
  // the pillar is at x = 100 and the box is 15 wide each side: it stops at 85
  Assert.IsTrue(LPmove.Ps.Origin[0] > 60, 'ha camminato');
  Assert.IsTrue(LPmove.Ps.Origin[0] <= 85.01, Format('x = %g', [LPmove.Ps.Origin[0]]));
end;

procedure TTestPmoveCollisionTrace.DovrebbeDareLoStessoRisultatoOgniVolta;
var
  LFirst, LSecond: TPmove;
begin
  LFirst := Walk(120);
  LSecond := Walk(120);
  Assert.IsTrue(CompareMem(@LFirst.Ps, @LSecond.Ps, SizeOf(LFirst.Ps)));
end;

procedure TTestPmoveCollisionTrace.DovrebbeCrearsiSuUnaMappa;
var
  LMover: IPmove;
begin
  LMover := TPmoveFactory.CreateForMap(FModel);
  Assert.IsNotNull(LMover);
  Assert.AreEqual(0, LMover.Counter);
end;

{ TTestPmoveOpenArena }

function TTestPmoveOpenArena.FindPak: string;
var
  LFolder: string;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (LFolder <> '') and TFile.Exists(LFolder) then
    LFolder := TPath.GetDirectoryName(LFolder);
  if (LFolder = '') or (not TDirectory.Exists(LFolder)) then
    LFolder := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8\baseoa');
  Result := TPath.Combine(LFolder, 'pak1-maps.pk3');
  if (LFolder = '') or (not TFile.Exists(Result)) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure TTestPmoveOpenArena.Visit(const AVisit: TProc<string, TBytes>);
var
  LZip: TZipFile;
  LName, LRejected: string;
  LBytes: TBytes;
  LCount, LTried: Integer;
begin
  LZip := TZipFile.Create;
  try
    LZip.Open(FindPak, zmRead);
    LCount := 0;
    LTried := 0;
    LRejected := '';
    for LName in LZip.FileNames do
      if LName.EndsWith('.bsp', True) then
      begin
        LZip.Read(LName, LBytes);
        Inc(LTried);
        try
          AVisit(LName, LBytes);
          Inc(LCount);
        except
          // the loader of the collision model checks the BSP strictly (CM_LoadMap of a stricter reader than
          // the original): a map it refuses is not what is under test here, the next one is tried
          on E: EQ3CollisionException do
            LRejected := LRejected + LName + ' (' + E.Message + ') ';
        end;
        if (LCount >= MAPS_TO_TRY) or (LTried >= MAPS_TO_LOOK_AT) then
          Break;
      end;
    if LCount = 0 then
      TTestSkip.Ignore('nessuna mappa di pak1-maps.pk3 che il modello di collisione accetti: ' + LRejected);
  finally
    LZip.Free;
  end;
end;

function TTestPmoveOpenArena.Spawns(const AEntities: AnsiString): TArray<TQ3Vec3>;
var
  LBlocks: TArray<string>;
  LBlock, LValue: string;
  LStart, LEnd: Integer;
  LParts: TArray<string>;
  LFormat: TFormatSettings;
  LPoint: TQ3Vec3;
  LList: TArray<TQ3Vec3>;
begin
  LFormat := TFormatSettings.Invariant;
  LList := nil;
  LBlocks := string(AEntities).Split(['}']);
  for LBlock in LBlocks do
  begin
    if Pos('"classname" "info_player_deathmatch"', LBlock) = 0 then
      Continue;
    LStart := Pos('"origin" "', LBlock);
    if LStart = 0 then
      Continue;
    LStart := LStart + Length('"origin" "');
    LEnd := Pos('"', LBlock, LStart);
    LValue := Copy(LBlock, LStart, LEnd - LStart);
    LParts := LValue.Split([' ']);
    if Length(LParts) <> 3 then
      Continue;
    LPoint[0] := StrToFloat(LParts[0], LFormat);
    LPoint[1] := StrToFloat(LParts[1], LFormat);
    // SelectSpawnPoint: the origin of the spot, 9 units up
    LPoint[2] := StrToFloat(LParts[2], LFormat) + 9;
    LList := LList + [LPoint];
  end;
  Result := LList;
end;

function TTestPmoveOpenArena.Run(const AModel: IQ3CollisionModel; const ASpawn: TQ3Vec3; const AMapIndex: Integer;
  out AFinal: TQ3PlayerState): Integer;
var
  LMover: IPmove;
  LPmove: TPmove;
  LIndex, LForward, LRight, LUp, LYaw: Integer;
  LTrace: TQ3Trace;
  LState: Cardinal;
  LOrigin, LMins, LMaxs: TQ3Vec3;
begin
  // the number of commands after which the player stood in a solid
  Result := 0;
  LMover := TPmoveFactory.CreateForMap(AModel);
  LPmove := Default(TPmove);
  LPmove.TraceMask := Q3_MASK_PLAYERSOLID;
  LPmove.Ps.CommandTime := 1000;
  LPmove.Ps.Gravity := 800;
  LPmove.Ps.Speed := 320;
  LPmove.Ps.ViewHeight := Q3_DEFAULT_VIEWHEIGHT;
  LPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  LPmove.Ps.Stats[Q3_STAT_HEALTH] := 100;
  LPmove.Ps.Stats[Q3_STAT_MAX_HEALTH] := 100;
  LPmove.Ps.Origin[0] := ASpawn[0];
  LPmove.Ps.Origin[1] := ASpawn[1];
  LPmove.Ps.Origin[2] := ASpawn[2];
  LState := Cardinal(2463534242) xor Cardinal(AMapIndex * 7919 + 1);
  LYaw := 0;
  LForward := 127;
  LRight := 0;
  for LIndex := 1 to COMMANDS_PER_SPAWN do
  begin
    // xorshift32: the same commands every time
    LState := LState xor (LState shl 13);
    LState := LState xor (LState shr 17);
    LState := LState xor (LState shl 5);
    if LState mod 16 = 0 then
      LYaw := (LYaw + Integer(LState shr 8) mod 20000) and 65535;
    if LState mod 12 = 1 then
      LForward := Integer((LState shr 4) mod 3) * 127 - 127;
    if LState mod 12 = 2 then
      LRight := Integer((LState shr 4) mod 3) * 127 - 127;
    if LState mod 24 = 3 then
      LUp := 127
    else
      LUp := 0;
    LPmove.Cmd.ServerTime := LPmove.Ps.CommandTime + 8 + Integer(LState shr 12) mod 26;
    LPmove.Cmd.Angles[Q3_YAW] := LYaw;
    LPmove.Cmd.ForwardMove := LForward;
    LPmove.Cmd.RightMove := LRight;
    LPmove.Cmd.UpMove := LUp;
    LMover.Execute(LPmove);
    LOrigin[0] := LPmove.Ps.Origin[0];
    LOrigin[1] := LPmove.Ps.Origin[1];
    LOrigin[2] := LPmove.Ps.Origin[2];
    LMins := LPmove.Mins;
    LMaxs := LPmove.Maxs;
    LTrace := AModel.BoxTrace(LOrigin, LOrigin, LMins, LMaxs, 0, Q3_MASK_PLAYERSOLID, False);
    if LTrace.AllSolid then
      Inc(Result);
  end;
  AFinal := LPmove.Ps;
end;

procedure TTestPmoveOpenArena.DovrebbeMuoversiNelleMappeSenzaFinireDentroIMuri;
var
  LSpawnsUsed, LFarthest: Integer;
begin
  LSpawnsUsed := 0;
  LFarthest := 0;
  Visit(
    procedure(AName: string; ABytes: TBytes)
    var
      LModel: IQ3CollisionModel;
      LSpawns: TArray<TQ3Vec3>;
      LFinal: TQ3PlayerState;
      LIndex, LMoved: Integer;
      LStartX, LStartY: Single;
    begin
      LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, ABytes, AnsiString(AName));
      LSpawns := Spawns(LModel.EntityString);
      for LIndex := 0 to High(LSpawns) do
      begin
        if LIndex >= SPAWNS_PER_MAP then
          Break;
        Assert.AreEqual(0, Run(LModel, LSpawns[LIndex], LIndex, LFinal), AName + ': comandi in cui il giocatore era in un muro');
        LStartX := LSpawns[LIndex][0];
        LStartY := LSpawns[LIndex][1];
        LMoved := Round(Sqrt(Sqr(LFinal.Origin[0] - LStartX) + Sqr(LFinal.Origin[1] - LStartY)));
        if LMoved > LFarthest then
          LFarthest := LMoved;
        Inc(LSpawnsUsed);
      end;
    end);
  Assert.IsTrue(LSpawnsUsed > 0, 'punti di partenza provati');
  Assert.IsTrue(LFarthest > 100, Format('il giocatore si e'' mosso (al piu'' %d unita'')', [LFarthest]));
end;


procedure TTestPmoveOpenArena.DovrebbeDareLoStessoRisultatoSuUnaMappaPiuVolte;
var
  LChecked: Integer;
begin
  LChecked := 0;
  Visit(
    procedure(AName: string; ABytes: TBytes)
    var
      LModel: IQ3CollisionModel;
      LSpawns: TArray<TQ3Vec3>;
      LFirst, LSecond: TQ3PlayerState;
    begin
      if LChecked > 0 then
        Exit;
      LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, ABytes, AnsiString(AName));
      LSpawns := Spawns(LModel.EntityString);
      if Length(LSpawns) = 0 then
        Exit;
      Run(LModel, LSpawns[0], 1, LFirst);
      Run(LModel, LSpawns[0], 1, LSecond);
      Assert.AreEqual(TTestFnv.Hash32(@LFirst, SizeOf(LFirst)), TTestFnv.Hash32(@LSecond, SizeOf(LSecond)), AName);
      Inc(LChecked);
    end);
  Assert.AreEqual(1, LChecked, 'mappe provate');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPmoveCollisionTrace);
  TDUnitX.RegisterTestFixture(TTestPmoveOpenArena);

end.
