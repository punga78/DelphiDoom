{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the tables that stretch 320x200 coordinates      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PreserveTables;

interface

type
  /// <summary>
  ///   The "preserve" tables of v_video: they turn a coordinate of a 320x200 (or 426x200)
  ///   picture into a coordinate of the screen. It is a plain object, not an interface: the
  ///   lookups run for every patch and rectangle drawn, so they are direct, non-virtual calls
  ///   on a table that does not change between two calls of Calculate
  /// </summary>
  TVideoPreserveTables = class sealed
  strict private
    FX320: array[0..319] of Integer;
    FX426: array[0..425] of Integer;
    FY200: array[0..199] of Integer;
    FTargetWidth: Integer;
    FTargetHeight: Integer;
    FWidthMultiplier: Integer;
    FHeightMultiplier: Integer;
  public
    /// <summary>Rebuilds the tables for a screen of the given size (after every change of mode)</summary>
    procedure Calculate(const ATargetWidth, ATargetHeight: Integer);
    /// <summary>The x of a 320 wide picture on the screen</summary>
    function MapX(const AX: Integer): Integer; overload;
    /// <summary>The x of a picture of the given width (320, 426 or any other) on the screen</summary>
    function MapX(const ASourceWidth: Integer; const AX: Integer): Integer; overload;
    /// <summary>The y of a 200 high picture on the screen</summary>
    function MapY(const AY: Integer): Integer;
    /// <summary>The integer ratio of the screen width to 320, 0 if it is not an integer</summary>
    property WidthMultiplier: Integer read FWidthMultiplier;
    /// <summary>The integer ratio of the screen height to 200, 0 if it is not an integer</summary>
    property HeightMultiplier: Integer read FHeightMultiplier;
    property TargetWidth: Integer read FTargetWidth;
    property TargetHeight: Integer read FTargetHeight;
  end;

implementation

{ TVideoPreserveTables }

procedure TVideoPreserveTables.Calculate(const ATargetWidth, ATargetHeight: Integer);
var
  LIndex: Integer;
begin
  FTargetWidth := ATargetWidth;
  FTargetHeight := ATargetHeight;
  for LIndex := 0 to 319 do
    FX320[LIndex] := Trunc(LIndex * ATargetWidth / 320);
  for LIndex := 0 to 425 do
    FX426[LIndex] := Trunc(LIndex * ATargetWidth / 426);
  for LIndex := 0 to 199 do
    FY200[LIndex] := Trunc(LIndex * ATargetHeight / 200);
  if ATargetWidth mod 320 = 0 then
    FWidthMultiplier := ATargetWidth div 320
  else
    FWidthMultiplier := 0;
  if ATargetHeight mod 200 = 0 then
    FHeightMultiplier := ATargetHeight div 200
  else
    FHeightMultiplier := 0;
end;

function TVideoPreserveTables.MapX(const AX: Integer): Integer;
begin
  // A screen as wide as the picture has FX320[x] = x: no shortcut is needed
  if AX <= 0 then
    Result := 0
  else if AX >= 320 then
    Result := FTargetWidth
  else
    Result := FX320[AX];
end;

function TVideoPreserveTables.MapX(const ASourceWidth: Integer; const AX: Integer): Integer;
begin
  if AX <= 0 then
    Result := 0
  else if AX >= ASourceWidth then
    Result := FTargetWidth
  else if ASourceWidth = 320 then
    Result := FX320[AX]
  else if ASourceWidth = 426 then
    Result := FX426[AX]
  else
    Result := Trunc(AX * FTargetWidth / ASourceWidth);
end;

function TVideoPreserveTables.MapY(const AY: Integer): Integer;
begin
  if AY <= 0 then
    Result := 0
  else if AY >= 200 then
    Result := FTargetHeight
  else
    Result := FY200[AY];
end;

end.
