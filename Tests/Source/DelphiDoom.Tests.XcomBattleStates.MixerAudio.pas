{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sounds of the battle on the channels of the mixer   }
{  (TXcomBattleMixerAudio) with a fake mixer                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.MixerAudio;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomAudio.Intf,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>IXcomChannelMixer that writes down the calls</summary>
  TFakeChannelMixer = class(TInterfacedObject, IXcomChannelMixer)
  strict private
    FCalls: TStringList;
    FPlaying: Boolean;
    FNoChannel: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function PlayChannel(const AWave: TBytes; AChannel, ALoops: Integer): Integer;
    procedure SetPosition(AChannel, AAngle, ADistance: Integer);
    procedure HaltChannel(AChannel: Integer);
    function IsChannelPlaying(AChannel: Integer): Boolean;
    procedure SetChannelVolume(AChannel, AVolume: Integer);
    function FreeInterfaceChannel: Integer;
    procedure SetAmbientVolume(AValue: Double);
    property Calls: TStringList read FCalls;
    /// <summary>What IsChannelPlaying answers</summary>
    property Playing: Boolean read FPlaying write FPlaying;
    /// <summary>No channel is free: PlayChannel gives -1</summary>
    property NoChannel: Boolean read FNoChannel write FNoChannel;
  end;

  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomBattleMixerAudio = class
  strict private
    FWorld: TTestWorld;
    FMixer: TFakeChannelMixer;
    FMixerRef: IXcomChannelMixer;
    FAudio: IXcomBattleAudio;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareSulPrimoCanaleLiberoSenzaPanSeLoStereoESpento;
    [Test]
    procedure DovrebbeSpostareIlSuonoConLoStereo;
    [Test]
    procedure NonDovrebbeSpostareUnSuonoCheNonHaAvutoUnCanale;
    [Test]
    procedure NonDovrebbeSuonareSeMuto;
    [Test]
    procedure NonDovrebbeSuonareUnSuonoNegativo;
    [Test]
    procedure DovrebbeRipetereLAmbienteSulCanaleTre;
    [Test]
    procedure NonDovrebbeRiavviareLAmbienteCheSuonaGia;
    [Test]
    procedure DovrebbeFermareLAmbiente;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomBattleStates.MixerAudio;

{ TFakeChannelMixer }

constructor TFakeChannelMixer.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
end;

destructor TFakeChannelMixer.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

function TFakeChannelMixer.PlayChannel(const AWave: TBytes; AChannel, ALoops: Integer): Integer;
begin
  FCalls.Add(Format('play %d bytes on %d loops %d', [Length(AWave), AChannel, ALoops]));
  if FNoChannel then
    Result := -1
  else if AChannel < 0 then
    Result := 5
  else
    Result := AChannel;
end;

procedure TFakeChannelMixer.SetPosition(AChannel, AAngle, ADistance: Integer);
begin
  FCalls.Add(Format('position %d %d %d', [AChannel, AAngle, ADistance]));
end;

procedure TFakeChannelMixer.HaltChannel(AChannel: Integer);
begin
  FCalls.Add(Format('halt %d', [AChannel]));
end;

function TFakeChannelMixer.IsChannelPlaying(AChannel: Integer): Boolean;
begin
  Result := FPlaying;
end;

procedure TFakeChannelMixer.SetChannelVolume(AChannel, AVolume: Integer);
begin
  FCalls.Add('volume');
end;

function TFakeChannelMixer.FreeInterfaceChannel: Integer;
begin
  Result := 1;
end;

procedure TFakeChannelMixer.SetAmbientVolume(AValue: Double);
begin
  FCalls.Add('ambient volume');
end;

{ TTestXcomBattleMixerAudio }

procedure TTestXcomBattleMixerAudio.Setup;
begin
  FWorld := TTestWorld.Create;
  (FWorld.Game.Resources as TFakeResources).Wave := TBytes.Create(1, 2, 3, 4);
  FMixer := TFakeChannelMixer.Create;
  FMixerRef := FMixer;
  FAudio := TXcomBattleMixerAudio.Create(FWorld.Game, FMixerRef);
end;

procedure TTestXcomBattleMixerAudio.TearDown;
begin
  FAudio := nil;
  FMixerRef := nil;
  FWorld.Free;
end;

procedure TTestXcomBattleMixerAudio.DovrebbeSuonareSulPrimoCanaleLiberoSenzaPanSeLoStereoESpento;
begin
  FWorld.Game.Options.SetValue('StereoSound', 0);
  FAudio.PlaySound(0, 7, 400);
  Assert.AreEqual(1, FMixer.Calls.Count);
  Assert.AreEqual('play 4 bytes on -1 loops 0', FMixer.Calls[0]);
end;

procedure TTestXcomBattleMixerAudio.DovrebbeSpostareIlSuonoConLoStereo;
begin
  FWorld.Game.Options.SetValue('StereoSound', 1);
  FAudio.PlaySound(1, 7, 400);
  Assert.AreEqual(2, FMixer.Calls.Count);
  Assert.AreEqual('position 5 400 0', FMixer.Calls[1]);
end;

procedure TTestXcomBattleMixerAudio.NonDovrebbeSpostareUnSuonoCheNonHaAvutoUnCanale;
begin
  FWorld.Game.Options.SetValue('StereoSound', 1);
  FMixer.NoChannel := True;
  FAudio.PlaySound(0, 7, 400);
  Assert.AreEqual(1, FMixer.Calls.Count);
end;

procedure TTestXcomBattleMixerAudio.NonDovrebbeSuonareSeMuto;
begin
  FWorld.Game.Options.SetValue('mute', 1);
  FAudio.PlaySound(0, 7, 400);
  FAudio.LoopAmbience(0, 3);
  Assert.AreEqual(0, FMixer.Calls.Count);
end;

procedure TTestXcomBattleMixerAudio.NonDovrebbeSuonareUnSuonoNegativo;
begin
  FAudio.PlaySound(0, -1, 400);
  Assert.AreEqual(0, FMixer.Calls.Count);
end;

procedure TTestXcomBattleMixerAudio.DovrebbeRipetereLAmbienteSulCanaleTre;
begin
  FAudio.LoopAmbience(2, 3);
  Assert.AreEqual('play 4 bytes on 3 loops -1', FMixer.Calls[0]);
end;

procedure TTestXcomBattleMixerAudio.NonDovrebbeRiavviareLAmbienteCheSuonaGia;
begin
  FMixer.Playing := True;
  FAudio.LoopAmbience(2, 3);
  Assert.AreEqual(0, FMixer.Calls.Count);
end;

procedure TTestXcomBattleMixerAudio.DovrebbeFermareLAmbiente;
begin
  FAudio.StopAmbience;
  Assert.AreEqual('halt 3', FMixer.Calls[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBattleMixerAudio);

end.
