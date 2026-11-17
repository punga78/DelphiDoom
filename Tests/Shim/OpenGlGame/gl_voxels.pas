{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_voxels for the per-game OpenGL scene tests      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_voxels.pas in DelphiDoom.Tests.OpenGl.<Game> only: the initialization call is a line of EventLog.
unit gl_voxels;

interface

uses
  System.SysUtils;

procedure gld_InitVoxels;

implementation

uses
  d_delphi;

procedure gld_InitVoxels;
begin
  ShimEvent('gld_InitVoxels');
end;

end.
