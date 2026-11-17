{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the choices of V_PageDrawer                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PageLayout;

interface

type
  /// <summary>
  ///   Pure rules of V_PageDrawer (v_video, Doom and Strife): how a full screen patch is drawn. Cold
  ///   (once per page), static functions, no state
  /// </summary>
  TVideoPageLayout = class sealed
  public
    /// <summary>A patch larger than 320x200 is drawn on a temporary screen of its own size</summary>
    class function IsOversized(const AWidth, AHeight: Integer): Boolean; static;
    /// <summary>The oversized patch is scaled down when it does not fit the screen of the game</summary>
    class function NeedsDownscale(const AWidth, AHeight, AScreenWidth, AScreenHeight: Integer): Boolean; static;
    /// <summary>The page is stretched to the monitor unless the patch is already 426x200 (wide pages of Doom)</summary>
    class function NeedsStretch(const AWidth, AHeight: Integer): Boolean; static;
  end;

implementation

class function TVideoPageLayout.IsOversized(const AWidth, AHeight: Integer): Boolean;
begin
  Result := (AWidth > 320) or (AHeight > 200);
end;

class function TVideoPageLayout.NeedsDownscale(const AWidth, AHeight, AScreenWidth, AScreenHeight: Integer): Boolean;
begin
  Result := (AWidth > AScreenWidth) or (AHeight > AScreenHeight);
end;

class function TVideoPageLayout.NeedsStretch(const AWidth, AHeight: Integer): Boolean;
begin
  Result := (AWidth <> 426) or (AHeight <> 200);
end;

end.
