{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_things for the per-game OpenGL scene tests       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_things.pas in DelphiDoom.Tests.OpenGl.<Game> only: the weapon drawing is a line of EventLog.
unit r_things;

interface

type
  TRendererThings = class sealed
  public
    class procedure R_DrawPlayer; static;
  end;

implementation

uses
  d_delphi;

class procedure TRendererThings.R_DrawPlayer;
begin
  ShimEvent('R_DrawPlayer');
end;

end.