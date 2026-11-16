{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the song of each map                             }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): selectsong of utils.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SongSelector;

interface

type
  /// <summary>A song: the module file and the pattern where it starts (BASS does not use the pattern)</summary>
  TGreedSong = record
    FileName: string;
    Pattern: Integer;
  end;

  /// <summary>The table of selectsong: which file and pattern play on each map number</summary>
  TGreedSongSelector = class
  public
    /// <summary>The demo has 5 songs that repeat (the number is taken modulo 5); the net game has its own ending song</summary>
    class function Select(ASongMap: Integer; ADemo, ANetGame: Boolean): TGreedSong; static;
  end;

implementation

type
  TSongEntry = record
    FileName: string;
    Pattern: Integer;
  end;

const
  SONGS: array[0..31] of TSongEntry = (
    (FileName: 'SONG0.S3M'; Pattern: 0), (FileName: 'SONG0.S3M'; Pattern: 20),
    (FileName: 'SONG0.S3M'; Pattern: 37), (FileName: 'SONG0.S3M'; Pattern: 54),
    (FileName: 'SONG0.S3M'; Pattern: 73), (FileName: 'SONG2.S3M'; Pattern: 0),
    (FileName: 'SONG2.S3M'; Pattern: 26), (FileName: 'SONG2.S3M'; Pattern: 46),
    (FileName: 'SONG2.S3M'; Pattern: 64), (FileName: 'SONG2.S3M'; Pattern: 83),
    (FileName: 'SONG3.S3M'; Pattern: 0), (FileName: 'SONG3.S3M'; Pattern: 39),
    (FileName: 'SONG3.S3M'; Pattern: 58), (FileName: 'SONG3.S3M'; Pattern: 78),
    (FileName: 'SONG3.S3M'; Pattern: 94), (FileName: 'SONG1.S3M'; Pattern: 0),
    (FileName: 'SONG1.S3M'; Pattern: 24), (FileName: 'SONG1.S3M'; Pattern: 45),
    (FileName: 'SONG4.S3M'; Pattern: 0), (FileName: 'SONG4.S3M'; Pattern: 10),
    (FileName: 'SONG4.S3M'; Pattern: 21), (FileName: 'SONG8.MOD'; Pattern: 0),
    (FileName: 'ENDING.MOD'; Pattern: 0), (FileName: 'SONG5.MOD'; Pattern: 0),
    (FileName: 'SONG6.MOD'; Pattern: 0), (FileName: 'SONG7.MOD'; Pattern: 0),
    (FileName: 'SONG4.S3M'; Pattern: 33), (FileName: 'SONG9.MOD'; Pattern: 0),
    (FileName: 'SONG10.MOD'; Pattern: 0), (FileName: 'SONG11.MOD'; Pattern: 0),
    (FileName: 'SONG12.MOD'; Pattern: 0), (FileName: 'SONG13.MOD'; Pattern: 0));

{ TGreedSongSelector }

class function TGreedSongSelector.Select(ASongMap: Integer; ADemo, ANetGame: Boolean): TGreedSong;
begin
  if ADemo then
    ASongMap := ASongMap mod 5;
  if ASongMap = 99 then
  begin
    Result.FileName := 'PROBE.MOD';
    Result.Pattern := 0;
  end
  else if (ASongMap = 22) and ANetGame then
  begin
    Result.FileName := 'SONG14.MOD';
    Result.Pattern := 0;
  end
  else if (ASongMap >= 0) and (ASongMap <= High(SONGS)) then
  begin
    Result.FileName := SONGS[ASongMap].FileName;
    Result.Pattern := SONGS[ASongMap].Pattern;
  end
  else
  begin
    Result.FileName := 'SONG0.S3M';
    Result.Pattern := 0;
  end;
end;

end.
