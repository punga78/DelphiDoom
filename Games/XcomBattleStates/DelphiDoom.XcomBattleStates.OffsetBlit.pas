{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battle states library - a widget placed in a surface,       }
{  copied on the target of that surface (issue 188)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.OffsetBlit;

interface

uses
  DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   A widget that has text (a message, a menu line) and sits inside another surface used to be drawn into that
  ///   surface, which was then copied on the screen: the text was then a picture of the game when it reached the
  ///   screen, and the screen could not draw it at its own resolution (the ink of a text is only left by a text
  ///   that is copied on the screen itself). Here the widget is copied on the target straight, with its place moved
  ///   by the place of the surface it belongs to, and put back
  /// </summary>
  TXcomOffsetBlit = class
  public
    /// <summary>
    ///   AWidget.Blit(ATarget) with the widget moved by (ADeltaX, ADeltaY) for the time of the call; the widget
    ///   keeps its place (relative to its surface) afterwards, also when the blit raises
    /// </summary>
    class procedure Blit(AWidget: TXcomSurface; ATarget: TXcomSurface; ADeltaX, ADeltaY: Integer); static;
  end;

implementation

class procedure TXcomOffsetBlit.Blit(AWidget: TXcomSurface; ATarget: TXcomSurface; ADeltaX, ADeltaY: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  LX := AWidget.X;
  LY := AWidget.Y;
  AWidget.X := LX + ADeltaX;
  AWidget.Y := LY + ADeltaY;
  try
    AWidget.Blit(ATarget);
  finally
    AWidget.X := LX;
    AWidget.Y := LY;
  end;
end;

end.
