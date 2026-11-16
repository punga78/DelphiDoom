{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - ISndfile made of sound formats                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Engine;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   Replacement of the C libsndfile: opens a sound by asking each format it
  ///   was given whether the data is its own. Stateless after construction, so
  ///   one instance can serve several threads
  /// </summary>
  TSoundEngine = class(TInterfacedObject, ISndfile)
  private
    FFormats: TArray<ISoundFormat>;
  public
    /// <summary>
    ///   AFormats are tried in order: put the ones that are cheaper to
    ///   recognise first
    /// </summary>
    constructor Create(const AFormats: TArray<ISoundFormat>);

    function GetVersion: PAnsiChar; stdcall;
    function OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
      out ASoundFile: ISoundFile): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Sound.Samples, DelphiDoom.Sound.SoundFile;

const
  MAX_SOURCE_SIZE = Cardinal(High(Integer));

function HasId3Tag(const AData: TBytes): Boolean;
begin
  // The marker libsndfile looks for is "ID3" and the version 3 (4 bytes), with 12 bytes to read
  Result := (Length(AData) >= 12) and (AData[0] = Ord('I')) and (AData[1] = Ord('D')) and
    (AData[2] = Ord('3')) and (AData[3] = 3);
end;

function IsEmbeddable(AFormat: Integer): Boolean;
begin
  // libsndfile lets WAV, AIFF and AU follow a tag too, but this build fails to open them
  Result := (AFormat and SNDFILE_FORMAT_TYPEMASK) = SNDFILE_FORMAT_FLAC;
end;

{ TSoundEngine }

constructor TSoundEngine.Create(const AFormats: TArray<ISoundFormat>);
begin
  inherited Create;
  FFormats := AFormats;
end;

function TSoundEngine.GetVersion: PAnsiChar;
begin
  Result := PAnsiChar('DelphiDoom.Sound');
end;

function TSoundEngine.OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
  out ASoundFile: ISoundFile): Integer;
var
  LData: TBytes;
  LFormat: ISoundFormat;
  LSamples: TSoundSamples;
  LTagSize: Integer;
  LEmbedded: Boolean;
begin
  ASoundFile := nil;
  if (ASource = nil) or (ASourceSize = 0) or (ASourceSize > MAX_SOURCE_SIZE) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  try
    SetLength(LData, ASourceSize);
    Move(ASource^, LData[0], ASourceSize);

    // A tag of ID3v2 in front of the sound: libsndfile skips one (a second tag
    // after it is not understood)
    LEmbedded := False;
    if HasId3Tag(LData) then
    begin
      LTagSize := 10 + (((LData[6] and $7F) shl 21) or ((LData[7] and $7F) shl 14) or
        ((LData[8] and $7F) shl 7) or (LData[9] and $7F));
      // a tag that takes all the file leaves nothing to recognise
      if LTagSize >= Length(LData) then
        LData := nil
      else
      begin
        LData := Copy(LData, LTagSize, Length(LData) - LTagSize);
        LEmbedded := True;
        if HasId3Tag(LData) then
          LData := nil;
      end;
    end;
    Result := SNDFILE_ERR_UNRECOGNISED_FORMAT;
    if Length(LData) > 0 then
      for LFormat in FFormats do
      begin
        LSamples := nil;
        Result := LFormat.Decode(LData, LSamples);
        if Result <> SNDFILE_ERR_UNRECOGNISED_FORMAT then
          Break;
      end;

    // Only some containers can follow the tag
    if LEmbedded and (Result = SNDFILE_OK) and not IsEmbeddable(LSamples.Info.Format) then
    begin
      LSamples.Free;
      Result := SNDFILE_ERR_MALFORMED_FILE;
    end;

    // What sf_open checks once the format has been read
    if (Result = SNDFILE_OK) and ((LSamples.Info.SampleRate < 1) or
       (LSamples.Info.Frames < 0) or (LSamples.Info.Channels < 1)) then
    begin
      LSamples.Free;
      Result := SNDFILE_ERR_MALFORMED_FILE;
    end;

    if Result = SNDFILE_OK then
      ASoundFile := TSoundFile.Create(LSamples);
  except
    on EOutOfMemory do
      Result := SNDFILE_ERR_OUT_OF_MEMORY;
    else
      Result := SNDFILE_ERR_UNEXPECTED;
  end;
end;

end.
