{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - a .proc file written by hand    }
{  in the format of dmap (no data of Doom 3)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcSample;

interface

type
  TProcSample = class
  public
    /// <summary>A file with every kind of section, exactly as dmap writes it</summary>
    class function Full: AnsiString; static;
    /// <summary>The same sections in another order and with other spacing</summary>
    class function Shuffled: AnsiString; static;
  end;

implementation

const
  HEADER = 'mapProcFile003'#10#10;
  MODEL =
    'model { /* name = */ "_area0" /* numSurfaces = */ 2'#10#10 +
    '/* surface 0 */ { "textures/base/wall" /* numVerts = */ 4 /* numIndexes = */ 6'#10 +
    '( 0 0 0 0 0 0 0 1 ) ( 64 0 0 1 0 0 0 1 ) ( 64 64 0 1 1 0 0 1 ) '#10 +
    '( 0 64 0 0 1 0 0 1 ) '#10 +
    '0 1 2 0 2 3 '#10 +
    '}'#10#10 +
    '/* surface 1 */ { "textures/base/floor" /* numVerts = */ 3 /* numIndexes = */ 3'#10 +
    '( 0.5 0.25 -1 0.125 2.5 0 0 -1 ) ( 1 0 0 0 0 0 0 -1 ) ( 0 1 0 0 0 0 0 -1 ) '#10 +
    '0 1 2 '#10 +
    '}'#10#10 +
    '}'#10#10;
  PORTALS =
    'interAreaPortals { /* numAreas = */ 2 /* numIAP = */ 1'#10#10 +
    '/* interAreaPortal format is: numPoints positiveSideArea negativeSideArea ( point) ... */'#10 +
    '/* iap 0 */ 4 0 1 ( 0 0 0 ) ( 0 64 0 ) ( 0 64 64 ) ( 0 0 64 ) '#10 +
    '}'#10#10;
  NODES =
    'nodes { /* numNodes = */ 2'#10#10 +
    '/* node format is: ( planeVector ) positiveChild negativeChild */'#10 +
    '/* a child number of 0 is an opaque, solid area */'#10 +
    '/* negative child numbers are areas: (-1-child) */'#10 +
    '/* node 0 */ ( 1 0 0 -32.5 ) 1 -2'#10 +
    '/* node 1 */ ( 0 1 0 0 ) -1 0'#10 +
    '}'#10#10;
  SHADOW =
    'shadowModel { /* name = */ "_prelight_light1"'#10#10 +
    '/* numVerts = */ 3 /* noCaps = */ 3 /* noFrontCaps = */ 3 /* numIndexes = */ 3 /* planeBits = */ 7'#10 +
    '( 0 0 0 ) ( 1 0 0 ) ( 0 2.5 0 ) '#10 +
    '0 1 2 '#10 +
    '}'#10#10;

class function TProcSample.Full: AnsiString;
begin
  Result := HEADER + MODEL + PORTALS + NODES + SHADOW;
end;

class function TProcSample.Shuffled: AnsiString;
begin
  Result := 'mapProcFile003'#10 + SHADOW + NODES + MODEL + PORTALS;
end;

end.
