{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lines drawn as transparent (special 260)           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.TransparentLines;

interface

type
  /// <summary>
  ///   The special 260 of BOOM: the line, or every line with its tag, is drawn as transparent.
  ///   For the games whose lines have a tag (Doom, Heretic and Strife; Hexen has arguments)
  /// </summary>
  TLevelTransparentLines = class
  public
    /// <summary>Sets LRF_TRANSPARENT in the lines of the level that the special names</summary>
    class procedure Mark; static;
  end;

implementation

uses
  r_defs,
  p_setup;

const
  TRANSPARENT_LINE_SPECIAL = 260;

{ TLevelTransparentLines }

class procedure TLevelTransparentLines.Mark;
var
  LIndex: Integer;
  LInner: Integer;
  LLine: Pline_t;
begin
  for LIndex := 0 to numlines - 1 do
  begin
    LLine := @lines[LIndex];
    if LLine.special <> TRANSPARENT_LINE_SPECIAL then
      Continue;
    if LLine.tag = 0 then
      LLine.renderflags := LLine.renderflags or LRF_TRANSPARENT
    else
    begin
      for LInner := 0 to numlines - 1 do
        if lines[LInner].tag = LLine.tag then
          lines[LInner].renderflags := lines[LInner].renderflags or LRF_TRANSPARENT
    end;
  end;
end;

end.
