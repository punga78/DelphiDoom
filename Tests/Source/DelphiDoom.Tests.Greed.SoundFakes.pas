{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - fakes of the sound                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SoundFakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Sound.Intf;

type
  TFakeEffectChannel = class(TInterfacedObject, IGreedEffectChannel)
  public
    Pan: Single;
    Volume: Single;
    Active: Boolean;
    Stopped: Boolean;
    PanCalls: Integer;
    constructor Create;
    procedure SetPan(APan: Single);
    procedure SetVolume(AVolume: Single);
    function IsActive: Boolean;
    procedure Stop;
  end;

  TFakeMusicChannel = class(TInterfacedObject, IGreedMusicChannel)
  public
    Volumes: TList<Single>;
    Stopped: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure SetVolume(AVolume: Single);
    procedure Stop;
  end;

  TFakeSoundDevice = class(TInterfacedObject, IGreedSoundDevice)
  public
    Effects: TList<TFakeEffectChannel>;
    EffectWaves: TList<TBytes>;
    Music: TFakeMusicChannel;
    /// <summary>Keeps the channels alive: the lists hold objects, the game holds interfaces</summary>
    Keep: TList<IInterface>;
    MusicModules: TList<TBytes>;
    /// <summary>The device cannot play the effects</summary>
    RefuseEffects: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Initialize: Boolean;
    procedure Shutdown;
    function StartEffect(const AWave: TBytes): IGreedEffectChannel;
    function StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
  end;

  TFakeListener = class(TInterfacedObject, IGreedListener)
  public
    X: TGreedFixed;
    Y: TGreedFixed;
    Angle: Integer;
    function GetX: TGreedFixed;
    function GetY: TGreedFixed;
    function GetAngle: Integer;
  end;

  TFakeTics = class(TInterfacedObject, IGreedTics)
  public
    Waited: Integer;
    procedure Wait(ATics: Integer);
  end;

  /// <summary>Files in memory by name</summary>
  TFakeFiles = class(TInterfacedObject, IGreedExternalFiles)
  public
    Files: TDictionary<string, TBytes>;
    constructor Create;
    destructor Destroy; override;
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

{ TFakeEffectChannel }

constructor TFakeEffectChannel.Create;
begin
  inherited Create;
  Active := True;
end;

procedure TFakeEffectChannel.SetPan(APan: Single);
begin
  Pan := APan;
  Inc(PanCalls);
end;

procedure TFakeEffectChannel.SetVolume(AVolume: Single);
begin
  Volume := AVolume;
end;

function TFakeEffectChannel.IsActive: Boolean;
begin
  Result := Active;
end;

procedure TFakeEffectChannel.Stop;
begin
  Stopped := True;
  Active := False;
end;

{ TFakeMusicChannel }

constructor TFakeMusicChannel.Create;
begin
  inherited Create;
  Volumes := TList<Single>.Create;
end;

destructor TFakeMusicChannel.Destroy;
begin
  Volumes.Free;
  inherited;
end;

procedure TFakeMusicChannel.SetVolume(AVolume: Single);
begin
  Volumes.Add(AVolume);
end;

procedure TFakeMusicChannel.Stop;
begin
  Stopped := True;
end;

{ TFakeSoundDevice }

constructor TFakeSoundDevice.Create;
begin
  inherited Create;
  Effects := TList<TFakeEffectChannel>.Create;
  EffectWaves := TList<TBytes>.Create;
  MusicModules := TList<TBytes>.Create;
  Keep := TList<IInterface>.Create;
end;

destructor TFakeSoundDevice.Destroy;
begin
  Effects.Free;
  EffectWaves.Free;
  MusicModules.Free;
  Music := nil;
  Keep.Free;
  inherited;
end;

function TFakeSoundDevice.Initialize: Boolean;
begin
  Result := True;
end;

procedure TFakeSoundDevice.Shutdown;
begin
end;

function TFakeSoundDevice.StartEffect(const AWave: TBytes): IGreedEffectChannel;
var
  LChannel: TFakeEffectChannel;
begin
  if RefuseEffects then
    Exit(nil);
  LChannel := TFakeEffectChannel.Create;
  Effects.Add(LChannel);
  Keep.Add(LChannel);
  EffectWaves.Add(AWave);
  Result := LChannel;
end;

function TFakeSoundDevice.StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
begin
  Music := TFakeMusicChannel.Create;
  Keep.Add(Music);
  Music.Volumes.Add(AVolume);
  MusicModules.Add(AModule);
  Result := Music;
end;

{ TFakeListener }

function TFakeListener.GetX: TGreedFixed;
begin
  Result := X;
end;

function TFakeListener.GetY: TGreedFixed;
begin
  Result := Y;
end;

function TFakeListener.GetAngle: Integer;
begin
  Result := Angle;
end;

{ TFakeTics }

procedure TFakeTics.Wait(ATics: Integer);
begin
  Inc(Waited, ATics);
end;

{ TFakeFiles }

constructor TFakeFiles.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
end;

destructor TFakeFiles.Destroy;
begin
  Files.Free;
  inherited;
end;

function TFakeFiles.Exists(const AName: string): Boolean;
begin
  Result := Files.ContainsKey(AName);
end;

function TFakeFiles.ReadAll(const AName: string): TBytes;
begin
  Result := Files[AName];
end;

end.
