{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - what the lump MAPDATA says of a circuit         }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the reading part of speed_mapdata.pas (GLSpeed).                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.MapInfoReader;

interface

type
  /// <summary>
  ///   A circuit as the game shows it: the lump MAPDATA that the translator writes after the
  ///   lumps of each level (the old mapdata_t without the name of the lump, which the caller has)
  /// </summary>
  TSpeedMapInfo = record
    /// <summary>The name of the circuit</summary>
    Name: string;
    /// <summary>The best lap of the authors, as CIRCUITS.LST gives it</summary>
    Best: Integer;
    /// <summary>The difficulty of the circuit</summary>
    Level: Integer;
    /// <summary>The length of a lap in meters</summary>
    Length: Integer;
    /// <summary>The picture of the circuit for the menu</summary>
    MapSprite: string;
    SkyTexture: string;
    MountainTexture: string;
    /// <summary>The flat of the ground around the circuit</summary>
    GroundTexture: string;
  end;

  /// <summary>
  ///   Reads the text of a MAPDATA lump: a line "key=value" for each field. A key that is missing
  ///   leaves its field empty or 0, a number that is not a number is 0 (the old atoi); unknown
  ///   keys and lines without "=" are skipped. The first line of a key counts. Without state
  /// </summary>
  TSpeedMapInfoReader = class
  public
    class function Parse(const AText: string): TSpeedMapInfo; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Speed.Names;

const
  KEY_SPRITE = 'sprite';
  KEY_SKY = 'sky';
  KEY_MOUNTAIN = 'mountain';
  KEY_GROUND = 'ground';
  KEY_NAME = 'name';
  KEY_LENGTH = 'length';
  KEY_BEST = 'best';
  KEY_LEVEL = 'level';

{ TSpeedMapInfoReader }

class function TSpeedMapInfoReader.Parse(const AText: string): TSpeedMapInfo;
var
  LLines: TStringList;
  LSeen: TStringList;
  LLine: string;
  LKey: string;
  LValue: string;
  LSeparator: Integer;
begin
  Result := Default(TSpeedMapInfo);
  LLines := TStringList.Create;
  LSeen := TStringList.Create;
  try
    LLines.Text := AText;
    for LLine in LLines do
    begin
      LSeparator := Pos('=', LLine);
      if LSeparator = 0 then
        Continue;
      LKey := LowerCase(Trim(Copy(LLine, 1, LSeparator - 1)));
      if LSeen.IndexOf(LKey) >= 0 then
        Continue;
      LSeen.Add(LKey);
      LValue := Copy(LLine, LSeparator + 1, MaxInt);
      if LKey = KEY_SPRITE then
        Result.MapSprite := LValue
      else if LKey = KEY_SKY then
        Result.SkyTexture := LValue
      else if LKey = KEY_MOUNTAIN then
        Result.MountainTexture := LValue
      else if LKey = KEY_GROUND then
        Result.GroundTexture := LValue
      else if LKey = KEY_NAME then
        Result.Name := LValue
      else if LKey = KEY_LENGTH then
        Result.Length := TSpeedNames.ToInteger(Trim(LValue))
      else if LKey = KEY_BEST then
        Result.Best := TSpeedNames.ToInteger(Trim(LValue))
      else if LKey = KEY_LEVEL then
        Result.Level := TSpeedNames.ToInteger(Trim(LValue));
    end;
  finally
    LSeen.Free;
    LLines.Free;
  end;
end;

end.
