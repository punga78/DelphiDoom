{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - a song: tracks and the values of its header       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Midi.Song;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xmi.Midi.Track;

type
  /// <summary>
  ///   The tracks of a song and what a standard MIDI file needs besides them
  /// </summary>
  TXmiSong = class
  private
    FTracks: TObjectList<TXmiTrack>;
    FInitialTempo: Cardinal;
    FDivision: Word;
    FSmpte: ShortInt;
    FMidiType: Word;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Adds a new empty track and returns it (the song owns it)
    /// </summary>
    function AddTrack: TXmiTrack;

    /// <summary>
    ///   Takes the track AIndex out of the song, which no longer owns it
    /// </summary>
    function ExtractTrack(AIndex: Integer): TXmiTrack;

    /// <summary>
    ///   Adds a track that was taken out of another song
    /// </summary>
    procedure AdoptTrack(ATrack: TXmiTrack);

    property Tracks: TObjectList<TXmiTrack> read FTracks;

    /// <summary>Microseconds per quarter note at the start of the song</summary>
    property InitialTempo: Cardinal read FInitialTempo write FInitialTempo;

    /// <summary>Ticks per quarter note (or per frame if Smpte is negative)</summary>
    property Division: Word read FDivision write FDivision;
    property Smpte: ShortInt read FSmpte write FSmpte;

    /// <summary>0, 1 or 2: the type of the standard MIDI file</summary>
    property MidiType: Word read FMidiType write FMidiType;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types;

{ TXmiSong }

constructor TXmiSong.Create;
begin
  inherited Create;
  FTracks := TObjectList<TXmiTrack>.Create(True);
  FInitialTempo := XMI_MIDI_STANDARD_TEMPO;
end;

destructor TXmiSong.Destroy;
begin
  FreeAndNil(FTracks);
  inherited;
end;

function TXmiSong.AddTrack: TXmiTrack;
begin
  Result := TXmiTrack.Create;
  FTracks.Add(Result);
end;

function TXmiSong.ExtractTrack(AIndex: Integer): TXmiTrack;
begin
  Result := FTracks.Extract(FTracks[AIndex]);
end;

procedure TXmiSong.AdoptTrack(ATrack: TXmiTrack);
begin
  FTracks.Add(ATrack);
end;

end.
