{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the standard resolutions of the desktop          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.StandardResolutions;

interface

type
  /// <summary>
  ///   The table of the standard screen resolutions that the full screen mode tries when the system refuses the
  ///   size of the window (the rule of I_ChangeFullScreen). Static, no state
  /// </summary>
  TVideoStandardResolutions = class sealed
  public
    /// <summary>
    ///   Picks the resolution out of the table for AWidth x AHeight. The first standard resolution that holds the
    ///   size and whose next one is not wider than AWidth wins; when none does, the size stays as it is. The engine
    ///   passes the smallest one (320x200) and so it always gets 400x300: the old rule, kept
    /// </summary>
    class procedure Choose(var AWidth, AHeight: Integer); static;
    /// <summary>The number of standard resolutions</summary>
    class function Count: Integer; static;
    /// <summary>The width of the resolution AIndex (the table goes from the widest to the narrowest)</summary>
    class function WidthOf(const AIndex: Integer): Integer; static;
    /// <summary>The height of the resolution AIndex</summary>
    class function HeightOf(const AIndex: Integer): Integer; static;
  end;

implementation

const
  NUMSTDRESOLUTIONS = 11;
  STANDARDSCREENRESOLUTIONS: array[0..NUMSTDRESOLUTIONS - 1, 0..1] of Integer = (
    (1920, 1080), (1366, 768), (1280, 1024), (1280, 800), (1024, 768), (800, 600), (640, 480), (600, 400),
    (512, 384), (400, 300), (320, 200)
  );

{ TVideoStandardResolutions }

class procedure TVideoStandardResolutions.Choose(var AWidth, AHeight: Integer);
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < NUMSTDRESOLUTIONS - 1 do
  begin
    if (AWidth <= STANDARDSCREENRESOLUTIONS[LIndex, 0]) and
       (AHeight <= STANDARDSCREENRESOLUTIONS[LIndex, 1]) and
       (AWidth >= STANDARDSCREENRESOLUTIONS[LIndex + 1, 0]) then
    begin
      AWidth := STANDARDSCREENRESOLUTIONS[LIndex, 0];
      AHeight := STANDARDSCREENRESOLUTIONS[LIndex, 1];
      Break;
    end;
    Inc(LIndex);
  end;
end;

class function TVideoStandardResolutions.Count: Integer;
begin
  Result := NUMSTDRESOLUTIONS;
end;

class function TVideoStandardResolutions.WidthOf(const AIndex: Integer): Integer;
begin
  Result := STANDARDSCREENRESOLUTIONS[AIndex, 0];
end;

class function TVideoStandardResolutions.HeightOf(const AIndex: Integer): Integer;
begin
  Result := STANDARDSCREENRESOLUTIONS[AIndex, 1];
end;

end.
