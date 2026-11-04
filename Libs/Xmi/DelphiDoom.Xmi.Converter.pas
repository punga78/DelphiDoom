{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - converts a song to a standard MIDI file           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Converter;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Intf, DelphiDoom.Xmi.Midi.Types;

type
  /// <summary>
  ///   Recognizes a song and turns one of its tracks into the bytes of a
  ///   standard MIDI file. Keeps no state: it can be used from any thread
  /// </summary>
  TXmiConverter = class
  private
    class function ToBytes(ASource: Pointer; ASourceSize: Integer): TBytes; static;
  public
    class function DetectFormat(ASource: Pointer;
      ASourceSize: Integer): TXmiFormat; static;

    /// <summary>
    ///   Number of songs (tracks) of an XMI, CMF or SOP file
    /// </summary>
    class function CountTracks(ASource: Pointer; ASourceSize: Integer;
      out ATrackCount: Integer): TXmiConversionStatus; static;

    /// <summary>
    ///   Converts track ATrack of an XMI, CMF or SOP file
    /// </summary>
    class function ConvertToMidi(ASource: Pointer; ASourceSize,
      ATrack: Integer; out AMidi: TBytes): TXmiConversionStatus; static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Midi.Track,
  DelphiDoom.Xmi.FormatDetector, DelphiDoom.Xmi.Reader.Xmi,
  DelphiDoom.Xmi.Converter.XmiToMidi, DelphiDoom.Xmi.Writer.Midi;

{ TXmiConverter }

class function TXmiConverter.ToBytes(ASource: Pointer;
  ASourceSize: Integer): TBytes;
begin
  Result := nil;
  if not Assigned(ASource) or (ASourceSize <= 0) then
    Exit;

  SetLength(Result, ASourceSize);
  Move(ASource^, Result[0], ASourceSize);
end;

class function TXmiConverter.DetectFormat(ASource: Pointer;
  ASourceSize: Integer): TXmiFormat;
begin
  Result := TXmiFormatDetector.Detect(ToBytes(ASource, ASourceSize));
end;

class function TXmiConverter.CountTracks(ASource: Pointer; ASourceSize: Integer;
  out ATrackCount: Integer): TXmiConversionStatus;
var
  LData: TBytes;
  LSong: TXmiSong;
begin
  ATrackCount := 0;
  LData := ToBytes(ASource, ASourceSize);
  try
    case TXmiFormatDetector.Detect(LData) of
      TXmiFormat.Xmi:
        begin
          LSong := TXmiXmiReader.Read(LData);
          try
            ATrackCount := LSong.Tracks.Count;
          finally
            LSong.Free;
          end;
          Result := TXmiConversionStatus.Ok;
        end;
    else
      Result := TXmiConversionStatus.UnknownFormat;
    end;
  except
    on EOutOfMemory do
      Result := TXmiConversionStatus.OutOfMemory;
    // The readers raise on truncated or inconsistent data
    on Exception do
      Result := TXmiConversionStatus.BadData;
  end;
end;

class function TXmiConverter.ConvertToMidi(ASource: Pointer; ASourceSize,
  ATrack: Integer; out AMidi: TBytes): TXmiConversionStatus;
var
  LData: TBytes;
  LSong: TXmiSong;
  LSelected: TXmiSong;
  LTrack: TXmiTrack;
begin
  AMidi := nil;
  LData := ToBytes(ASource, ASourceSize);
  try
    case TXmiFormatDetector.Detect(LData) of
      TXmiFormat.Xmi:
        begin
          LSong := TXmiXmiReader.Read(LData);
          try
            if (ATrack < 0) or (ATrack >= LSong.Tracks.Count) then
              Exit(TXmiConversionStatus.TrackOutOfRange);

            // The file that comes out has the song asked for and nothing else
            LSelected := TXmiSong.Create;
            try
              LSelected.InitialTempo := LSong.InitialTempo;
              LSelected.Division := LSong.Division;
              LSelected.Smpte := LSong.Smpte;
              LSelected.MidiType := LSong.MidiType;
              LTrack := LSong.ExtractTrack(ATrack);
              LSelected.AdoptTrack(LTrack);

              TXmiXmiToMidiConverter.Convert(LSelected);
              AMidi := TXmiMidiWriter.Write(LSelected);
            finally
              LSelected.Free;
            end;
          finally
            LSong.Free;
          end;
          Result := TXmiConversionStatus.Ok;
        end;
    else
      Result := TXmiConversionStatus.UnknownFormat;
    end;
  except
    on EOutOfMemory do
      Result := TXmiConversionStatus.OutOfMemory;
    on Exception do
      Result := TXmiConversionStatus.BadData;
  end;
end;

end.
