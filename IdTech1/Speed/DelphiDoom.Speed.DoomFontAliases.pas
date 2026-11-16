{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - the font of the game under the names of Doom    }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.DoomFontAliases;

interface

uses
  DelphiDoom.GameData.Intf;

const
  /// <summary>The prefix of the small yellow font that the translator writes (SFNTA033..SFNTA127)</summary>
  SPEED_SMALL_FONT_PREFIX = 'SFNTA';
  /// <summary>The prefix of the heads-up font that the engine of Doom reads (STCFN033..STCFN095)</summary>
  SPEED_DOOM_FONT_PREFIX = 'STCFN';
  /// <summary>The first and the last character of the heads-up font of Doom ('!' and '_')</summary>
  SPEED_DOOM_FONT_FIRST = 33;
  SPEED_DOOM_FONT_LAST = 95;

type
  /// <summary>
  ///   The engine of Doom writes its messages with the lumps STCFNnnn; the old fork changed
  ///   hu_stuff.pas to read SFNTAnnn instead. Here the difference is data: the characters of the
  ///   small font of Speed Haste are appended to the translated WAD under the names of Doom, so the
  ///   engine needs no rule of its own
  /// </summary>
  TSpeedDoomFontAliases = class
  public
    /// <summary>
    ///   Appends a copy of each character that the WAD has as SFNTAnnn and does not have as
    ///   STCFNnnn. The number of lumps appended; EArgumentNilException when AWad is nil
    /// </summary>
    class function Append(const AWad: IGameWadComposer): Integer; static;
  end;

implementation

uses
  System.SysUtils;

{ TSpeedDoomFontAliases }

class function TSpeedDoomFontAliases.Append(const AWad: IGameWadComposer): Integer;
var
  LCharacter: Integer;
  LSource: Integer;
  LName: string;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  Result := 0;
  for LCharacter := SPEED_DOOM_FONT_FIRST to SPEED_DOOM_FONT_LAST do
  begin
    LSource := AWad.IndexOf(Format('%s%.3d', [SPEED_SMALL_FONT_PREFIX, LCharacter]));
    LName := Format('%s%.3d', [SPEED_DOOM_FONT_PREFIX, LCharacter]);
    if (LSource >= 0) and (AWad.IndexOf(LName) < 0) then
    begin
      AWad.AddLump(LName, AWad.LumpData[LSource]);
      Inc(Result);
    end;
  end;
end;

end.
