program RenderParity;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: confronta il renderer ORIGINALE di xGreed (r_render, r_walls, r_plane, r_spans,
// r_conten, r_interpolate, r_public) con il renderer a classi di Libs\Greed sugli stessi scenari
// (Tests\Source\DelphiDoom.Tests.Greed.RenderScenarios). Gli stub sono in stubs\ (d_misc, d_ints, d_video, raven...).
// Uso: RenderParity <cartella con GREED.BLO> <uscita golden.txt> [mappe separate da virgola] [seed] [viste]
uses
  SysUtils, Classes, Windows,
  g_delphi, d_disk, protos_h, r_public_h, r_refdef, r_render, r_walls, r_plane, r_spans, r_conten, r_interpolate,
  r_public, raven, d_ints, d_video, d_misc,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Factory, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.State, DelphiDoom.Tests.Greed.RenderScenarios, DelphiDoom.Tests.Greed.RenderRunner;

var
  Folder, GoldenPath: string;
  Maps: TArray<Integer>;
  Seed: Cardinal = 20260109;
  ViewCount: Integer = 12;
  SpriteCount: Integer = 40;
  Golden: TStringList;
  Runner: TRenderRunner;
  Archive: IGreedArchive;
  TotalDiff, TotalFrames, Skipped: Integer;

procedure InitOriginal;
var
  i, x, size: integer;
  wall, base: PByteArray;
  transparency, lightlump: integer;
  bd: PByteArray;
  bdBytes: TBytes;
begin
  CA_InitFromArchive(Archive);
  spritelump := CA_GetNamedNum('startsprites');
  numsprites := CA_GetNamedNum('endsprites') - spritelump;
  walllump := CA_GetNamedNum('startwalls');
  numwalls := CA_GetNamedNum('endwalls') - walllump;
  flatlump := CA_GetNamedNum('startflats');
  numflats := CA_GetNamedNum('endflats') - flatlump;
  for i := spritelump to spritelump + numsprites - 1 do CA_CacheLump(i);
  for i := walllump to walllump + numwalls - 1 do CA_CacheLump(i);
  for i := flatlump to flatlump + numflats - 1 do CA_CacheLump(i);
  RF_Startup;
  wallposts := mallocz((numwalls + 1) * 64 * 4);
  for i := 0 to numwalls - 2 do
  begin
    wall := lumpcache[walllump + i + 1].data;
    if wall <> nil then
    begin
      base := @wall[65 * 2];
      size := wall[0] * 4;
      for x := 0 to 63 do
        wallposts[i * 64 + x] := @base[size * x];
    end;
  end;
  transparency := CA_GetNamedNum('TRANSPARENCY');
  bd := CA_CacheLump(transparency);
  for i := 0 to 255 do translookup[i] := @bd[256 * i];
  backdrop := malloc(256 * 256);
  bdBytes := RenderTestBackdrop;
  Move(bdBytes[0], backdrop^, 65536);
  for i := 0 to 255 do backdroplookup[i] := @backdrop[256 * i];
  lightlump := 0;
end;

procedure SetupOriginalSprites; forward;

procedure SetupOriginalMap(const World: IGreedWorld);
var
  i, p: integer;
  d: Pdoorobj_t;
  s: Pscaleobj_t;
  sc: ^TGreedSprite;
  door: TGreedDoor;
  sprite: TGreedSprite;
begin
  RF_ClearWorld;
  World.CopyPlane(gpNorthWall, @northwall[0]);
  World.CopyPlane(gpNorthFlags, @northflags[0]);
  World.CopyPlane(gpWestWall, @westwall[0]);
  World.CopyPlane(gpWestFlags, @westflags[0]);
  World.CopyPlane(gpFloorPic, @floorpic[0]);
  World.CopyPlane(gpFloorFlags, @floorflags[0]);
  World.CopyPlane(gpCeilingPic, @ceilingpic[0]);
  World.CopyPlane(gpCeilingFlags, @ceilingflags[0]);
  World.CopyPlane(gpFloorHeight, @floorheight[0]);
  World.CopyPlane(gpCeilingHeight, @ceilingheight[0]);
  World.CopyPlane(gpFloorDef, @floordef[0]);
  World.CopyPlane(gpFloorDefFlags, @floordefflags[0]);
  World.CopyPlane(gpCeilingDef, @ceilingdef[0]);
  World.CopyPlane(gpCeilingDefFlags, @ceilingdefflags[0]);
  World.CopyPlane(gpMapLights, @maplights[0]);
  World.CopyPlane(gpMapEffects, @mapeffects[0]);
  World.CopyPlane(gpMapSprites, @mapsprites[0]);
  World.CopyPlane(gpMapSlopes, @mapslopes[0]);
  World.CopyMapFlags(@mapflags[0]);
  fillchar(reallight, sizeof(reallight), 0);
  for i := 0 to High(Runner.Scenario.Lights) do
    reallight[Runner.Scenario.Lights[i].Spot] := Runner.Scenario.Lights[i].Value;
  for i := 0 to World.DoorCount - 1 do
  begin
    door := World.GetDoor(i);
    d := @doorlist[i];
    fillchar(d^, sizeof(d^), 0);
    d.tilex := door.TileX;
    d.tiley := door.TileY;
    d.orientation := orientation_t(Ord(door.Orientation));
    d.pic := door.Pic;
    d.position := door.Position;
    d.transparent := door.Transparent;
  end;
  numdoors := World.DoorCount;
  SetupOriginalSprites;
end;

procedure SetupOriginalSprites;
var i: integer; s: Pscaleobj_t; sprite: TGreedSprite;
begin
  firstscaleobj.next := @lastscaleobj; lastscaleobj.prev := @firstscaleobj; freescaleobj_p := @scaleobjlist[0];
  fillchar(scaleobjlist, sizeof(scaleobjlist), 0);
  for i := 0 to MAXSPRITES - 2 do scaleobjlist[i].next := @scaleobjlist[i + 1];
  for i := 0 to High(Runner.Scenario.Sprites) do
  begin
    sprite := Runner.Scenario.Sprites[i];
    s := RF_GetSprite;
    s.basepic := sprite.BasePic;
    s.rotate := rotate_t(Ord(sprite.Rotate));
    s.angle := sprite.Angle;
    s.animation := sprite.Animation;
    s.animationTime := sprite.AnimationTime;
    s.x := sprite.X; s.y := sprite.Y; s.z := sprite.Z;
    s.scale := sprite.Scale;
    s.specialtype := special_t(Ord(sprite.SpecialType));
    s.typ := sprite.Kind;
    s.oldx := sprite.OldX; s.oldy := sprite.OldY; s.oldz := sprite.OldZ;
    s.newx := sprite.NewX; s.newy := sprite.NewY; s.newz := sprite.NewZ;
    s.oldangle := sprite.OldAngle; s.newangle := sprite.NewAngle;
    s.oldfloorz := sprite.OldFloorZ; s.newfloorz := sprite.NewFloorZ;
    s.grounded := sprite.Grounded;
  end;
end;

function OriginalSpritesHash: Cardinal;
var
  s: Pscaleobj_t;
  t: TGreedSprite;
begin
  Result := 2166136261;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    t := Default(TGreedSprite);
    t.BasePic := s.basepic; t.Angle := s.angle; t.Animation := s.animation; t.AnimationTime := s.animationTime;
    t.X := s.x; t.Y := s.y; t.Z := s.z;
    Result := RenderSpriteHash(Result, t);
    s := s.next;
  end;
end;

// renders a view with the original renderer; returns the pixels
function RenderOriginal(const v: TRenderView; var w, h: Integer): PByteArray;
begin
  fillchar(player.northmap, sizeof(player.northmap), 0);
  fillchar(player.westmap, sizeof(player.westmap), 0);
  timecount := v.TimeCount;
  rtimecount := timecount;
  spritemovetime := v.SpriteMoveTime;
  scrollmin := v.ScrollMin;
  w := v.Width; h := v.Height;
  if v.Width = 320 then
  begin
    MAXSCROLL := MAXSCROLL1 div 2;
    SetViewSize(320, 200, @viewbuffer);
    memcpy(@pixelangle, @lowpixelangle, SizeOf(pixelangle));
    memcpy(@pixelcosine, @lowpixelcosine, SizeOf(pixelcosine));
    RF_RenderView(v.X, v.Y, v.Z, v.Angle);
    Result := @viewbuffer;
  end
  else
  begin
    MAXSCROLL := MAXSCROLL1;
    fillchar(renderbuffer, sizeof(renderbuffer), 0);
    SetViewSize(640, 400, @renderbuffer);
    memcpy(@pixelangle, @wallpixelangle, SizeOf(pixelangle));
    memcpy(@pixelcosine, @wallpixelcosine, SizeOf(pixelcosine));
    RF_RenderView(v.X, v.Y, v.Z, v.Angle);
    Result := @renderbuffer;
  end;
end;

procedure DumpDiff(orig: PByteArray; const nw: TBytes; w, h: Integer);
var i, x, y, minx, maxx, miny, maxy, n: Integer;
begin
  minx := w; maxx := -1; miny := h; maxy := -1; n := 0;
  for i := 0 to w * h - 1 do
    if orig[i] <> nw[i] then
    begin
      x := i mod w; y := i div w;
      if x < minx then minx := x; if x > maxx then maxx := x; if y < miny then miny := y; if y > maxy then maxy := y;
      if n < 6 then Writeln(Format('   (%d,%d) orig %d new %d', [x, y, orig[i], nw[i]]));
      Inc(n);
    end;
  Writeln(Format('   bbox x %d..%d y %d..%d', [minx, maxx, miny, maxy]));
end;

procedure ListDiff;
var so, sl: TStringList; k, a: Integer; key: string;
begin
  so := TStringList.Create; sl := TStringList.Create; so.Sorted := True; sl.Sorted := True; so.Duplicates := dupAccept; sl.Duplicates := dupAccept;
  for k := 0 to r_spans.numspans - 1 do if r_spans.spans[k].spantype = sp_slope then so.Add(Format('%5d %4d %4d %d', [r_spans.spans[k].y, r_spans.spansx[k], r_spans.spans[k].x2, r_spans.spantags[k].point * 0]));
  for k := 0 to Runner.Renderer.State.NumSpans - 1 do if Runner.Renderer.State.Spans[k].Kind = gskSlope then sl.Add(Format('%5d %4d %4d %d', [Runner.Renderer.State.Spans[k].Y, Runner.Renderer.State.SpansX[k], Runner.Renderer.State.Spans[k].X2, 0]));
  a := 0;
  for k := 0 to so.Count - 1 do if sl.IndexOf(so[k]) < 0 then begin if a < 5 then Writeln('   only original: ', so[k]); Inc(a); end;
  Writeln('   only in original: ', a); a := 0;
  for k := 0 to sl.Count - 1 do if so.IndexOf(sl[k]) < 0 then begin if a < 5 then Writeln('   only library: ', sl[k]); Inc(a); end;
  Writeln('   only in library: ', a);
  so.Free; sl.Free;
end;

procedure CompareSpans;
var co, cn: array[0..10] of Integer; k, n, shown: Integer; so: Pspan_t; sn: PGreedSpan; S: TGreedRenderState;
begin
  S := Runner.Renderer.State; shown := 0;
  Writeln(Format('   spans original %d library %d', [r_spans.numspans, S.NumSpans]));
  begin
    FillChar(co, SizeOf(co), 0); FillChar(cn, SizeOf(cn), 0);
    for k := 0 to r_spans.numspans - 1 do Inc(co[Ord(r_spans.spans[k].spantype)]);
    for k := 0 to S.NumSpans - 1 do Inc(cn[Ord(S.Spans[k].Kind)]);
    for k := 0 to 10 do if co[k] <> cn[k] then Writeln(Format('   kind %d: original %d library %d', [k, co[k], cn[k]]));
  end;
  n := r_spans.numspans; if S.NumSpans < n then n := S.NumSpans;
  for k := 0 to n - 1 do
  begin
    so := @r_spans.spans[r_spans.spantags[k].span]; sn := @S.Spans[S.SpanTags[k].Span];
    if (r_spans.spantags[k].point <> S.SpanTags[k].Point) or (Ord(so.spantype) <> Ord(sn.Kind)) or (so.x2 <> sn.X2) or (so.y <> sn.Y) or (r_spans.spansx[r_spans.spantags[k].span] <> S.SpansX[S.SpanTags[k].Span]) then
    begin
      if shown < 4 then Writeln(Format('   span #%d orig z %d t %d x %d x2 %d y %d | lib z %d t %d x %d x2 %d y %d', [k, r_spans.spantags[k].point, Ord(so.spantype), r_spans.spansx[r_spans.spantags[k].span], so.x2, so.y, S.SpanTags[k].Point, Ord(sn.Kind), S.SpansX[S.SpanTags[k].Span], sn.X2, sn.Y]));
      Inc(shown);
    end;
  end;
  Writeln('   span mismatches ', shown);
  ListDiff;
end;

procedure Diagnose(map: Integer);
var i: Integer; bad: set of byte; badf: set of byte; msg: string; n: Integer;
begin
  bad := []; badf := [];
  for i := 0 to 4095 do
  begin
    if northwall[i] <> 0 then if (northwall[i] >= numwalls) or (lumpcache[walllump + northwall[i]].data = nil) then Include(bad, northwall[i]);
    if westwall[i] <> 0 then if (westwall[i] >= numwalls) or (lumpcache[walllump + westwall[i]].data = nil) then Include(bad, westwall[i]);
    if (floordef[i] >= numwalls) or (lumpcache[walllump + floordef[i]].data = nil) then Include(bad, floordef[i]);
    if (ceilingdef[i] >= numwalls) or (lumpcache[walllump + ceilingdef[i]].data = nil) then Include(bad, ceilingdef[i]);
  end;
  msg := ''; for i := 0 to 255 do if i in bad then msg := msg + ' ' + IntToStr(i);
  if msg <> '' then Writeln('   map ', map, ' walls without data (numwalls ', numwalls, '):', msg);
end;

var KindFrames, KindFramesOk: array[0..10] of Integer;

procedure CountKinds(ok: Boolean);
var k: Integer; seen: array[0..10] of Boolean;
begin
  FillChar(seen, SizeOf(seen), 0);
  for k := 0 to r_spans.numspans - 1 do seen[Ord(r_spans.spans[k].spantype)] := True;
  for k := 0 to 10 do if seen[k] then begin Inc(KindFrames[k]); if ok then Inc(KindFramesOk[k]); end;
end;

procedure RunMap(map: Integer);
var
  vi, i, diff, w, h, firstdiff: Integer;
  orig: PByteArray;
  nw: TGreedFrame;
  crcO, crcN, nmO, wmO, rndO, shO: Cardinal;
  line: string;
  maps: Boolean;
  mapDiff, spriteMismatch, origFailed: Boolean;
begin
  Runner.LoadMap(map, Seed + Cardinal(map), ViewCount, SpriteCount);
  SetupOriginalMap(Runner.World);
  Diagnose(map);
  for vi := 0 to High(Runner.Scenario.Views) do
  begin
    origFailed := False;
    try orig := RenderOriginal(Runner.Scenario.Views[vi], w, h); except on E: Exception do begin Writeln('ORIGINAL failed map ', map, ' view ', vi, ': ', E.Message, ' RVA ', IntToHex(NativeUInt(ExceptAddr) - HInstance, 8)); origFailed := True; orig := nil; Writeln(Format('    mapspot %d tile (%d,%d) side %d walltype %d wallshadow %d wallflags %d src %p cmap %p count %d frac %d floordef %d ceildef %d', [r_render.mapspot, r_render.tilex, r_render.tiley, r_render.side, r_render.walltype, r_render.wallshadow, r_render.wallflags, r_spans.sp_source, r_spans.sp_colormap, r_spans.sp_count, r_spans.sp_frac, floordef[r_render.mapspot], ceilingdef[r_render.mapspot]])); end; end;
    try nw := Runner.RenderView(vi); except on E: Exception do begin Writeln('LIBRARY failed map ', map, ' view ', vi, ': ', E.Message); raise; end; end;
    if origFailed then begin Inc(Skipped); Golden.Add(Format('M %d V %d skipped %d', [map, vi, rndofs])); Runner.ResetSprites; SetupOriginalSprites; Runner.Random.Offset := Integer(rndofs); Continue; end;
    diff := 0; firstdiff := -1;
    for i := 0 to w * h - 1 do
      if orig[i] <> nw.Pixels[i] then
      begin
        if firstdiff < 0 then firstdiff := i;
        Inc(diff);
      end;
    crcO := RenderCrc32(orig^, w * h);
    crcN := RenderCrc32(nw.Pixels[0], w * h);
    nmO := RenderCrc32(player.northmap, SizeOf(player.northmap));
    wmO := RenderCrc32(player.westmap, SizeOf(player.westmap));
    mapDiff := (CompareMem(@player.northmap, @Runner.Player.NorthMap, 4096) = false) or
      (CompareMem(@player.westmap, @Runner.Player.WestMap, 4096) = false);
    rndO := rndofs;
    shO := OriginalSpritesHash;
    spriteMismatch := (shO <> RenderSpritesHash(Runner.Sprites)) or (Integer(rndO) <> Runner.Random.Offset);
    Inc(TotalFrames);
    CountKinds(diff = 0);
    if (diff > 0) or mapDiff or spriteMismatch then
    begin
      Inc(TotalDiff);
      if diff > 0 then DumpDiff(orig, nw.Pixels, w, h);
      if diff > 0 then CompareSpans;
      Writeln(Format('   numflats %d floorpic here %d (lump size %d) ceilpic %d', [numflats, floorpic[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)], infotable[flatlump + floorpic[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)]].size, ceilingpic[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)]]));
      Writeln(Format('   view tile (%d,%d) flags %d floor %d ceil %d', [Runner.Scenario.Views[vi].X shr 22, Runner.Scenario.Views[vi].Y shr 22, mapflags[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)], floorheight[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)], ceilingheight[(Runner.Scenario.Views[vi].Y shr 22) * 64 + (Runner.Scenario.Views[vi].X shr 22)]]));
      Writeln(Format('DIFF map %d view %d %dx%d scroll %d: pixels %d (first %d) maps %s sprites/rnd %s',
        [map, vi, w, h, Runner.Scenario.Views[vi].ScrollMin, diff, firstdiff, BoolToStr(mapDiff, True),
         BoolToStr(spriteMismatch, True)]));
    end;
    line := Format('M %d V %d %dx%d %s %s %s %d %s', [map, vi, w, h, IntToHex(crcO, 8), IntToHex(nmO, 8),
      IntToHex(wmO, 8), rndO, IntToHex(shO, 8)]);
    Golden.Add(line);
  end;
end;

procedure Timing;
var
  freq, t0, t1: Int64;
  i, n: Integer;
  w, h: Integer;
  v: TRenderView;
  nw: TGreedFrame;
  tOrig, tNew: Double;
  sz: Integer;
begin
  QueryPerformanceFrequency(freq);
  Runner.LoadMap(Maps[0], Seed, 6, SpriteCount);
  SetupOriginalMap(Runner.World);
  for sz := 0 to 1 do
  begin
    v := Runner.Scenario.Views[2 + sz * 0];
    if sz = 0 then begin v.Width := 320; v.Height := 200; v.ScrollMin := 0; end
    else begin v.Width := 640; v.Height := 400; v.ScrollMin := 0; end;
    n := 60;
    QueryPerformanceCounter(t0);
    for i := 1 to n do RenderOriginal(v, w, h);
    QueryPerformanceCounter(t1);
    tOrig := (t1 - t0) * 1000 / freq / n;
    QueryPerformanceCounter(t0);
    for i := 1 to n do
    begin
      Runner.Scenario.Views[0] := v;
      nw := Runner.RenderView(0);
    end;
    QueryPerformanceCounter(t1);
    tNew := (t1 - t0) * 1000 / freq / n;
    Writeln(Format('TIMING %dx%d: original %.3f ms/frame, library %.3f ms/frame', [v.Width, v.Height, tOrig, tNew]));
  end;
end;

var
  s: string;
  parts: TStringList;
  i: integer;
begin
  try
    Folder := ParamStr(1);
    GoldenPath := ParamStr(2);
    parts := TStringList.Create;
    parts.CommaText := ParamStr(3);
    if parts.Count = 0 then parts.CommaText := '0,1,2,3';
    for i := 0 to parts.Count - 1 do
    begin
      SetLength(Maps, Length(Maps) + 1);
      Maps[High(Maps)] := StrToInt(parts[i]);
    end;
    if ParamStr(4) <> '' then Seed := StrToInt(ParamStr(4));
    if ParamStr(5) <> '' then ViewCount := StrToInt(ParamStr(5));
    if ParamStr(6) <> '' then SpriteCount := StrToInt(ParamStr(6));
    TRenderScenarios.NoDoors := ParamStr(7) = 'nodoors';
    Golden := TStringList.Create;
    Archive := TGreedFactory.OpenArchiveFile(Folder + '\GREED.BLO');
    Runner := TRenderRunner.Create(Archive, TGreedFactory.CreateFolderFiles([Folder]));
    InitOriginal;
    for i := 0 to High(Maps) do
      RunMap(Maps[i]);
    Writeln(Format('FRAMES %d, DIFFERENT %d, SKIPPED (original crashes) %d', [TotalFrames, TotalDiff, Skipped]));
    Writeln('KINDS (frames containing each kind of span; identical): flat ', KindFramesOk[0], '/', KindFrames[0], ' slope ', KindFramesOk[1], '/', KindFrames[1], ' door ', KindFramesOk[2], '/', KindFrames[2], ' shape ', KindFramesOk[3], '/', KindFrames[3], ' maskeddoor ', KindFramesOk[4], '/', KindFrames[4], ' transwall ', KindFramesOk[5], '/', KindFrames[5], ' step ', KindFramesOk[6], '/', KindFrames[6], ' sky ', KindFramesOk[7], '/', KindFrames[7], ' slopesky ', KindFramesOk[8], '/', KindFrames[8], ' flatsky ', KindFramesOk[9], '/', KindFrames[9], ' inviswall ', KindFramesOk[10], '/', KindFrames[10]);
    if GoldenPath <> '' then Golden.SaveToFile(GoldenPath);
    Timing;
  except
    on E: Exception do
    begin
      Writeln('ERROR ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.



