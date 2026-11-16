{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - which events of a song go to the stream next      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.EventFeeder;

interface

type
  /// <summary>
  ///   The choice that the old I_ProcessMusicMus made every time a header of the stream came
  ///   back: a song already made of events is given to the stream a piece after the other, at
  ///   most AMaxCount events each, and after the last piece it starts again
  /// </summary>
  TMidiEventFeeder = class
  public
    /// <summary>
    ///   The piece that goes next: AStartIndex is the first event and ACount their number. ANextIndex is
    ///   where the song is (zero for the start): it moves to the following piece, or to zero
    ///   after the last one
    /// </summary>
    /// <param name="ATotalCount">The events of the song</param>
    /// <param name="AMaxCount">The most that a piece may have (it is a buffer of the stream)</param>
    /// <param name="ANextIndex">The position in the song, updated</param>
    /// <param name="AStartIndex">The first event of the piece</param>
    /// <param name="ACount">The events of the piece</param>
    class procedure NextPiece(ATotalCount, AMaxCount: Integer; var ANextIndex: Integer;
      out AStartIndex, ACount: Integer); static;
  end;

implementation

{ TMidiEventFeeder }

class procedure TMidiEventFeeder.NextPiece(ATotalCount, AMaxCount: Integer;
  var ANextIndex: Integer; out AStartIndex, ACount: Integer);
begin
  AStartIndex := ANextIndex;
  ACount := ATotalCount - ANextIndex;
  if ACount > AMaxCount then
  begin
    ACount := AMaxCount;
    Inc(ANextIndex, AMaxCount);
  end
  else
    ANextIndex := 0;
end;

end.
