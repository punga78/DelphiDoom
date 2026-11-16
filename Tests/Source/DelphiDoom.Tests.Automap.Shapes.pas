{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the vector shapes                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Shapes;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Automap.Types,
  DelphiDoom.Automap.Shapes;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapShapes = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseLineeDelVecchioAM_InitPerDoomEStrife;
    [Test]
    procedure DovrebbeDareLeStesseLineeDelVecchioAM_InitPerHereticEHexen;
    [Test]
    procedure DovrebbeContareLeLineeDellaFrecciaPerStile;
    [Test]
    procedure DovrebbeLasciareInalterataLaLineaOltreLaFine;
  end;

implementation

type
  TShapeLines = array of TAutomapLine;

const
  PLAYERRADIUS = AUTOMAP_PLAYERRADIUS;
  MAPUNIT = AUTOMAP_MAPUNIT;

// The text below is the raw one of AM_Init of Base\am_map.pas before the shapes became
// TAutomapShapes (commit 1e049049), compiled once for each family of games with its own {$IF}s
{$UNDEF HERETIC}
{$UNDEF HEXEN}
procedure OldShapesDoom(var player_arrow, cheat_player_arrow, triangle_guy, thintriangle_guy, traceplayer_guy,
  keysquare: TShapeLines);
var
  pl: PAutomapLine;
begin
  pl := @player_arrow[0];
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.a.y := 0;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////

  pl := @cheat_player_arrow[0];
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 10;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

////////////////////////////////////////////////////////////////////////////////

  pl := @triangle_guy[0];
  pl.a.x := round(-0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := round(0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

  inc(pl);
  pl.a.x := round(0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := 0;
  pl.b.y := MAPUNIT;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := MAPUNIT;
  pl.b.x := round(-0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////

  pl := @thintriangle_guy[0];
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := MAPUNIT;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := MAPUNIT;
  pl.a.y := 0;
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(0.7 * MAPUNIT);

  inc(pl);
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(-0.7 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl := @keysquare[0];
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);  // handle part type thing
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);  // stem
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);  // end lockpick part
  pl.a.x := -((8 * PLAYERRADIUS) div 7);
  pl.a.y :=  0;
  pl.b.x :=  -((8 * PLAYERRADIUS) div 7);
  pl.b.y :=  -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := 0;
  pl.b.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

////////////////////////////////////////////////////////////////////////////////
{$ENDIF}

  pl := @traceplayer_guy[0];
  pl.a.x := 0;
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

////////////////////////////////////////////////////////////////////////////////
end;

{$DEFINE HERETIC}
procedure OldShapesRaven(var player_arrow, cheat_player_arrow, triangle_guy, thintriangle_guy, traceplayer_guy,
  keysquare: TShapeLines);
var
  pl: PAutomapLine;
begin
  pl := @player_arrow[0];
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.a.y := 0;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
{$ENDIF}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 4;
{$ELSE}
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
{$ENDIF}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

  inc(pl);
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
{$ENDIF}
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 8;
{$ELSE}
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////

  pl := @cheat_player_arrow[0];
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7);
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) - ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) + 3 * ((8 * PLAYERRADIUS) div 7) div 8;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) + ((8 * PLAYERRADIUS) div 7) div 8;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 2 + ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 6;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.x := 0;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 4;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 32;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 7 - ((8 * PLAYERRADIUS) div 7) div 32;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 6 + ((8 * PLAYERRADIUS) div 7) div 10;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 7;

////////////////////////////////////////////////////////////////////////////////

  pl := @triangle_guy[0];
  pl.a.x := round(-0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := round(0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

  inc(pl);
  pl.a.x := round(0.867 * MAPUNIT);
  pl.a.y := round(-0.5 * MAPUNIT);
  pl.b.x := 0;
  pl.b.y := MAPUNIT;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := MAPUNIT;
  pl.b.x := round(-0.867 * MAPUNIT);
  pl.b.y := round(-0.5 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////

  pl := @thintriangle_guy[0];
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := MAPUNIT;
  pl.b.y := 0;

  inc(pl);
  pl.a.x := MAPUNIT;
  pl.a.y := 0;
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(0.7 * MAPUNIT);

  inc(pl);
  pl.a.x := round(-0.5 * MAPUNIT);
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(-0.5 * MAPUNIT);
  pl.b.y := round(-0.7 * MAPUNIT);

////////////////////////////////////////////////////////////////////////////////
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pl := @keysquare[0];
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := -((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := ((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);  // handle part type thing
  pl.a.x := ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := ((8 * PLAYERRADIUS) div 7) div 2;
  pl.b.x := 0;
  pl.b.y := 0;

  inc(pl);  // stem
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := -((8 * PLAYERRADIUS) div 7);
  pl.b.y := 0;

  inc(pl);  // end lockpick part
  pl.a.x := -((8 * PLAYERRADIUS) div 7);
  pl.a.y :=  0;
  pl.b.x :=  -((8 * PLAYERRADIUS) div 7);
  pl.b.y :=  -((8 * PLAYERRADIUS) div 7) div 2;

  inc(pl);
  pl.a.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.a.y := 0;
  pl.b.x := -3 * ((8 * PLAYERRADIUS) div 7) div 4;
  pl.b.y := -((8 * PLAYERRADIUS) div 7) div 4;

////////////////////////////////////////////////////////////////////////////////
{$ENDIF}

  pl := @traceplayer_guy[0];
  pl.a.x := 0;
  pl.a.y := round(-0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := round(0.7 * MAPUNIT);
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

  inc(pl);
  pl.a.x := 0;
  pl.a.y := 0;
  pl.b.x := round(0.7 * MAPUNIT);
  pl.b.y := 0;

////////////////////////////////////////////////////////////////////////////////
end;
{$UNDEF HERETIC}

procedure CompareLines(const AExpected, AActual: TShapeLines; const AName: string);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual), AName + ' count');
  for LIndex := 0 to High(AExpected) do
  begin
    Assert.AreEqual<Integer>(AExpected[LIndex].A.X, AActual[LIndex].A.X, Format('%s[%d].A.X', [AName, LIndex]));
    Assert.AreEqual<Integer>(AExpected[LIndex].A.Y, AActual[LIndex].A.Y, Format('%s[%d].A.Y', [AName, LIndex]));
    Assert.AreEqual<Integer>(AExpected[LIndex].B.X, AActual[LIndex].B.X, Format('%s[%d].B.X', [AName, LIndex]));
    Assert.AreEqual<Integer>(AExpected[LIndex].B.Y, AActual[LIndex].B.Y, Format('%s[%d].B.Y', [AName, LIndex]));
  end;
end;

procedure TTestAutomapShapes.DovrebbeDareLeStesseLineeDelVecchioAM_InitPerDoomEStrife;
var
  LArrow, LCheat, LTriangle, LThin, LTrace, LKey: TShapeLines;
  LNewArrow, LNewCheat, LNewTriangle, LNewThin, LNewTrace: TShapeLines;
begin
  SetLength(LArrow, 7);
  SetLength(LCheat, 16);
  SetLength(LTriangle, 3);
  SetLength(LThin, 3);
  SetLength(LTrace, 3);
  SetLength(LKey, 8);
  OldShapesDoom(LArrow, LCheat, LTriangle, LThin, LTrace, LKey);
  SetLength(LNewArrow, 7);
  SetLength(LNewCheat, 16);
  SetLength(LNewTriangle, 3);
  SetLength(LNewThin, 3);
  SetLength(LNewTrace, 3);
  TAutomapShapes.FillPlayerArrow(@LNewArrow[0], assDoom);
  TAutomapShapes.FillCheatPlayerArrow(@LNewCheat[0]);
  TAutomapShapes.FillTriangleGuy(@LNewTriangle[0]);
  TAutomapShapes.FillThinTriangleGuy(@LNewThin[0]);
  TAutomapShapes.FillTracePlayerGuy(@LNewTrace[0]);
  CompareLines(LArrow, LNewArrow, 'player_arrow');
  CompareLines(LCheat, LNewCheat, 'cheat_player_arrow');
  CompareLines(LTriangle, LNewTriangle, 'triangle_guy');
  CompareLines(LThin, LNewThin, 'thintriangle_guy');
  CompareLines(LTrace, LNewTrace, 'traceplayer_guy');
end;

procedure TTestAutomapShapes.DovrebbeDareLeStesseLineeDelVecchioAM_InitPerHereticEHexen;
var
  LArrow, LCheat, LTriangle, LThin, LTrace, LKey: TShapeLines;
  LNewArrow, LNewCheat, LNewTriangle, LNewThin, LNewTrace, LNewKey: TShapeLines;
begin
  SetLength(LArrow, 10);
  SetLength(LCheat, 16);
  SetLength(LTriangle, 3);
  SetLength(LThin, 3);
  SetLength(LTrace, 3);
  SetLength(LKey, 8);
  OldShapesRaven(LArrow, LCheat, LTriangle, LThin, LTrace, LKey);
  SetLength(LNewArrow, 10);
  SetLength(LNewCheat, 16);
  SetLength(LNewTriangle, 3);
  SetLength(LNewThin, 3);
  SetLength(LNewTrace, 3);
  SetLength(LNewKey, 8);
  TAutomapShapes.FillPlayerArrow(@LNewArrow[0], assRaven);
  TAutomapShapes.FillCheatPlayerArrow(@LNewCheat[0]);
  TAutomapShapes.FillTriangleGuy(@LNewTriangle[0]);
  TAutomapShapes.FillThinTriangleGuy(@LNewThin[0]);
  TAutomapShapes.FillTracePlayerGuy(@LNewTrace[0]);
  TAutomapShapes.FillKeySquare(@LNewKey[0]);
  CompareLines(LArrow, LNewArrow, 'player_arrow');
  CompareLines(LCheat, LNewCheat, 'cheat_player_arrow');
  CompareLines(LTriangle, LNewTriangle, 'triangle_guy');
  CompareLines(LThin, LNewThin, 'thintriangle_guy');
  CompareLines(LTrace, LNewTrace, 'traceplayer_guy');
  CompareLines(LKey, LNewKey, 'keysquare');
end;

procedure TTestAutomapShapes.DovrebbeContareLeLineeDellaFrecciaPerStile;
begin
  Assert.AreEqual(7, TAutomapShapes.PlayerArrowLineCount(assDoom));
  Assert.AreEqual(10, TAutomapShapes.PlayerArrowLineCount(assRaven));
end;

procedure TTestAutomapShapes.DovrebbeLasciareInalterataLaLineaOltreLaFine;
var
  LLines: TShapeLines;
begin
  // the sentinel after the last line of the thin triangle must not be written
  SetLength(LLines, 4);
  LLines[3].A.X := 12345;
  TAutomapShapes.FillThinTriangleGuy(@LLines[0]);
  Assert.AreEqual<Integer>(12345, LLines[3].A.X);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAutomapShapes);

end.