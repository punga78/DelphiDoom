{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound effect (sfx_t)                  }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Sfx;

interface

const
  /// <summary>SND_CHUNK_SIZE: samples of one sndBuffer</summary>
  Q3_SND_CHUNK_SIZE = 1024;

type
  /// <summary>
  ///   A sound effect of Quake III (sfx_t) held in memory as 16 bit mono samples at the
  ///   rate of the device
  /// </summary>
  /// <remarks>
  ///   The C keeps the samples in a chain of chunks of 1024 samples; here they are one
  ///   array padded with zeros to a whole number of chunks, which is what the chain
  ///   holds (the C leaves the padding of the last chunk uninitialised). Only the
  ///   uncompressed form is kept (soundCompressionMethod 0)
  /// </remarks>
  TQ3Sfx = class
  strict private
    FName: string;
    FSamples: TArray<SmallInt>;
    FSoundLength: Integer;
    FDefaultSound: Boolean;
    FInMemory: Boolean;
    FLastTimeUsed: Integer;
  public
    constructor Create(const AName: string);
    /// <summary>Stores ALength samples (padding the array to whole chunks)</summary>
    procedure SetSamples(const ASamples: TArray<SmallInt>; ALength: Integer);
    /// <summary>Number of chunks of the chain</summary>
    function ChunkCount: Integer;
    property Name: string read FName;
    /// <summary>Samples padded to a multiple of Q3_SND_CHUNK_SIZE</summary>
    property Samples: TArray<SmallInt> read FSamples;
    /// <summary>soundLength: the real number of samples</summary>
    property SoundLength: Integer read FSoundLength;
    /// <summary>The sound could not be loaded</summary>
    property DefaultSound: Boolean read FDefaultSound write FDefaultSound;
    /// <summary>The loading was tried (inMemory)</summary>
    property InMemory: Boolean read FInMemory write FInMemory;
    property LastTimeUsed: Integer read FLastTimeUsed write FLastTimeUsed;
  end;

implementation

{ TQ3Sfx }

constructor TQ3Sfx.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

procedure TQ3Sfx.SetSamples(const ASamples: TArray<SmallInt>; ALength: Integer);
var
  LPadded: Integer;
begin
  if ALength < 0 then
    ALength := 0;
  if ALength > Length(ASamples) then
    ALength := Length(ASamples);
  FSoundLength := ALength;
  LPadded := (ALength + Q3_SND_CHUNK_SIZE - 1) div Q3_SND_CHUNK_SIZE * Q3_SND_CHUNK_SIZE;
  SetLength(FSamples, LPadded);
  if ALength > 0 then
    Move(ASamples[0], FSamples[0], ALength * SizeOf(SmallInt));
end;

function TQ3Sfx.ChunkCount: Integer;
begin
  Result := Length(FSamples) div Q3_SND_CHUNK_SIZE;
end;

end.
