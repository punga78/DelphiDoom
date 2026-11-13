{******************************************************************************}
{                                                                              }
{  DelphiDoom: a Quake III sound system on fakes, for the tests                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Rig;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Intf,
  DelphiDoom.Audio.Q3.SoundSystem, DelphiDoom.Tests.Audio.Q3.Fakes;

type
  /// <summary>
  ///   What the factory builds with a fake clock, device and file source, already
  ///   initialised and out of the muted state
  /// </summary>
  TQ3TestRig = class
  strict private
    FClockObject: TQ3FakeClock;
    FClock: IQ3SoundClock;
    FDeviceObject: TQ3FakeDevice;
    FDevice: IQ3SoundDevice;
    FFilesObject: TQ3FakeFileSource;
    FFiles: IQ3SoundFileSource;
    FSystem: TQ3SoundSystem;
  public
    /// <summary>AWithReader gives the system the real WAV reader of Libs\Sound</summary>
    constructor Create(AChannels: Integer = 2; ASamples: Integer = 8192; ABits: Integer = 16;
      ASpeed: Integer = 22050; AChunk: Integer = 1024; AWithReader: Boolean = False);
    destructor Destroy; override;
    /// <summary>Adds a sound of 16 bit samples at the rate of the device; the handle</summary>
    function AddSound(const AName: string; const ASamples: array of SmallInt): Integer;
    /// <summary>A sound of ACount samples all equal to AValue</summary>
    function AddConstant(const AName: string; AValue: SmallInt; ACount: Integer): Integer;
    /// <summary>The 16 bit samples the mixer wrote in the device buffer</summary>
    function DeviceSample(AIndex: Integer): SmallInt;
    property Clock: TQ3FakeClock read FClockObject;
    property Device: TQ3FakeDevice read FDeviceObject;
    property Files: TQ3FakeFileSource read FFilesObject;
    property Sound: TQ3SoundSystem read FSystem;
  end;

function Vec3(AX, AY, AZ: Single): TQ3Vec3;
/// <summary>The listener axes of a view looking along +x with +y to the left</summary>
function IdentityAxis: TQ3Axis;

implementation

uses
  DelphiDoom.Audio.Q3.Factory, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Factory;

function Vec3(AX, AY, AZ: Single): TQ3Vec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

function IdentityAxis: TQ3Axis;
begin
  Result[0] := Vec3(1, 0, 0);
  Result[1] := Vec3(0, 1, 0);
  Result[2] := Vec3(0, 0, 1);
end;

{ TQ3TestRig }

constructor TQ3TestRig.Create(AChannels, ASamples, ABits, ASpeed, AChunk: Integer;
  AWithReader: Boolean);
var
  LReader: ISndfile;
begin
  inherited Create;
  FClockObject := TQ3FakeClock.Create;
  FClock := FClockObject;
  FDeviceObject := TQ3FakeDevice.Create;
  FDevice := FDeviceObject;
  FDeviceObject.Configure(AChannels, ASamples, ABits, ASpeed, AChunk);
  FFilesObject := TQ3FakeFileSource.Create;
  FFiles := FFilesObject;
  LReader := nil;
  if AWithReader then
    LReader := TSoundFactory.CreateEngine;
  FSystem := TQ3SoundSystemFactory.CreateSoundSystem(FDevice, FClock, LReader, FFiles);
  FSystem.Init;
  FSystem.BeginRegistration;
end;

destructor TQ3TestRig.Destroy;
begin
  FSystem.Free;
  inherited Destroy;
end;

function TQ3TestRig.AddSound(const AName: string; const ASamples: array of SmallInt): Integer;
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LSamples, Length(ASamples));
  for LIndex := 0 to High(ASamples) do
    LSamples[LIndex] := ASamples[LIndex];
  Result := FSystem.Registry.AddSound(AName, LSamples, Length(LSamples));
end;

function TQ3TestRig.AddConstant(const AName: string; AValue: SmallInt;
  ACount: Integer): Integer;
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  SetLength(LSamples, ACount);
  for LIndex := 0 to ACount - 1 do
    LSamples[LIndex] := AValue;
  Result := FSystem.Registry.AddSound(AName, LSamples, ACount);
end;

function TQ3TestRig.DeviceSample(AIndex: Integer): SmallInt;
begin
  Result := PSmallInt(@FDeviceObject.Buffer[AIndex * 2])^;
end;

end.
