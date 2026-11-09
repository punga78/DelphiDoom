{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the sound effects                                }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): modplay.pas                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SoundEffects;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Sound.Intf;

const
  /// <summary>MAXSFXCHANNELS</summary>
  GREED_SFX_CHANNELS = 64;
  /// <summary>The lump that comes before the first effect (the effects are the lumps after "SOUNDEFFECTS")</summary>
  GREED_LUMP_SOUND_EFFECTS = 'SOUNDEFFECTS';

type
  /// <summary>
  ///   SoundEffect, UpdateSound, CheckChannels and UpdateChannelParams of modplay.pas. A channel is free when its
  ///   slot is empty; the effects are the lumps after SOUNDEFFECTS, WAV files that the device plays
  /// </summary>
  TGreedSoundEffects = class(TInterfacedObject, IGreedSoundEffects)
  strict private
    type
      TSlot = record
        Channel: IGreedEffectChannel;
        X: TGreedFixed;
        Y: TGreedFixed;
      end;
    var
      FDevice: IGreedSoundDevice;
      FArchive: IGreedArchive;
      FListener: IGreedListener;
      FVolumes: IGreedSoundVolumes;
      FFirstEffectLump: Integer;
      FSlots: array[0..GREED_SFX_CHANNELS - 1] of TSlot;
    procedure CheckChannels;
    function FreeChannel: Integer;
    procedure UpdateChannel(AIndex: Integer);
  public
    /// <exception cref="EGreedNotFoundException">There is no SOUNDEFFECTS lump (InitSound: MS_Error)</exception>
    constructor Create(const ADevice: IGreedSoundDevice; const AArchive: IGreedArchive;
      const AListener: IGreedListener; const AVolumes: IGreedSoundVolumes);
    procedure Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
    procedure Update;
    procedure StopAll;
  end;

implementation

uses
  DelphiDoom.Greed.SoundGeometry;

{ TGreedSoundEffects }

constructor TGreedSoundEffects.Create(const ADevice: IGreedSoundDevice; const AArchive: IGreedArchive;
  const AListener: IGreedListener; const AVolumes: IGreedSoundVolumes);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AListener) then
    raise EArgumentNilException.Create('AListener');
  if not Assigned(AVolumes) then
    raise EArgumentNilException.Create('AVolumes');
  FDevice := ADevice;
  FArchive := AArchive;
  FListener := AListener;
  FVolumes := AVolumes;
  FFirstEffectLump := FArchive.RequireIndexOf(GREED_LUMP_SOUND_EFFECTS) + 1;
end;

procedure TGreedSoundEffects.CheckChannels;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_SFX_CHANNELS - 1 do
    if Assigned(FSlots[LIndex].Channel) and not FSlots[LIndex].Channel.IsActive then
      FSlots[LIndex].Channel := nil;
end;

function TGreedSoundEffects.FreeChannel: Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_SFX_CHANNELS - 1 do
    if not Assigned(FSlots[LIndex].Channel) then
      Exit(LIndex);
  Result := -1;
end;

procedure TGreedSoundEffects.UpdateChannel(AIndex: Integer);
var
  LDeltaX, LDeltaY: TGreedFixed;
begin
  LDeltaX := FSlots[AIndex].X - FListener.GetX;
  LDeltaY := FSlots[AIndex].Y - FListener.GetY;
  FSlots[AIndex].Channel.SetPan(TGreedSoundGeometry.Pan(LDeltaX, LDeltaY, FListener.GetAngle));
  FSlots[AIndex].Channel.SetVolume(TGreedSoundGeometry.Volume(LDeltaX, LDeltaY, FVolumes.SfxVolume));
end;

procedure TGreedSoundEffects.Start(ASoundNumber, AVariation: Integer; AX, AY: TGreedFixed);
var
  LChannel: Integer;
  LWave: TBytes;
begin
  if not TGreedSoundGeometry.IsInRange(AX - FListener.GetX, AY - FListener.GetY) then
    Exit;
  LChannel := FreeChannel;
  // the original looks again after CheckChannels also when the free one is the first (ch <= 0)
  if LChannel <= 0 then
  begin
    CheckChannels;
    LChannel := FreeChannel;
  end;
  if LChannel = -1 then
    Exit;
  LWave := FArchive.ReadLump(FFirstEffectLump + ASoundNumber);
  if Length(LWave) = 0 then
    Exit;
  FSlots[LChannel].X := AX;
  FSlots[LChannel].Y := AY;
  FSlots[LChannel].Channel := FDevice.StartEffect(LWave);
  if Assigned(FSlots[LChannel].Channel) then
    UpdateChannel(LChannel);
end;

procedure TGreedSoundEffects.Update;
var
  LIndex: Integer;
begin
  CheckChannels;
  for LIndex := 0 to GREED_SFX_CHANNELS - 1 do
    if Assigned(FSlots[LIndex].Channel) then
      UpdateChannel(LIndex);
end;

procedure TGreedSoundEffects.StopAll;
var
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_SFX_CHANNELS - 1 do
    if Assigned(FSlots[LIndex].Channel) then
    begin
      FSlots[LIndex].Channel.Stop;
      FSlots[LIndex].Channel := nil;
    end;
end;

end.
