{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the points of the path from the map files      }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the reading in SH_LoadPath of speed_path.pas                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.PathReader;

interface

uses
  System.SysUtils, DelphiDoom.Racing.Types;

const
  /// <summary>The number of the thing of the map that marks a point of the path (the old _SHTH_PATH)</summary>
  RACING_PATH_THING_TYPE = 512;

type
  /// <summary>
  ///   Reads the points of the track from the PATH and THINGS lumps of a level, or from the text
  ///   file that a mod can give instead. The game makes an object of each point, as it does for
  ///   any thing of the map, and gives the track the position and the angle of the object
  /// </summary>
  TRacingPathReader = class
  public
    /// <summary>
    ///   The points of a level. The things of the path are in the THINGS lump (a thing of type
    ///   RACING_PATH_THING_TYPE for every point, in order) and the speeds in the PATH lump (16 bytes
    ///   for a point; the speed is the last 4 bytes, in 1/10240 of a km/h). The lump of the path
    ///   decides how many points there are: surplus things are not read
    /// </summary>
    class function FromLumps(const AThings, APath: TBytes): TArray<TRacingPathThing>; static;
    /// <summary>
    ///   The points of a text file: four numbers for each point (x, y, angle in degrees and the
    ///   speed in km/h), separated by spaces or lines; // starts a comment. Numbers that are not
    ///   complete are not read
    /// </summary>
    class function FromText(const AText: string): TArray<TRacingPathThing>; static;
  end;

implementation

uses
  System.Classes;

const
  PATH_TO_KMH_DIVIDER = 10240;
  THING_SIZE = 10;
  PATH_POINT_SIZE = 16;

{ TRacingPathReader }

class function TRacingPathReader.FromLumps(const AThings, APath: TBytes): TArray<TRacingPathThing>;
var
  LPointCount, LThingCount, LThing, LPoint: Integer;
  LOffset: Integer;
begin
  LPointCount := Length(APath) div PATH_POINT_SIZE;
  LThingCount := Length(AThings) div THING_SIZE;
  SetLength(Result, LPointCount);

  LPoint := 0;
  for LThing := 0 to LThingCount - 1 do
  begin
    LOffset := LThing * THING_SIZE;
    if PWord(@AThings[LOffset + 6])^ = RACING_PATH_THING_TYPE then
    begin
      if LPoint >= LPointCount then
        Break;
      Result[LPoint].X := PSmallInt(@AThings[LOffset])^;
      Result[LPoint].Y := PSmallInt(@AThings[LOffset + 2])^;
      Result[LPoint].Angle := PSmallInt(@AThings[LOffset + 4])^;
      Result[LPoint].Speed := PInteger(@APath[LPoint * PATH_POINT_SIZE + 12])^ div PATH_TO_KMH_DIVIDER;
      Inc(LPoint);
    end;
  end;
  SetLength(Result, LPoint);
end;

class function TRacingPathReader.FromText(const AText: string): TArray<TRacingPathThing>;
var
  LTokens: TStringList;
  LLines: TStringList;
  LLine, LComment, LPoint: Integer;
  LText: string;

  function Number(AIndex: Integer): Integer;
  begin
    if not TryStrToInt(LTokens[AIndex], Result) then
      Result := 0;
  end;

begin
  LTokens := TStringList.Create;
  LLines := TStringList.Create;
  try
    LTokens.Delimiter := ' ';
    LTokens.StrictDelimiter := True;
    LLines.Text := AText;
    for LLine := 0 to LLines.Count - 1 do
    begin
      LText := LLines[LLine];
      LComment := Pos('//', LText);
      if LComment > 0 then
        LText := Copy(LText, 1, LComment - 1);
      LText := StringReplace(StringReplace(LText, #9, ' ', [rfReplaceAll]), ',', ' ', [rfReplaceAll]);
      while LText <> '' do
      begin
        LText := TrimLeft(LText);
        if LText = '' then
          Break;
        LComment := Pos(' ', LText);
        if LComment = 0 then
        begin
          LTokens.Add(LText);
          LText := '';
        end
        else
        begin
          LTokens.Add(Copy(LText, 1, LComment - 1));
          LText := Copy(LText, LComment + 1, MaxInt);
        end;
      end;
    end;

    SetLength(Result, LTokens.Count div 4);
    for LPoint := 0 to High(Result) do
    begin
      Result[LPoint].X := Number(LPoint * 4);
      Result[LPoint].Y := Number(LPoint * 4 + 1);
      Result[LPoint].Angle := Number(LPoint * 4 + 2);
      Result[LPoint].Speed := Number(LPoint * 4 + 3);
    end;
  finally
    LLines.Free;
    LTokens.Free;
  end;
end;

end.
