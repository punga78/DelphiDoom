{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the check of a spawn spot (G_CheckSpot)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.SpawnSpot;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.SpawnSpot;

type
  /// <summary>A level with four players: bodies, a free or occupied position, and a log of the effects</summary>
  TSpotWorld = class(TInterfacedObject, ISpawnSpotHost)
  public
    HasBody: array[0..3] of Boolean;
    BodyX: array[0..3] of Integer;
    BodyY: array[0..3] of Integer;
    Free: Boolean;
    Height: Integer;
    Log: string;
    function PlayerHasBody(const APlayer: Integer): Boolean;
    function PlayerBodyX(const APlayer: Integer): Integer;
    function PlayerBodyY(const APlayer: Integer): Integer;
    procedure BeginPositionTest(const APlayer: Integer);
    procedure EndPositionTest(const APlayer: Integer);
    function SpotHeight(const APlayer, AX, AY: Integer): Integer;
    function PositionFree(const APlayer, AX, AY: Integer): Boolean;
    procedure FlushCorpse(const APlayer: Integer);
    procedure SpawnFog(const AX, AY, AHeight, AFineAngle: Integer);
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersSpawnSpot = class
  strict private
    function OldCheck(const AWorld: TSpotWorld; const APlayer, AX, AY, AAngle: Integer): Boolean;
  public
    [Test]
    procedure DovrebbeCalcolareLAngoloDellaNebbiaComeIlVecchioCodice;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
    [Test]
    procedure DovrebbeFermarsiAlPrimoGiocatoreSulPosto;
  end;

implementation

{ TSpotWorld }

function TSpotWorld.PlayerHasBody(const APlayer: Integer): Boolean;
begin
  Result := HasBody[APlayer];
end;

function TSpotWorld.PlayerBodyX(const APlayer: Integer): Integer;
begin
  Log := Log + 'x' + IntToStr(APlayer) + ';';
  Result := BodyX[APlayer];
end;

function TSpotWorld.PlayerBodyY(const APlayer: Integer): Integer;
begin
  Log := Log + 'y' + IntToStr(APlayer) + ';';
  Result := BodyY[APlayer];
end;

procedure TSpotWorld.BeginPositionTest(const APlayer: Integer);
begin
  Log := Log + 'begin;';
end;

procedure TSpotWorld.EndPositionTest(const APlayer: Integer);
begin
  Log := Log + 'end;';
end;

function TSpotWorld.SpotHeight(const APlayer, AX, AY: Integer): Integer;
begin
  Log := Log + 'height;';
  Result := Height;
end;

function TSpotWorld.PositionFree(const APlayer, AX, AY: Integer): Boolean;
begin
  Log := Log + 'pos;';
  Result := Free;
end;

procedure TSpotWorld.FlushCorpse(const APlayer: Integer);
begin
  Log := Log + 'flush;';
end;

procedure TSpotWorld.SpawnFog(const AX, AY, AHeight, AFineAngle: Integer);
begin
  Log := Log + 'fog' + IntToStr(AX) + ',' + IntToStr(AY) + ',' + IntToStr(AHeight) + ',' +
    IntToStr(AFineAngle) + ';';
end;

{ TTestThinkersSpawnSpot }

function TTestThinkersSpawnSpot.OldCheck(const AWorld: TSpotWorld; const APlayer, AX, AY,
  AAngle: Integer): Boolean;
const
  ANG45 = Cardinal($20000000);
var
  an: Cardinal;
  i: Integer;
  z: Integer;
begin
  // G_CheckSpot of g_game, copied (the objects of the engine are the world)
  if not AWorld.HasBody[APlayer] then
  begin
    for i := 0 to APlayer - 1 do
      if (AWorld.PlayerBodyX(i) = AX) and (AWorld.PlayerBodyY(i) = AY) then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
    Exit;
  end;

  AWorld.BeginPositionTest(APlayer);
  z := AWorld.SpotHeight(APlayer, AX, AY);
  if not AWorld.PositionFree(APlayer, AX, AY) then
  begin
    AWorld.EndPositionTest(APlayer);
    Result := False;
    Exit;
  end;
  AWorld.EndPositionTest(APlayer);

  AWorld.FlushCorpse(APlayer);

  an := (ANG45 * (AAngle div 45)) shr 19;
  AWorld.SpawnFog(AX, AY, z, an);
  Result := True;
end;

procedure TTestThinkersSpawnSpot.DovrebbeCalcolareLAngoloDellaNebbiaComeIlVecchioCodice;
const
  ANG45 = Cardinal($20000000);
var
  LAngle: Integer;
  LOld: Cardinal;
begin
  for LAngle := -720 to 720 do
  begin
    LOld := (ANG45 * (LAngle div 45)) shr 19;
    Assert.AreEqual(LOld, TSpawnSpot.FineAngleOf(LAngle), 'angolo ' + IntToStr(LAngle));
  end;
  Assert.AreEqual<Cardinal>(1024, TSpawnSpot.FineAngleOf(45));
end;

procedure TTestThinkersSpawnSpot.DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
var
  LOld, LNew: TSpotWorld;
  LNewRef, LOldRef: ISpawnSpotHost;
  LPlayer, LMask, LAngle, LIndex, LCase: Integer;
  LFree: Boolean;
  LResultOld, LResultNew: Boolean;
begin
  for LPlayer := 0 to 3 do
    for LMask := 0 to 15 do // which players already have a body
      for LFree := False to True do
        for LAngle := 0 to 7 do
          for LCase := 0 to 4 do // where the players with a body stand
          begin
            LOld := TSpotWorld.Create;
            LNew := TSpotWorld.Create;
            LNewRef := LNew;
            LOldRef := LOld;
            try
              for LIndex := 0 to 3 do
              begin
                LOld.HasBody[LIndex] := (LMask shr LIndex) and 1 <> 0;
                LOld.BodyX[LIndex] := 100 * ((LIndex + LCase) mod 3);
                LOld.BodyY[LIndex] := 200 * ((LIndex * LCase) mod 2);
                LNew.HasBody[LIndex] := LOld.HasBody[LIndex];
                LNew.BodyX[LIndex] := LOld.BodyX[LIndex];
                LNew.BodyY[LIndex] := LOld.BodyY[LIndex];
              end;
              LOld.Free := LFree;
              LNew.Free := LFree;
              LOld.Height := 77;
              LNew.Height := 77;
              LResultOld := OldCheck(LOld, LPlayer, 100, 200, LAngle * 45);
              LResultNew := TSpawnSpot.Check(LNew, LPlayer, 100, 200, LAngle * 45);
              Assert.AreEqual(LResultOld, LResultNew);
              Assert.AreEqual(LOld.Log, LNew.Log);
            finally
              LOldRef := nil;
              LNewRef := nil;
            end;
          end;
end;

procedure TTestThinkersSpawnSpot.DovrebbeFermarsiAlPrimoGiocatoreSulPosto;
var
  LWorld: TSpotWorld;
  LHost: ISpawnSpotHost;
begin
  LWorld := TSpotWorld.Create;
  LHost := LWorld;
  LWorld.BodyX[0] := 5;
  LWorld.BodyY[0] := 6;
  Assert.IsFalse(TSpawnSpot.Check(LHost, 2, 5, 6, 0));
  // the body of the player 1 was not read: it may not exist
  Assert.AreEqual('x0;y0;', LWorld.Log);
end;

end.
