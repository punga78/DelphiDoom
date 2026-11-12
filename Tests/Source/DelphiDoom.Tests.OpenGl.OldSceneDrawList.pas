{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - the old draw list                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The text of gld_drawinfo, gld_AddDrawItem, ADDWALL and of the tails of      }
{  gld_AddFlat and gld_AddSprite of Libs\OpenGl\Legacy\gl_render.pas before    }
{  Libs\GlScene, kept only to compare the new class with it. The global        }
{  variables are fields of a record and Z_Realloc is ReallocMem.               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldSceneDrawList;

// the frame counter is a byte that wraps, as in the engine (compiled without overflow checks)
{$Q-}
{$R-}

interface

type
  // stand-ins of the records of gl_render: only the size and one field to recognise them matter
  GLWall = record
    id: integer;
    filler: array[0..12] of single;
  end;
  PGLWall = ^GLWall;
  GLWallArray = array[0..$FFFF] of GLWall;
  PGLWallArray = ^GLWallArray;

  GLFlat = record
    id: integer;
    filler: array[0..8] of single;
  end;
  PGLFlat = ^GLFlat;
  GLFlatArray = array[0..$FFFF] of GLFlat;
  PGLFlatArray = ^GLFlatArray;

  GLSprite = record
    id: integer;
    filler: array[0..20] of single;
  end;
  PGLSprite = ^GLSprite;
  GLSpriteArray = array[0..$FFFF] of GLSprite;
  PGLSpriteArray = ^GLSpriteArray;

  GLDrawItemType = (
    GLDIT_NONE,
    GLDIT_WALL,
    GLDIT_FLAT,
    GLDIT_SPRITE,
    GLDIT_DLIGHT
  );

  GLDrawItem = record
    itemtype: GLDrawItemType;
    itemcount: integer;
    firstitemindex: integer;
    rendermarker: byte;
  end;
  PGLDrawItem = ^GLDrawItem;
  GLDrawItemArray = array[0..$FFFF] of GLDrawItem;
  PGLDrawItemArray = ^GLDrawItemArray;

  GLDrawInfo = record
    walls: PGLWallArray;
    num_walls: integer;
    max_walls: integer;
    flats: PGLFlatArray;
    num_flats: integer;
    max_flats: integer;
    sprites: PGLSpriteArray;
    num_sprites: integer;
    max_sprites: integer;
    drawitems: PGLDrawItemArray;
    num_drawitems: integer;
    max_drawitems: integer;
  end;

  TOldSceneDrawList = record
    gld_drawinfo: GLDrawInfo;
    rendermarker: byte;
  end;

procedure old_InitDrawList(var old: TOldSceneDrawList);

// the lines of gld_StartDrawScene that start a frame
procedure old_StartFrame(var old: TOldSceneDrawList);

procedure old_AddWall(var old: TOldSceneDrawList; wall: PGLWall);

procedure old_AddFlat(var old: TOldSceneDrawList; const flat: GLFlat);

procedure old_AddSprite(var old: TOldSceneDrawList; const sprite: GLSprite);

// the zone gave the blocks back at the end of the level and gld_PreprocessLevel cleared the record
procedure old_NewLevel(var old: TOldSceneDrawList);

implementation

procedure old_InitDrawList(var old: TOldSceneDrawList);
begin
  FillChar(old, SizeOf(old), 0);
end;

procedure old_StartFrame(var old: TOldSceneDrawList);
begin
  with old do
  begin
    inc(rendermarker);
    gld_drawinfo.num_walls := 0;
    gld_drawinfo.num_flats := 0;
    gld_drawinfo.num_sprites := 0;
    gld_drawinfo.num_drawitems := 0;
  end;
end;

procedure gld_AddDrawItem(var old: TOldSceneDrawList; itemtype: GLDrawItemType; itemindex: integer);
var
  item: PGLDrawItem;
begin
  with old do
  begin
    if gld_drawinfo.num_drawitems >= gld_drawinfo.max_drawitems then
    begin
      gld_drawinfo.max_drawitems := gld_drawinfo.max_drawitems + 64;
      ReallocMem(gld_drawinfo.drawitems, gld_drawinfo.max_drawitems * SizeOf(GLDrawItem));
      item := @gld_drawinfo.drawitems[gld_drawinfo.num_drawitems];
      item.itemtype := itemtype;
      item.itemcount := 1;
      item.firstitemindex := itemindex;
      item.rendermarker := rendermarker;
      exit;
    end;
    item := @gld_drawinfo.drawitems[gld_drawinfo.num_drawitems];
    if item.rendermarker <> rendermarker then
    begin
      item.itemtype := GLDIT_NONE;
      item.rendermarker := rendermarker;
    end;
    if item.itemtype <> itemtype then
    begin
      if item.itemtype <> GLDIT_NONE then
      begin
        inc(gld_drawinfo.num_drawitems);
      end;
      if gld_drawinfo.num_drawitems >= gld_drawinfo.max_drawitems then
      begin
        gld_drawinfo.max_drawitems := gld_drawinfo.max_drawitems + 64;
        ReallocMem(gld_drawinfo.drawitems, gld_drawinfo.max_drawitems * SizeOf(GLDrawItem));
      end;
      item := @gld_drawinfo.drawitems[gld_drawinfo.num_drawitems];
      item.itemtype := itemtype;
      item.itemcount := 1;
      item.firstitemindex := itemindex;
      item.rendermarker := rendermarker;
      exit;
    end;
    inc(item.itemcount);
  end;
end;

procedure old_AddWall(var old: TOldSceneDrawList; wall: PGLWall);
begin
  with old do
  begin
    if gld_drawinfo.num_walls >= gld_drawinfo.max_walls then
    begin
      gld_drawinfo.max_walls := gld_drawinfo.max_walls + 128;
      ReallocMem(gld_drawinfo.walls, gld_drawinfo.max_walls * SizeOf(GLWall));
    end;
    gld_AddDrawItem(old, GLDIT_WALL, gld_drawinfo.num_walls);
    gld_drawinfo.walls[gld_drawinfo.num_walls] := wall^;
    inc(gld_drawinfo.num_walls);
  end;
end;

procedure old_AddFlat(var old: TOldSceneDrawList; const flat: GLFlat);
begin
  with old do
  begin
    if gld_drawinfo.num_flats >= gld_drawinfo.max_flats then
    begin
      gld_drawinfo.max_flats := gld_drawinfo.max_flats + 128;
      ReallocMem(gld_drawinfo.flats, gld_drawinfo.max_flats * SizeOf(GLFlat));
    end;
    gld_AddDrawItem(old, GLDIT_FLAT, gld_drawinfo.num_flats);
    gld_drawinfo.flats[gld_drawinfo.num_flats] := flat;
    inc(gld_drawinfo.num_flats);
  end;
end;

procedure old_AddSprite(var old: TOldSceneDrawList; const sprite: GLSprite);
begin
  with old do
  begin
    if gld_drawinfo.num_sprites >= gld_drawinfo.max_sprites then
    begin
      gld_drawinfo.max_sprites := gld_drawinfo.max_sprites + 128;
      ReallocMem(gld_drawinfo.sprites, gld_drawinfo.max_sprites * SizeOf(GLSprite));
    end;
    gld_AddDrawItem(old, GLDIT_SPRITE, gld_drawinfo.num_sprites);
    gld_drawinfo.sprites[gld_drawinfo.num_sprites] := sprite;
    inc(gld_drawinfo.num_sprites);
  end;
end;

procedure old_NewLevel(var old: TOldSceneDrawList);
begin
  with old do
  begin
    FreeMem(gld_drawinfo.walls);
    FreeMem(gld_drawinfo.flats);
    FreeMem(gld_drawinfo.sprites);
    FreeMem(gld_drawinfo.drawitems);
    FillChar(gld_drawinfo, SizeOf(GLDrawInfo), 0);
  end;
end;

end.
