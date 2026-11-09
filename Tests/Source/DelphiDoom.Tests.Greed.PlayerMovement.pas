{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedPlayerMovement                                    }
{                                                                              }
{  The oracle is TryDoor, TryMove, ClipMove and Thrust of xGreed as they were   }
{  (the doors in an array, the planes read from a second world)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PlayerMovement;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.PlayerMovement;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedPlayerMovement = class(TObject)
  private
    FWorld: IGreedWorld;
    FNetLog: TStringBuilder;
    FMovement: TGreedPlayerMovement;
    FPlayer: TGreedPlayerRecord;
    procedure Build(AWallAt: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaWorldNeHost;
    [Test]
    procedure DovrebbeMuoversiInUnaStanzaLibera;
    [Test]
    procedure DovrebbeFermarsiControUnMuro;
    [Test]
    procedure DovrebbeScivolareLungoUnMuro;
    [Test]
    procedure DovrebbeNonFermarsiControUnMuroSenzaCollisione;
    [Test]
    procedure DovrebbeNonUscireDalPavimento;
    [Test]
    procedure DovrebbeAprireUnaPortaCheSiUrta;
    [Test]
    procedure DovrebbeLasciarePassareUnaPortaAperta;
    [Test]
    procedure DovrebbeDireAgliAltriGiocatoriCheUnaPortaSiApre;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Greed.Intf, DelphiDoom.Greed.Factory, DelphiDoom.Greed.World, DelphiDoom.Greed.FixedMath,
  DelphiDoom.Greed.TrigTables, DelphiDoom.Greed.Terrain, DelphiDoom.Tests.Greed.Builders;

const
  FRACUNIT = 65536;
  FRACTILEUNIT = 1 shl 22;
  TILEUNIT = 64 * FRACUNIT;
  PLAYERSIZE = 16 * FRACUNIT;

type
  TNetHost = class(TInterfacedObject, IGreedMovementHost)
  strict private
    FLog: TStringBuilder;
    FNetMode: Boolean;
  public
    constructor Create(ALog: TStringBuilder; ANetMode: Boolean);
    function GetNetMode: Boolean;
    procedure NetOpenDoor(AX, AY: TGreedFixed);
  end;

constructor TNetHost.Create(ALog: TStringBuilder; ANetMode: Boolean);
begin
  inherited Create;
  FLog := ALog;
  FNetMode := ANetMode;
end;

function TNetHost.GetNetMode: Boolean;
begin
  Result := FNetMode;
end;

procedure TNetHost.NetOpenDoor(AX, AY: TGreedFixed);
begin
  FLog.Append('N').Append(AX).Append(',').Append(AY).Append(';');
end;

function NextRandom(var ASeed: Cardinal): Cardinal;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := ASeed shr 8;
end;

{ the original, with the doors in an array and the planes in a world that nobody changes }

type
  TOldDoor = record
    tilex, tiley: Integer;
    doorOpen, doorOpening, doorClosing, doorBlocked, doorBumpable: Boolean;
    orientation: TGreedDoorOrientation;
  end;

var
  OWorld: IGreedWorld;
  ODoors: array[0..31] of TOldDoor;
  ONumDoors: Integer;
  ODoorSound: Boolean;
  ODoorX, ODoorY: Integer;
  ONetMode: Boolean;
  ONetLog: TStringBuilder;
  OPlayer: TGreedPlayerRecord;

function OldFloorPic(spot: Integer): Integer;
begin
  Result := OWorld.GetValue(gpFloorPic, spot);
end;

function OldTryDoor(const xcenter, ycenter: Integer): Boolean;
var
  xl, yl, xh, yh, x, y, i: Integer;
begin
  xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  yl := (ycenter - PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
  yh := (ycenter + PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  for y := yl + 1 to yh do
    for x := xl to xh do
      if OWorld.GetMapFlags(y * 64 + x) and 128 <> 0 then
        for i := 0 to ONumDoors - 1 do
          if (ODoors[i].tilex = x) and (ODoors[i].tiley = y) and
            ((ODoors[i].orientation = gdoHorizontal) or (ODoors[i].orientation = gdoHorizontal2)) then
          begin
            if ODoors[i].doorOpen and not ODoors[i].doorClosing then
              Exit(True)
            else if not ODoors[i].doorOpen and ODoors[i].doorBumpable and not ODoors[i].doorOpening then
            begin
              ODoors[i].doorClosing := False;
              ODoors[i].doorOpening := True;
              ODoorSound := True;
              ODoorX := ODoors[i].tilex * FRACTILEUNIT;
              ODoorY := ODoors[i].tiley * FRACTILEUNIT;
              if ODoors[i].orientation = gdoHorizontal then
                OldTryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                OldTryDoor(xcenter - 64 * FRACUNIT, ycenter);
              if ONetMode then
                ONetLog.Append('N').Append(xcenter).Append(',').Append(ycenter).Append(';');
              Exit(False);
            end
            else if not ODoors[i].doorOpen and ODoors[i].doorBumpable and ODoors[i].doorClosing then
            begin
              ODoors[i].doorClosing := False;
              ODoors[i].doorOpening := True;
              ODoorSound := True;
              ODoorX := ODoors[i].tilex * FRACTILEUNIT;
              ODoorY := ODoors[i].tiley * FRACTILEUNIT;
              if ODoors[i].orientation = gdoHorizontal then
                OldTryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                OldTryDoor(xcenter - 64 * FRACUNIT, ycenter);
              if ONetMode then
                ONetLog.Append('N').Append(xcenter).Append(',').Append(ycenter).Append(';');
              Exit(False);
            end
            else
              Exit(False);
          end;
  xl := (xcenter - PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  yl := (ycenter - PLAYERSIZE) div FRACTILEUNIT;
  xh := (xcenter + PLAYERSIZE - (TILEUNIT div 2)) div FRACTILEUNIT;
  yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
  for y := yl to yh do
    for x := xl + 1 to xh do
      if OWorld.GetMapFlags(y * 64 + x) and 128 <> 0 then
        for i := 0 to ONumDoors - 1 do
          if (ODoors[i].tilex = x) and (ODoors[i].tiley = y) and
            ((ODoors[i].orientation = gdoVertical) or (ODoors[i].orientation = gdoVertical2)) then
          begin
            if ODoors[i].doorOpen and not ODoors[i].doorClosing then
              Exit(True)
            else if not ODoors[i].doorOpen and ODoors[i].doorBumpable and not ODoors[i].doorOpening then
            begin
              ODoors[i].doorOpening := True;
              ODoors[i].doorClosing := False;
              ODoorSound := True;
              ODoorX := ODoors[i].tilex * FRACTILEUNIT;
              ODoorY := ODoors[i].tiley * FRACTILEUNIT;
              if ODoors[i].orientation = gdoVertical then
                OldTryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                OldTryDoor(xcenter, ycenter - 64 * FRACUNIT);
              if ONetMode then
                ONetLog.Append('N').Append(xcenter).Append(',').Append(ycenter).Append(';');
              Exit(False);
            end
            else if not ODoors[i].doorOpen and ODoors[i].doorBumpable and ODoors[i].doorClosing then
            begin
              ODoors[i].doorClosing := False;
              ODoors[i].doorOpening := True;
              ODoorSound := True;
              ODoorX := ODoors[i].tilex * FRACTILEUNIT;
              ODoorY := ODoors[i].tiley * FRACTILEUNIT;
              if ODoors[i].orientation = gdoVertical then
                OldTryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                OldTryDoor(xcenter, ycenter - 64 * FRACUNIT);
              if ONetMode then
                ONetLog.Append('N').Append(xcenter).Append(',').Append(ycenter).Append(';');
              Exit(False);
            end
            else
              Exit(False);
          end;
  Result := True;
end;

function OldTryMove(const angle: Integer; xcenter, ycenter: Integer): Boolean;
var
  xl, yl, xh, yh, x, y, mapspot: Integer;
  pz: Integer;
begin
  if (angle < 256) or (angle > 768) then
  begin
    xl := xcenter div FRACTILEUNIT;
    xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
  end
  else if (angle > 256) and (angle < 768) then
  begin
    xh := xcenter div FRACTILEUNIT;
    xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  end
  else
  begin
    xh := (xcenter + PLAYERSIZE) div FRACTILEUNIT;
    xl := (xcenter - PLAYERSIZE) div FRACTILEUNIT;
  end;
  if angle > 512 then
  begin
    yl := ycenter div FRACTILEUNIT;
    yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
  end
  else if (angle < 512) and (angle <> 0) then
  begin
    yl := (ycenter - PLAYERSIZE) div FRACTILEUNIT;
    yh := ycenter div FRACTILEUNIT;
  end
  else
  begin
    yl := (ycenter - PLAYERSIZE) div FRACTILEUNIT;
    yh := (ycenter + PLAYERSIZE) div FRACTILEUNIT;
  end;
  pz := OPlayer.Z - OPlayer.Height + (26 * FRACUNIT);
  for y := yl to yh do
    for x := xl to xh do
    begin
      mapspot := 64 * y + x;
      if (y > yl) and (OWorld.GetValue(gpNorthWall, mapspot) <> 0) and
        (OWorld.GetValue(gpNorthFlags, mapspot) and (1 shl 5) = 0) then
        Exit(False);
      if (x > xl) and (OWorld.GetValue(gpWestWall, mapspot) <> 0) and
        (OWorld.GetValue(gpWestFlags, mapspot) and (1 shl 5) = 0) then
        Exit(False);
      if mapspot <> OPlayer.MapSpot then
      begin
        if (OWorld.GetValue(gpMapSprites, mapspot) > 0) and (OWorld.GetValue(gpMapSprites, mapspot) < 128) then
          Exit(False);
        if TGreedTerrain.FloorZ(OWorld, (x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) > pz then
          Exit(False);
        if TGreedTerrain.CeilingZ(OWorld, (x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) <
          OPlayer.Z + (10 * FRACUNIT) then
          Exit(False);
      end;
    end;
  Result := True;
end;

function OldClipMove(const angle: Integer; const xmove, ymove: Integer): Boolean;
var
  dx, dy, angle2: Integer;
begin
  dx := OPlayer.X + xmove;
  dy := OPlayer.Y + ymove;
  if OldTryMove(angle, dx, dy) and OldTryDoor(dx, dy) then
  begin
    if OldFloorPic((dy div FRACTILEUNIT) * 64 + (dx div FRACTILEUNIT)) = 0 then
      Exit(False);
    OPlayer.X := OPlayer.X + xmove;
    OPlayer.Y := OPlayer.Y + ymove;
    Exit(True);
  end;
  if xmove > 0 then
    angle2 := 0
  else
    angle2 := 512;
  if OldTryMove(angle2, dx, OPlayer.Y) and OldTryDoor(dx, OPlayer.Y) then
  begin
    if OldFloorPic((OPlayer.Y div FRACTILEUNIT) * 64 + (dx div FRACTILEUNIT)) = 0 then
      Exit(False);
    OPlayer.X := OPlayer.X + xmove;
    Exit(True);
  end;
  if ymove > 0 then
    angle2 := 768
  else
    angle2 := 256;
  if OldTryMove(angle2, OPlayer.X, dy) and OldTryDoor(OPlayer.X, dy) then
  begin
    if OldFloorPic((dy div FRACTILEUNIT) * 64 + (OPlayer.X div FRACTILEUNIT)) = 0 then
      Exit(False);
    OPlayer.Y := OPlayer.Y + ymove;
    Exit(True);
  end;
  Result := False;
end;

function OldThrust(const ang: Integer; const speed: Integer): Boolean;
var
  xmove, ymove, angle: Integer;
begin
  angle := ang and 1023;
  xmove := TGreedFixedMath.Mul(speed, TGreedTrigTables.Cosine(angle));
  ymove := -TGreedFixedMath.Mul(speed, TGreedTrigTables.Sine(angle));
  Result := OldClipMove(angle, xmove, ymove);
  OPlayer.MapSpot := (OPlayer.Y div FRACTILEUNIT) * 64 + (OPlayer.X div FRACTILEUNIT);
end;

{ TTestGreedPlayerMovement }

procedure TTestGreedPlayerMovement.Setup;
begin
  FNetLog := TStringBuilder.Create;
  FWorld := TGreedWorld.Create;
  FMovement := nil;
end;

procedure TTestGreedPlayerMovement.TearDown;
begin
  FreeAndNil(FMovement);
  FreeAndNil(FNetLog);
end;

// A room of floor with 20 units: a wall on the north side of the tile AWallAt (when it is 0 or more)
procedure TTestGreedPlayerMovement.Build(AWallAt: Integer);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := TGreedLumps.MapBytes(nil);
  FillChar(LBytes[0], Length(LBytes), 0);
  for LIndex := 0 to 4095 do
  begin
    LBytes[Ord(gpFloorPic) * 4096 + LIndex] := 1;
    LBytes[Ord(gpFloorHeight) * 4096 + LIndex] := 0;
    LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] := 100;
  end;
  if AWallAt >= 0 then
    LBytes[Ord(gpNorthWall) * 4096 + AWallAt] := 1;
  FWorld.Load(TGreedFactory.CreateMapReader.Read(LBytes));
  FreeAndNil(FMovement);
  FMovement := TGreedPlayerMovement.Create(FWorld, TNetHost.Create(FNetLog, True));
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FPlayer.X := 10 * TILEUNIT + 32 * FRACUNIT;
  FPlayer.Y := 10 * TILEUNIT + 32 * FRACUNIT;
  FPlayer.Height := 40 * FRACUNIT;
  FPlayer.Z := 40 * FRACUNIT;
  FPlayer.MapSpot := 10 * 64 + 10;
end;

procedure TTestGreedPlayerMovement.DovrebbeSollevareSenzaWorldNeHost;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TGreedPlayerMovement.Create(nil, TNetHost.Create(FNetLog, False)).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'world');
  LRaised := False;
  try
    TGreedPlayerMovement.Create(FWorld, nil).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'host');
end;

procedure TTestGreedPlayerMovement.DovrebbeMuoversiInUnaStanzaLibera;
var
  LOldX: Integer;
begin
  Build(-1);
  LOldX := FPlayer.X;
  Assert.IsTrue(FMovement.Thrust(FPlayer, GREED_EAST, 5 * FRACUNIT));
  Assert.IsTrue(FPlayer.X > LOldX);
  Assert.AreEqual(10 * 64 + 10, FPlayer.MapSpot);
end;

procedure TTestGreedPlayerMovement.DovrebbeFermarsiControUnMuro;
var
  LOldY, LIndex: Integer;
begin
  // a wall on the north side of the tile 10, 9 is the border between the tiles 10, 9 and 10, 10... the player
  // goes north from the middle of the tile 10, 10 and stops 16 units from the wall
  Build(10 * 64 + 10);
  LOldY := FPlayer.Y;
  // with a move that has no x part the slide along x succeeds with no move: it never gives False, so the
  // number of steps is limited (the original does the same)
  for LIndex := 1 to 200 do
    FMovement.Thrust(FPlayer, GREED_NORTH, 5 * FRACUNIT);
  Assert.IsTrue(FPlayer.Y < LOldY);
  Assert.IsTrue(FPlayer.Y >= 10 * TILEUNIT, 'it did not cross the wall');
end;

procedure TTestGreedPlayerMovement.DovrebbeScivolareLungoUnMuro;
var
  LOldX: Integer;
begin
  Build(10 * 64 + 10);
  FPlayer.Y := 10 * TILEUNIT + 16 * FRACUNIT + 100;
  LOldX := FPlayer.X;
  // the move goes north-east, into the wall: it goes along the wall to the east
  Assert.IsTrue(FMovement.Thrust(FPlayer, 128, 5 * FRACUNIT));
  Assert.IsTrue(FPlayer.X > LOldX);
end;

procedure TTestGreedPlayerMovement.DovrebbeNonFermarsiControUnMuroSenzaCollisione;
begin
  Build(10 * 64 + 10);
  FWorld.SetValue(gpNorthFlags, 10 * 64 + 10, GREED_F_NOCLIP);
  FPlayer.Y := 10 * TILEUNIT + 17 * FRACUNIT;
  Assert.IsTrue(FMovement.Thrust(FPlayer, GREED_NORTH, 5 * FRACUNIT));
end;

procedure TTestGreedPlayerMovement.DovrebbeNonUscireDalPavimento;
begin
  Build(-1);
  FWorld.SetValue(gpFloorPic, 10 * 64 + 11, 0);
  FPlayer.X := 10 * TILEUNIT + 63 * FRACUNIT;
  Assert.IsFalse(FMovement.ClipMove(FPlayer, GREED_EAST, 2 * FRACUNIT, 0));
end;

procedure TTestGreedPlayerMovement.DovrebbeAprireUnaPortaCheSiUrta;
var
  LIndex: Integer;
  LDoor: TGreedDoor;
begin
  Build(-1);
  LIndex := FWorld.AddDoor(11, 10);
  LDoor := FWorld.GetDoor(LIndex);
  LDoor.Orientation := gdoVertical;
  LDoor.Bumpable := True;
  FWorld.SetDoor(LIndex, LDoor);
  FPlayer.X := 10 * TILEUNIT + 60 * FRACUNIT;
  Assert.IsFalse(FMovement.TryDoor(11 * TILEUNIT + 40 * FRACUNIT, FPlayer.Y));
  Assert.IsTrue(FWorld.GetDoor(LIndex).Opening);
  Assert.IsTrue(FMovement.DoorSound);
  Assert.AreEqual(11 * (1 shl 22), FMovement.DoorX);
  Assert.AreEqual(10 * (1 shl 22), FMovement.DoorY);
  Assert.IsTrue(FNetLog.Length > 0, 'told to the net');
end;

procedure TTestGreedPlayerMovement.DovrebbeLasciarePassareUnaPortaAperta;
var
  LIndex: Integer;
  LDoor: TGreedDoor;
begin
  Build(-1);
  LIndex := FWorld.AddDoor(11, 10);
  LDoor := FWorld.GetDoor(LIndex);
  LDoor.Orientation := gdoVertical;
  LDoor.Open := True;
  FWorld.SetDoor(LIndex, LDoor);
  Assert.IsTrue(FMovement.TryDoor(11 * TILEUNIT + 40 * FRACUNIT, 10 * TILEUNIT + 32 * FRACUNIT));
  Assert.IsFalse(FMovement.DoorSound);
end;

procedure TTestGreedPlayerMovement.DovrebbeDireAgliAltriGiocatoriCheUnaPortaSiApre;
var
  LIndex: Integer;
  LDoor: TGreedDoor;
begin
  Build(-1);
  FreeAndNil(FMovement);
  FMovement := TGreedPlayerMovement.Create(FWorld, TNetHost.Create(FNetLog, False));
  LIndex := FWorld.AddDoor(11, 10);
  LDoor := FWorld.GetDoor(LIndex);
  LDoor.Orientation := gdoVertical;
  LDoor.Bumpable := True;
  FWorld.SetDoor(LIndex, LDoor);
  FMovement.TryDoor(11 * TILEUNIT + 40 * FRACUNIT, 10 * TILEUNIT + 32 * FRACUNIT);
  Assert.AreEqual(0, FNetLog.Length, 'not in a net game');
end;

procedure TTestGreedPlayerMovement.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LSeed: Cardinal;
  LScenario, LStep, LIndex, LAngle, LSpeed, LDoorCount: Integer;
  LBytes: TBytes;
  LMap: IGreedMap;
  LWorldNew: IGreedWorld;
  LNew, LOld: Boolean;
  LDoor: TGreedDoor;
  LNetLogNew: TStringBuilder;
  LMoves: Integer;
  LMovement: TGreedPlayerMovement;
begin
  LSeed := 20260101;
  LMoves := 0;
  for LScenario := 1 to 120 do
  begin
    LBytes := TGreedLumps.MapBytes(nil);
    FillChar(LBytes[0], Length(LBytes), 0);
    for LIndex := 0 to 4095 do
    begin
      if NextRandom(LSeed) mod 10 = 0 then
        LBytes[Ord(gpNorthWall) * 4096 + LIndex] := 1;
      if NextRandom(LSeed) mod 10 = 0 then
        LBytes[Ord(gpWestWall) * 4096 + LIndex] := 1;
      LBytes[Ord(gpNorthFlags) * 4096 + LIndex] := Byte(NextRandom(LSeed) mod 2) shl 5;
      LBytes[Ord(gpWestFlags) * 4096 + LIndex] := Byte(NextRandom(LSeed) mod 2) shl 5;
      if NextRandom(LSeed) mod 20 = 0 then
        LBytes[Ord(gpMapSprites) * 4096 + LIndex] := Byte(NextRandom(LSeed) mod 140);
      if NextRandom(LSeed) mod 25 <> 0 then
        LBytes[Ord(gpFloorPic) * 4096 + LIndex] := 1;
      LBytes[Ord(gpFloorHeight) * 4096 + LIndex] := Byte(NextRandom(LSeed) mod 30);
      LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] := 70 + Byte(NextRandom(LSeed) mod 60);
    end;
    LMap := TGreedFactory.CreateMapReader.Read(LBytes);
    LWorldNew := TGreedWorld.Create;
    LWorldNew.Load(LMap);
    OWorld := TGreedWorld.Create;
    OWorld.Load(LMap);
    ONumDoors := 0;
    FillChar(ODoors, SizeOf(ODoors), 0);
    LDoorCount := 6 + Integer(NextRandom(LSeed) mod 10);
    for LIndex := 0 to LDoorCount - 1 do
    begin
      LDoor := Default(TGreedDoor);
      LDoor.TileX := 4 + Integer(NextRandom(LSeed) mod 50);
      LDoor.TileY := 4 + Integer(NextRandom(LSeed) mod 50);
      LDoor.Orientation := TGreedDoorOrientation(NextRandom(LSeed) mod 4);
      LDoor.Open := NextRandom(LSeed) mod 4 = 0;
      LDoor.Opening := NextRandom(LSeed) mod 4 = 0;
      LDoor.Closing := NextRandom(LSeed) mod 4 = 0;
      LDoor.Bumpable := NextRandom(LSeed) mod 3 <> 0;
      LWorldNew.SetDoor(LWorldNew.AddDoor(LDoor.TileX, LDoor.TileY), LDoor);
      OWorld.SetDoor(OWorld.AddDoor(LDoor.TileX, LDoor.TileY), LDoor);
      ODoors[ONumDoors].tilex := LDoor.TileX;
      ODoors[ONumDoors].tiley := LDoor.TileY;
      ODoors[ONumDoors].orientation := LDoor.Orientation;
      ODoors[ONumDoors].doorOpen := LDoor.Open;
      ODoors[ONumDoors].doorOpening := LDoor.Opening;
      ODoors[ONumDoors].doorClosing := LDoor.Closing;
      ODoors[ONumDoors].doorBumpable := LDoor.Bumpable;
      Inc(ONumDoors);
    end;
    ONetMode := NextRandom(LSeed) mod 2 = 0;
    LNetLogNew := TStringBuilder.Create;
    ONetLog := TStringBuilder.Create;
    LMovement := TGreedPlayerMovement.Create(LWorldNew, TNetHost.Create(LNetLogNew, ONetMode));
    try
      FillChar(FPlayer, SizeOf(FPlayer), 0);
      FPlayer.X := (6 + Integer(NextRandom(LSeed) mod 50)) * TILEUNIT + Integer(NextRandom(LSeed) mod 4000) * 1000;
      FPlayer.Y := (6 + Integer(NextRandom(LSeed) mod 50)) * TILEUNIT + Integer(NextRandom(LSeed) mod 4000) * 1000;
      FPlayer.Height := 40 * FRACUNIT;
      FPlayer.Z := FPlayer.Height + Integer(NextRandom(LSeed) mod 20) * FRACUNIT;
      FPlayer.MapSpot := (FPlayer.Y div FRACTILEUNIT) * 64 + (FPlayer.X div FRACTILEUNIT);
      OPlayer := FPlayer;
      ODoorSound := False;
      LMovement.DoorSound := False;
      for LStep := 1 to 150 do
      begin
        LAngle := Integer(NextRandom(LSeed) mod 2048) - 512;
        LSpeed := Integer(NextRandom(LSeed) mod 12) * FRACUNIT + Integer(NextRandom(LSeed) mod 65536);
        // keep the player inside the part of the map that the oracle can read
        if (FPlayer.X < 5 * TILEUNIT) or (FPlayer.X > 58 * TILEUNIT) or (FPlayer.Y < 5 * TILEUNIT) or
          (FPlayer.Y > 58 * TILEUNIT) then
          Break;
        LNew := LMovement.Thrust(FPlayer, LAngle, LSpeed);
        LOld := OldThrust(LAngle, LSpeed);
        if LNew then
          Inc(LMoves);
        Assert.AreEqual(LOld, LNew, Format('result, scenario %d step %d', [LScenario, LStep]));
        Assert.AreEqual(OPlayer.X, FPlayer.X, 'x');
        Assert.AreEqual(OPlayer.Y, FPlayer.Y, 'y');
        Assert.AreEqual(OPlayer.MapSpot, FPlayer.MapSpot, 'mapspot');
        Assert.AreEqual(ODoorSound, LMovement.DoorSound, 'door sound');
        if ODoorSound then
        begin
          Assert.AreEqual(ODoorX, LMovement.DoorX, 'door x');
          Assert.AreEqual(ODoorY, LMovement.DoorY, 'door y');
        end;
        Assert.AreEqual(ONetLog.ToString, LNetLogNew.ToString, 'net');
      end;
      for LIndex := 0 to ONumDoors - 1 do
      begin
        LDoor := LWorldNew.GetDoor(LIndex);
        Assert.AreEqual(ODoors[LIndex].doorOpening, LDoor.Opening, 'opening');
        Assert.AreEqual(ODoors[LIndex].doorClosing, LDoor.Closing, 'closing');
        Assert.AreEqual(ODoors[LIndex].doorOpen, LDoor.Open, 'open');
      end;
    finally
      LMovement.Free;
      LNetLogNew.Free;
      ONetLog.Free;
    end;
  end;
  Assert.IsTrue(LMoves > 2000, 'the scenarios move the player often enough');
end;

end.
