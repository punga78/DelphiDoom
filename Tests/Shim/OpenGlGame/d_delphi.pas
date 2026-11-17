{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_delphi for the per-game OpenGL scene tests        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Common\d_delphi.pas in DelphiDoom.Tests.OpenGl.<Game> only: the scene units take
// from it the type float and the allocation helpers of the light buffer.
unit d_delphi;

interface

type
  float = Single;
  Pfloat = ^float;

/// <summary>The realloc of d_delphi: a block of the new size that keeps the bytes of the old one</summary>
procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);

implementation

procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);
begin
  if NewSize = 0 then
  begin
    FreeMem(P, OldSize);
    P := nil;
  end
  else if NewSize <> OldSize then
    ReallocMem(P, NewSize);
end;

end.
