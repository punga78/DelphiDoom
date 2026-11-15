{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the list of colors of the debug drawing (GENERATED)}
{                                                                              }
{  Port of war1 (acoto87/war1), war_render.c (wr_getColorFromList), (c) 2019    }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This }
{  is an altered version, not the original.                                    }
{                                                                              }
{  Written by Tools\Verifica\197\Make-WarColorList.ps1 from the original C     }
{  code: do not edit by hand                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Render.ColorList.Data;

interface

uses
  DelphiDoom.War.Render.Types;

const
  WAR_COLOR_LIST_COUNT = 85;
  /// <summary>The 85 colors of wr_getColorFromList, opaque</summary>
  WAR_COLOR_LIST: array[0..WAR_COLOR_LIST_COUNT - 1] of TWarRgba = (
    (R: 229; G: 43; B: 80; A: 255),
    (R: 255; G: 191; B: 0; A: 255),
    (R: 153; G: 102; B: 204; A: 255),
    (R: 251; G: 206; B: 177; A: 255),
    (R: 127; G: 255; B: 212; A: 255),
    (R: 0; G: 127; B: 255; A: 255),
    (R: 137; G: 207; B: 240; A: 255),
    (R: 245; G: 245; B: 220; A: 255),
    (R: 0; G: 0; B: 0; A: 255),
    (R: 0; G: 0; B: 255; A: 255),
    (R: 0; G: 149; B: 182; A: 255),
    (R: 138; G: 43; B: 226; A: 255),
    (R: 222; G: 93; B: 131; A: 255),
    (R: 205; G: 127; B: 50; A: 255),
    (R: 150; G: 75; B: 0; A: 255),
    (R: 128; G: 0; B: 32; A: 255),
    (R: 112; G: 41; B: 99; A: 255),
    (R: 150; G: 0; B: 24; A: 255),
    (R: 222; G: 49; B: 99; A: 255),
    (R: 0; G: 123; B: 167; A: 255),
    (R: 247; G: 231; B: 206; A: 255),
    (R: 127; G: 255; B: 0; A: 255),
    (R: 123; G: 63; B: 0; A: 255),
    (R: 0; G: 71; B: 171; A: 255),
    (R: 111; G: 78; B: 55; A: 255),
    (R: 184; G: 115; B: 51; A: 255),
    (R: 248; G: 131; B: 121; A: 255),
    (R: 220; G: 20; B: 60; A: 255),
    (R: 0; G: 255; B: 255; A: 255),
    (R: 237; G: 201; B: 175; A: 255),
    (R: 125; G: 249; B: 255; A: 255),
    (R: 80; G: 200; B: 120; A: 255),
    (R: 0; G: 255; B: 63; A: 255),
    (R: 255; G: 215; B: 0; A: 255),
    (R: 128; G: 128; B: 128; A: 255),
    (R: 0; G: 255; B: 0; A: 255),
    (R: 63; G: 255; B: 0; A: 255),
    (R: 75; G: 0; B: 130; A: 255),
    (R: 255; G: 255; B: 240; A: 255),
    (R: 0; G: 168; B: 107; A: 255),
    (R: 41; G: 171; B: 135; A: 255),
    (R: 181; G: 126; B: 220; A: 255),
    (R: 255; G: 247; B: 0; A: 255),
    (R: 200; G: 162; B: 200; A: 255),
    (R: 191; G: 255; B: 0; A: 255),
    (R: 255; G: 0; B: 255; A: 255),
    (R: 255; G: 0; B: 175; A: 255),
    (R: 128; G: 0; B: 0; A: 255),
    (R: 224; G: 176; B: 255; A: 255),
    (R: 0; G: 0; B: 128; A: 255),
    (R: 204; G: 119; B: 34; A: 255),
    (R: 128; G: 128; B: 0; A: 255),
    (R: 255; G: 165; B: 0; A: 255),
    (R: 255; G: 69; B: 0; A: 255),
    (R: 218; G: 112; B: 214; A: 255),
    (R: 255; G: 229; B: 180; A: 255),
    (R: 209; G: 226; B: 49; A: 255),
    (R: 204; G: 204; B: 255; A: 255),
    (R: 28; G: 57; B: 187; A: 255),
    (R: 255; G: 192; B: 203; A: 255),
    (R: 142; G: 69; B: 133; A: 255),
    (R: 0; G: 49; B: 83; A: 255),
    (R: 204; G: 136; B: 153; A: 255),
    (R: 128; G: 0; B: 128; A: 255),
    (R: 227; G: 11; B: 92; A: 255),
    (R: 255; G: 0; B: 0; A: 255),
    (R: 199; G: 21; B: 133; A: 255),
    (R: 255; G: 0; B: 127; A: 255),
    (R: 224; G: 17; B: 95; A: 255),
    (R: 250; G: 128; B: 114; A: 255),
    (R: 146; G: 0; B: 10; A: 255),
    (R: 15; G: 82; B: 186; A: 255),
    (R: 255; G: 36; B: 0; A: 255),
    (R: 192; G: 192; B: 192; A: 255),
    (R: 112; G: 128; B: 144; A: 255),
    (R: 167; G: 252; B: 0; A: 255),
    (R: 0; G: 255; B: 127; A: 255),
    (R: 210; G: 180; B: 140; A: 255),
    (R: 72; G: 60; B: 50; A: 255),
    (R: 0; G: 128; B: 128; A: 255),
    (R: 64; G: 224; B: 208; A: 255),
    (R: 238; G: 130; B: 238; A: 255),
    (R: 64; G: 130; B: 109; A: 255),
    (R: 255; G: 255; B: 255; A: 255),
    (R: 255; G: 255; B: 0; A: 255)
  );

implementation

end.