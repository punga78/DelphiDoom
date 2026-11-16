{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - what is known of the samples of a sound         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SoundParameters;

interface

uses
  DelphiDoom.Audio.Types;

type
  /// <summary>Where the samples of a sound come from (wavestatus_t of the old i_sound)</summary>
  TSfxWaveStatus = (
    /// <summary>Not a WAV: a DMX sound of the WAD, or not read yet</summary>
    NoWave,
    /// <summary>A WAV inside a lump of the WAD</summary>
    InternalWave,
    /// <summary>A file out of the WAD</summary>
    ExternalWave,
    /// <summary>The file out of the WAD caused a problem: it is not looked for again</summary>
    WaveFailed
  );

  /// <summary>
  ///   The parameters of a sound (soundparam_t of the old i_sound): format, where the samples
  ///   start and how long the buffer of the voice is. The number of channels and the bits are kept
  ///   in a byte, as before
  /// </summary>
  TSfxSoundParameters = record
    Length: Integer;
    Offset: Integer;
    Format: TSfxFormat;
    Status: TSfxWaveStatus;
    /// <summary>
    ///   What the parser found in a file out of the WAD: the samples are copied in a block of their
    ///   own, so they start at 0. AAccepted is the result of the parser
    /// </summary>
    procedure ApplyFile(const AChunks: TSfxWaveChunks; AAccepted: Boolean);
    /// <summary>What the parser found in the lump; AComplete is the result of the parser</summary>
    procedure ApplyLump(const AChunks: TSfxWaveChunks; AComplete: Boolean);
    /// <summary>The sample over the samples in AData</summary>
    function ToSample(AData: PByte): TSfxSample;
  end;

implementation

{ TSfxSoundParameters }

procedure ApplyFormat(var AParameters: TSfxSoundParameters; const AFormat: TSfxFormat);
begin
  AParameters.Format.Tag := AFormat.Tag;
  AParameters.Format.SamplesPerSecond := AFormat.SamplesPerSecond;
  AParameters.Format.AverageBytesPerSecond := AFormat.AverageBytesPerSecond;
  // the old record had a byte for both
  AParameters.Format.BitsPerSample := Byte(AFormat.BitsPerSample and $FF);
  AParameters.Format.Channels := Byte(AFormat.Channels and $FF);
end;

procedure TSfxSoundParameters.ApplyFile(const AChunks: TSfxWaveChunks; AAccepted: Boolean);
begin
  if AChunks.FormatFound then
    ApplyFormat(Self, AChunks.Format);
  if AChunks.DataFound then
  begin
    Length := AChunks.DataLength;
    Offset := 0;
  end;
  if AAccepted and AChunks.FormatDone and AChunks.DataDone then
    Status := TSfxWaveStatus.ExternalWave;
end;

procedure TSfxSoundParameters.ApplyLump(const AChunks: TSfxWaveChunks; AComplete: Boolean);
begin
  if AChunks.FormatFound then
    ApplyFormat(Self, AChunks.Format);
  if AChunks.DataFound then
  begin
    Length := AChunks.DataLength;
    Offset := AChunks.DataOffset;
  end;
  if AComplete then
    Status := TSfxWaveStatus.InternalWave;
end;

function TSfxSoundParameters.ToSample(AData: PByte): TSfxSample;
begin
  Result.Format := Format;
  Result.Data := AData;
  Result.Offset := Offset;
  Result.Length := Length;
  Result.IsExternal := Status = TSfxWaveStatus.ExternalWave;
end;

end.
