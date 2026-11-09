{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedPlayerRules                                       }
{                                                                              }
{  The oracles are heal, medpaks, hurt, addscore and newplayer of utils.pas of  }
{  xGreed as they were (the globals are variables of the unit, the calls of     }
{  the game are written in a log)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PlayerRules;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Player.Intf,
  DelphiDoom.Greed.Types;

type
  TFakePlayerGame = class(TInterfacedObject, IGreedPlayerContext, IGreedPlayerFeedback)
  public
    Log: TStringList;
    God: Boolean;
    Effect: Integer;
    Net: Boolean;
    Time: Integer;
    HurtSoundTime: Integer;
    constructor Create;
    destructor Destroy; override;
    function GetGodMode: Boolean;
    function GetSpecialEffect: Integer;
    function GetNetMode: Boolean;
    function GetTimeCount: Integer;
    function GetNetHurtSoundTime: Integer;
    procedure SetNetHurtSoundTime(AValue: Integer);
    procedure ShowHurtBorder;
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure PlayNetSound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedPlayerRules = class(TObject)
  private
    FGame: TFakePlayerGame;
    FGameIntf: IInterface;
    FSut: TObject;
    FPlayer: TGreedPlayerRecord;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCuraLoScudoFinoAlMassimo;
    [Test]
    procedure DovrebbeCurareLaSaluteSoloSeIlGiocatoreEVivo;
    [Test]
    procedure DovrebbeTogliereIlDannoAlloScudoPrima;
    [Test]
    procedure DovrebbeTogliereLaSaluteQuandoLoScudoFinisce;
    [Test]
    procedure DovrebbeSuonareDueVolteLaMorte;
    [Test]
    procedure DovrebbeNonFarNienteInGodMode;
    [Test]
    procedure DovrebbeDividereIlDannoPerTreConLInvisibilita;
    [Test]
    procedure DovrebbeCurareConLaPilloleReverso;
    [Test]
    procedure DovrebbeDirePocoAgliAltriInReteSoloUnaVoltaOgni35Tic;
    [Test]
    procedure DovrebbeLimitareIlPunteggio;
    [Test]
    procedure DovrebbeIniziareUnaNuovaPartitaDiOgniPersonaggio;
    [Test]
    procedure DovrebbeRifiutareUnPersonaggioChePNonCe;
    [Test]
    procedure DovrebbeSollevareSenzaDipendenze;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Greed.PlayerRules;

{ TFakePlayerGame }

constructor TFakePlayerGame.Create;
begin
  inherited Create;
  Log := TStringList.Create;
end;

destructor TFakePlayerGame.Destroy;
begin
  Log.Free;
  inherited;
end;

function TFakePlayerGame.GetGodMode: Boolean;
begin
  Result := God;
end;

function TFakePlayerGame.GetSpecialEffect: Integer;
begin
  Result := Effect;
end;

function TFakePlayerGame.GetNetMode: Boolean;
begin
  Result := Net;
end;

function TFakePlayerGame.GetTimeCount: Integer;
begin
  Result := Time;
end;

function TFakePlayerGame.GetNetHurtSoundTime: Integer;
begin
  Result := HurtSoundTime;
end;

procedure TFakePlayerGame.SetNetHurtSoundTime(AValue: Integer);
begin
  HurtSoundTime := AValue;
end;

procedure TFakePlayerGame.ShowHurtBorder;
begin
  Log.Add('border');
end;

procedure TFakePlayerGame.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Log.Add(Format('sound %d %d %d %d', [ASound, AVariation, AX, AY]));
end;

procedure TFakePlayerGame.PlayNetSound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  Log.Add(Format('net %d %d %d %d', [ASound, AVariation, AX, AY]));
end;

// ---- the code of utils.pas, as it was ----

var
  OPlayer: TGreedPlayerRecord;
  OGod: Boolean;
  OEffect: Integer;
  ONet: Boolean;
  OTime: Integer;
  OHurtSoundTime: Integer;
  OLog: TStringList;

procedure OldHeal(const n: integer);
begin
  OPlayer.Shield := OPlayer.Shield + n;
  if OPlayer.Shield > OPlayer.MaxShield then
    OPlayer.Shield := OPlayer.MaxShield;
  OLog.Add('border');
end;

procedure OldMedpaks(const n: integer);
begin
  if OPlayer.Angst <= 0 then
    exit;
  OPlayer.Angst := OPlayer.Angst + n;
  if OPlayer.Angst > OPlayer.MaxAngst then
    OPlayer.Angst := OPlayer.MaxAngst;
  OLog.Add('border');
end;

procedure OldSound(const n, v, x, y: Integer);
begin
  OLog.Add(Format('sound %d %d %d %d', [n, v, x, y]));
end;

procedure OldNetSound(const n, v, x, y: Integer);
begin
  OLog.Add(Format('net %d %d %d %d', [n, v, x, y]));
end;

procedure OldHurt(n: integer);
begin
  if OGod or (OPlayer.Angst = 0) then
    exit;
  if OEffect = 4 then
    n := n div 3;
  if OEffect = 1 then
  begin
    OldMedpaks(n div 2);
    OldHeal(n div 2);
    exit;
  end;
  OPlayer.Status := 1;
  if n > OPlayer.Shield then
  begin
    n := n - OPlayer.Shield;
    OPlayer.Shield := 0;
    OPlayer.Angst := OPlayer.Angst - n;
    if OPlayer.Angst < 0 then
      OPlayer.Angst := 0;
  end
  else
    OPlayer.Shield := OPlayer.Shield - n;
  OLog.Add('border');
  if OPlayer.Angst = 0 then
  begin
    OldSound(34 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
    if ONet then
      OldNetSound(34 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
    OldSound(34 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
    if ONet then
      OldNetSound(34 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
  end
  else
  begin
    OldSound(29 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
    if ONet and (OTime > OHurtSoundTime) then
    begin
      OldNetSound(29 + OPlayer.CharType, 15, OPlayer.X, OPlayer.Y);
      OHurtSoundTime := OTime + 35;
    end;
  end;
end;

procedure OldAddScore(const n: integer);
begin
  OPlayer.Score := OPlayer.Score + n;
  if OPlayer.Score > 2000000000 then
    OPlayer.Score := 0;
  OPlayer.LevelScore := OPlayer.LevelScore - n;
  if OPlayer.LevelScore < 0 then
    OPlayer.LevelScore := 0;
end;

const
  OLD_PLAYERMOVESPEED = (65536 * 5) div 2;
  OLD_HEIGHTS: array[0..5] of Integer = (42 * 65536, 35 * 65536, 50 * 65536, 35 * 65536, 38 * 65536, 32 * 65536);
  OLD_MAXSHIELD: array[0..5] of Integer = (700, 400, 500, 300, 500, 700);
  OLD_MAXANGST: array[0..5] of Integer = (600, 400, 700, 500, 500, 700);
  OLD_WALKMOD: array[0..5] of Integer = (-OLD_PLAYERMOVESPEED, OLD_PLAYERMOVESPEED, -OLD_PLAYERMOVESPEED,
    OLD_PLAYERMOVESPEED, 0, OLD_PLAYERMOVESPEED * 3 div 2);
  OLD_RUNMOD: array[0..5] of Integer = (-OLD_PLAYERMOVESPEED, OLD_PLAYERMOVESPEED div 2, -OLD_PLAYERMOVESPEED,
    OLD_PLAYERMOVESPEED div 2, 0, OLD_PLAYERMOVESPEED * 2);
  OLD_JUMPMOD: array[0..5] of Integer = (-65536, 0, 0, 0, -65536, 0);

// newplayer, without MS_CheckParm('char'), resetengine and newmap
procedure OldNewPlayer(const map: integer; chartype: integer; const difficulty, levelscore, windowHeight: integer);
begin
  FillChar(OPlayer, SizeOf(OPlayer), 0);
  OPlayer.ScrollMin := 0;
  OPlayer.ScrollMax := windowHeight;
  OPlayer.X := -1;
  OPlayer.Map := map;
  OPlayer.Height := OLD_HEIGHTS[chartype];
  OPlayer.MaxAngst := OLD_MAXANGST[chartype];
  OPlayer.MaxShield := OLD_MAXSHIELD[chartype];
  OPlayer.WalkMod := OLD_WALKMOD[chartype];
  OPlayer.RunMod := OLD_RUNMOD[chartype];
  OPlayer.JumpMod := OLD_JUMPMOD[chartype];
  OPlayer.Shield := OPlayer.MaxShield;
  OPlayer.Angst := OPlayer.MaxAngst;
  OPlayer.LevelScore := levelscore;
  OPlayer.CharType := chartype;
  OPlayer.Difficulty := difficulty;
  case chartype of
  0:
    begin
      OPlayer.Weapons[0] := 7;
      OPlayer.Weapons[1] := 1;
    end;
  1:
    begin
      OPlayer.Weapons[0] := 8;
      OPlayer.Weapons[1] := 9;
    end;
  2:
    begin
      OPlayer.Weapons[0] := 13;
      OPlayer.Weapons[1] := 11;
    end;
  3:
    begin
      OPlayer.Weapons[0] := 14;
      OPlayer.Weapons[1] := 10;
    end;
  4:
    begin
      OPlayer.Weapons[0] := 15;
      OPlayer.Weapons[1] := 12;
    end;
  5:
    begin
      OPlayer.Weapons[0] := 8;
      OPlayer.Weapons[1] := 9;
    end;
  end;
  OPlayer.Weapons[2] := -1;
  OPlayer.Weapons[3] := -1;
  OPlayer.Weapons[4] := -1;
  OPlayer.Ammo[0] := 100;
  OPlayer.Ammo[1] := 100;
  OPlayer.Ammo[2] := 100;
  OPlayer.Inventory[7] := 2;
  OPlayer.Inventory[5] := 2;
  OPlayer.Inventory[4] := 2;
  OPlayer.Inventory[2] := 4;
end;

function Next(var ASeed: Cardinal): Cardinal;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := ASeed shr 8;
end;

function Same(const A, B: TGreedPlayerRecord): Boolean;
begin
  Result := CompareMem(@A, @B, SizeOf(A));
end;

{ TTestGreedPlayerRules }

procedure TTestGreedPlayerRules.Setup;
begin
  FGame := TFakePlayerGame.Create;
  FGameIntf := FGame;
  FSut := TGreedPlayerRules.Create(FGame as IGreedPlayerContext, FGame as IGreedPlayerFeedback);
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FPlayer.Shield := 100;
  FPlayer.MaxShield := 300;
  FPlayer.Angst := 200;
  FPlayer.MaxAngst := 400;
  FPlayer.CharType := 2;
  FPlayer.X := 5;
  FPlayer.Y := 6;
end;

procedure TTestGreedPlayerRules.TearDown;
begin
  FSut.Free;
  FGameIntf := nil;
end;

procedure TTestGreedPlayerRules.DovrebbeCuraLoScudoFinoAlMassimo;
begin
  TGreedPlayerRules(FSut).Heal(FPlayer, 50);
  Assert.AreEqual(150, FPlayer.Shield);
  TGreedPlayerRules(FSut).Heal(FPlayer, 500);
  Assert.AreEqual(300, FPlayer.MaxShield);
  Assert.AreEqual(300, FPlayer.Shield);
  Assert.AreEqual('border', FGame.Log[0]);
end;

procedure TTestGreedPlayerRules.DovrebbeCurareLaSaluteSoloSeIlGiocatoreEVivo;
begin
  TGreedPlayerRules(FSut).MedPaks(FPlayer, 1000);
  Assert.AreEqual(400, FPlayer.Angst);
  FPlayer.Angst := 0;
  FGame.Log.Clear;
  TGreedPlayerRules(FSut).MedPaks(FPlayer, 50);
  Assert.AreEqual(0, FPlayer.Angst);
  Assert.AreEqual(0, FGame.Log.Count);
end;

procedure TTestGreedPlayerRules.DovrebbeTogliereIlDannoAlloScudoPrima;
begin
  TGreedPlayerRules(FSut).Hurt(FPlayer, 30);
  Assert.AreEqual(70, FPlayer.Shield);
  Assert.AreEqual(200, FPlayer.Angst);
  Assert.AreEqual(1, FPlayer.Status);
  Assert.AreEqual('border', FGame.Log[0]);
  Assert.AreEqual('sound 31 15 5 6', FGame.Log[1]);
end;

procedure TTestGreedPlayerRules.DovrebbeTogliereLaSaluteQuandoLoScudoFinisce;
begin
  TGreedPlayerRules(FSut).Hurt(FPlayer, 150);
  Assert.AreEqual(0, FPlayer.Shield);
  Assert.AreEqual(150, FPlayer.Angst);
end;

procedure TTestGreedPlayerRules.DovrebbeSuonareDueVolteLaMorte;
begin
  TGreedPlayerRules(FSut).Hurt(FPlayer, 5000);
  Assert.AreEqual(0, FPlayer.Angst);
  Assert.AreEqual(3, FGame.Log.Count);
  Assert.AreEqual('sound 36 15 5 6', FGame.Log[1]);
  Assert.AreEqual('sound 36 15 5 6', FGame.Log[2]);
  // dead: nothing more
  FGame.Log.Clear;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 5);
  Assert.AreEqual(0, FGame.Log.Count);
end;

procedure TTestGreedPlayerRules.DovrebbeNonFarNienteInGodMode;
begin
  FGame.God := True;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 5000);
  Assert.AreEqual(100, FPlayer.Shield);
  Assert.AreEqual(0, FGame.Log.Count);
  Assert.AreEqual(0, FPlayer.Status);
end;

procedure TTestGreedPlayerRules.DovrebbeDividereIlDannoPerTreConLInvisibilita;
begin
  FGame.Effect := GREED_SE_INVISIBILITY;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 90);
  Assert.AreEqual(70, FPlayer.Shield);
end;

procedure TTestGreedPlayerRules.DovrebbeCurareConLaPilloleReverso;
begin
  FGame.Effect := GREED_SE_REVERSO_PILL;
  FPlayer.Angst := 100;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 80);
  Assert.AreEqual(140, FPlayer.Angst);
  Assert.AreEqual(140, FPlayer.Shield);
  Assert.AreEqual(0, FPlayer.Status);
end;

procedure TTestGreedPlayerRules.DovrebbeDirePocoAgliAltriInReteSoloUnaVoltaOgni35Tic;
begin
  FGame.Net := True;
  FGame.Time := 100;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 10);
  Assert.AreEqual(135, FGame.HurtSoundTime);
  Assert.AreEqual('net 31 15 5 6', FGame.Log[2]);
  FGame.Log.Clear;
  FGame.Time := 120;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 10);
  Assert.AreEqual(2, FGame.Log.Count);
  FGame.Log.Clear;
  FGame.Time := 136;
  TGreedPlayerRules(FSut).Hurt(FPlayer, 10);
  Assert.AreEqual(3, FGame.Log.Count);
end;

procedure TTestGreedPlayerRules.DovrebbeLimitareIlPunteggio;
begin
  FPlayer.Score := 1999999990;
  FPlayer.LevelScore := 5;
  TGreedPlayerRules.AddScore(FPlayer, 20);
  Assert.AreEqual(0, FPlayer.Score);
  Assert.AreEqual(0, FPlayer.LevelScore);
  TGreedPlayerRules.AddScore(FPlayer, 3);
  Assert.AreEqual(3, FPlayer.Score);
end;

procedure TTestGreedPlayerRules.DovrebbeIniziareUnaNuovaPartitaDiOgniPersonaggio;
var
  LType: Integer;
begin
  for LType := 0 to GREED_CHAR_TYPES - 1 do
  begin
    TGreedPlayerRules.NewPlayer(FPlayer, 3, LType, 2, 700, 200);
    Assert.AreEqual(-1, FPlayer.X);
    Assert.AreEqual(FPlayer.MaxShield, FPlayer.Shield);
    Assert.AreEqual(-1, FPlayer.Weapons[2]);
    Assert.AreEqual(100, FPlayer.Ammo[1]);
    Assert.AreEqual(200, FPlayer.ScrollMax);
  end;
end;

procedure TTestGreedPlayerRules.DovrebbeRifiutareUnPersonaggioChePNonCe;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerRules.NewPlayer(FPlayer, 0, 6, 0, 0, 200);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerRules.NewPlayer(FPlayer, 0, -1, 0, 0, 200);
    end, EGreedException);
end;

procedure TTestGreedPlayerRules.DovrebbeSollevareSenzaDipendenze;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerRules.Create(nil, FGame as IGreedPlayerFeedback);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedPlayerRules.Create(FGame as IGreedPlayerContext, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedPlayerRules.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
const
  EFFECTS: array[0..3] of Integer = (0, 1, 4, 2);
var
  LSeed: Cardinal;
  LCase, LStep, LType: Integer;
  LPlayer: TGreedPlayerRecord;
  LGame: TFakePlayerGame;
  LGameIntf: IInterface;
  LSut: TGreedPlayerRules;
  LAmount: Integer;
begin
  LSeed := 5150;
  OLog := TStringList.Create;
  try
    for LCase := 1 to 300 do
    begin
      LGame := TFakePlayerGame.Create;
      LGameIntf := LGame;
      LSut := TGreedPlayerRules.Create(LGame as IGreedPlayerContext, LGame as IGreedPlayerFeedback);
      try
        LType := Next(LSeed) mod GREED_CHAR_TYPES;
        TGreedPlayerRules.NewPlayer(LPlayer, 1, LType, 2, 500, 200);
        OldNewPlayer(1, LType, 2, 500, 200);
        Assert.IsTrue(Same(OPlayer, LPlayer), 'new player ' + IntToStr(LCase));
        OLog.Clear;
        OGod := Next(LSeed) mod 8 = 0;
        OEffect := EFFECTS[Next(LSeed) mod 4];
        ONet := Next(LSeed) mod 2 = 0;
        OTime := 0;
        OHurtSoundTime := 0;
        LGame.God := OGod;
        LGame.Effect := OEffect;
        LGame.Net := ONet;
        LPlayer.X := Integer(Next(LSeed) mod 100000);
        LPlayer.Y := Integer(Next(LSeed) mod 100000);
        OPlayer.X := LPlayer.X;
        OPlayer.Y := LPlayer.Y;
        for LStep := 1 to 60 do
        begin
          LAmount := Integer(Next(LSeed) mod 400) - 20;
          OTime := OTime + Integer(Next(LSeed) mod 30);
          LGame.Time := OTime;
          case Next(LSeed) mod 4 of
            0:
              begin
                OldHeal(LAmount);
                LSut.Heal(LPlayer, LAmount);
              end;
            1:
              begin
                OldMedpaks(LAmount);
                LSut.MedPaks(LPlayer, LAmount);
              end;
            2:
              begin
                OldAddScore(LAmount * 1000000);
                TGreedPlayerRules.AddScore(LPlayer, LAmount * 1000000);
              end;
          else
            begin
              OldHurt(LAmount);
              LSut.Hurt(LPlayer, LAmount);
            end;
          end;
          Assert.IsTrue(Same(OPlayer, LPlayer), Format('case %d step %d', [LCase, LStep]));
          Assert.AreEqual(OHurtSoundTime, LGame.HurtSoundTime, 'hurt sound time');
        end;
        Assert.AreEqual(OLog.Text, LGame.Log.Text, 'calls ' + IntToStr(LCase));
      finally
        LSut.Free;
        LGameIntf := nil;
      end;
    end;
  finally
    OLog.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPlayerRules);

end.
