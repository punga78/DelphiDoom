{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_models for the per-game OpenGL scene tests      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_models.pas in DelphiDoom.Tests.OpenGl.<Game> only: the initialization call is a line of EventLog.
unit gl_models;

interface

uses
  System.SysUtils;

procedure gld_InitModels;

implementation

uses
  d_delphi;

procedure gld_InitModels;
begin
  ShimEvent('gld_InitModels');
end;

end.
