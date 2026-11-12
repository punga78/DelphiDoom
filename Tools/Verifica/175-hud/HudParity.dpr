program HudParity;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: confronta sui pixel l'HUD ORIGINALE di xGreed (display.pas, d_font.pas, d_video.pas
// e i ritagli di raven.pas, utils.pas e i_video.pas fatti da Compila.ps1) con le classi di Libs\Greed sugli stessi
// scenari (Tests\Source\DelphiDoom.Tests.Greed.HudScenarios). Le righe del golden sono i valori dell'ORIGINALE.
// Uso: HudParity <cartella con GREED.BLO | sintetico> <golden.txt | nessuno>
uses
  SysUtils, Classes,
  g_delphi, d_disk, d_ints, protos_h, constant, r_public_h, r_refdef, r_render, r_conten, r_public, i_video, d_video, d_font,
  display, raven, utils, net, harness_hud,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Factory,
  DelphiDoom.Greed.Canvas, DelphiDoom.Tests.Greed.HudScenarios;

var
  Archive: IGreedArchive;
  Data: THudData;
  Runner: THudLibraryRunner;
  Golden: TStringList;
  ColorMapCopy: TBytes;
  PaletteHash: Cardinal;
  TotalCases, TotalDifferent, TotalPixels: Integer;
  Com: greedcom_t;
  Progress: string;

procedure OnPalette;
var
  pal: packed array[0..767] of byte;
begin
  I_GetPalette(@pal);
  PaletteHash := HudFnv(PaletteHash, pal, 768);
end;

procedure InitOriginal;
var
  i: integer;
begin
  CA_InitFromArchive(Archive);
  // the trig tables (sintable, costable, sines, cosines) are made by RF_Startup
  windowWidth := MAX_VIEW_WIDTH;
  windowHeight := MAX_VIEW_HEIGHT;
  RF_Startup;
  VI_Init;
  // what UpdateView leaves after the level is rendered
  SetViewSize(MAX_VIEW_WIDTH, MAX_VIEW_HEIGHT, @viewbuffer);
  font1 := CA_CacheLump(CA_GetNamedNum('FONT1'));
  font2 := CA_CacheLump(CA_GetNamedNum('FONT2'));
  font3 := CA_CacheLump(CA_GetNamedNum('FONT3'));
  // LoadMiscData
  statusbar[0] := CA_CacheLump(CA_GetNamedNum('STATBAR1'));
  statusbar[1] := CA_CacheLump(CA_GetNamedNum('STATBAR2'));
  statusbar[2] := CA_CacheLump(CA_GetNamedNum('STATBAR3'));
  statusbar[3] := CA_CacheLump(CA_GetNamedNum('STATBAR4'));
  for i := 0 to 9 do
    heart[i] := CA_CacheLump(CA_GetNamedNum('HEART') + i);
  // display.pas reads the pictures of items and goals straight from the cache: the game loaded them with the sprites
  for i := 0 to MAXINVENTORY - 1 do
    CA_CacheLump(Data.InventoryLump + i);
  for i := 0 to High(primnames) do
    CA_CacheLump(Data.PrimaryLump + i);
  for i := 0 to High(secnames) do
    CA_CacheLump(Data.SecondaryLump + i);
  ColorMapCopy := Copy(Data.ColorMaps);
  colormaps := @ColorMapCopy[0];
  numcolormaps := HUD_COLORMAPS;
  RF_SetLights(MAXZ);
  netmode := false;
  playernum := 1;
  Com.numplayers := 1;
  greedcom := @Com;
end;

// the lumps leave the cache and the pointers of LoadMiscData are taken again
procedure FlushOriginal;
var
  i: integer;
begin
  for i := 0 to High(Data.Pictures) do
    CA_FreeLump(Data.Pictures[i]);
  statusbar[0] := CA_CacheLump(CA_GetNamedNum('STATBAR1'));
  statusbar[1] := CA_CacheLump(CA_GetNamedNum('STATBAR2'));
  statusbar[2] := CA_CacheLump(CA_GetNamedNum('STATBAR3'));
  statusbar[3] := CA_CacheLump(CA_GetNamedNum('STATBAR4'));
  for i := 0 to 9 do
    heart[i] := CA_CacheLump(CA_GetNamedNum('HEART') + i);
end;

function Compare(const what: string): Integer;
var
  i, shown: Integer;
begin
  Result := 0;
  shown := 0;
  for i := 0 to 63999 do
    if viewbuffer[i] <> Runner.Canvas.Pixels[i] then
    begin
      if (Result = 0) or (shown < 4) then
      begin
        Writeln(Format('  %s: (%d,%d) original %d library %d', [what, i mod 320, i div 320, viewbuffer[i],
          Runner.Canvas.Pixels[i]]));
        Inc(shown);
      end;
      Inc(Result);
    end;
  Inc(TotalCases);
  if Result > 0 then
  begin
    Inc(TotalDifferent);
    Inc(TotalPixels, Result);
    Writeln(Format('DIFF %s: %d pixels', [what, Result]));
  end;
end;

function OriginalPixelHash: Cardinal;
begin
  Result := HudFnv(HUD_FNV_START, viewbuffer, 64000);
end;

procedure RunPalettes;
var
  k: Integer;
  c: THudPaletteCase;
  approx: Byte;
  hash: Cardinal;
  shown, target: packed array[0..767] of byte;
begin
  for k := 0 to HUD_PALETTE_CASES - 1 do
  begin
    c := THudScenarios.PaletteCase(k);
    Move(c.Shown[0], shown, 768);
    Move(c.Target[0], target, 768);
    PaletteHook := nil;
    I_SetPalette(@shown);
    PaletteHash := HUD_FNV_START;
    PaletteHook := OnPalette;
    VI_FadeOut(c.Start, c.Stop, c.Red, c.Green, c.Blue, c.Steps);
    PaletteHook := nil;
    I_SetPalette(@shown);
    PaletteHook := OnPalette;
    VI_FadeIn(c.Start, c.Stop, @target, c.Steps);
    PaletteHook := nil;
    I_SetPalette(@shown);
    Runner.RunPalette(c, approx, hash);
    Inc(TotalCases);
    if (approx <> approx_zero) or (hash <> PaletteHash) then
    begin
      Inc(TotalDifferent);
      Writeln(Format('DIFF palette %d: approx zero original %d library %d, steps %s %s', [k, approx_zero, approx,
        IntToHex(PaletteHash, 8), IntToHex(hash, 8)]));
    end;
    Golden.Add(Format('P %d %d %s', [k, approx_zero, IntToHex(PaletteHash, 8)]));
  end;
end;

procedure RunCanvases;
var
  k, i: Integer;
  c: THudCanvasCase;
  b: TBytes;
  pic: Ppic_t;
begin
  for k := 0 to HUD_CANVAS_CASES - 1 do
  begin
    c := THudScenarios.CanvasCase(Data, k);
    approx_zero := c.ApproxZero;
    b := THudScenarios.Background(c.BackgroundSeed, 64000);
    Move(b[0], viewbuffer, 64000);
    for i := 0 to High(c.Operations) do
    begin
      pic := CA_CacheLump(c.Operations[i].Lump);
      case c.Operations[i].Kind of
        hcoSolid: VI_DrawPicSolid(c.Operations[i].X, c.Operations[i].Y, pic);
        hcoSolidUntranslated: VI_DrawPicSolidUntranslated(c.Operations[i].X, c.Operations[i].Y, pic);
        hcoMasked: VI_DrawMaskedPic(c.Operations[i].X, c.Operations[i].Y, pic);
        hcoMaskedToBuffer: VI_DrawMaskedPicToBuffer(c.Operations[i].X, c.Operations[i].Y, pic);
        hcoTrans: VI_DrawTransPicToBuffer(c.Operations[i].X, c.Operations[i].Y, pic);
        hcoLit:
          begin
            // the glowing table of the frame is the one of the case
            player.mapspot := 0;
            mapeffects[0] := 1;
            wallglow := c.Operations[i].Colormap;
            VI_DrawMaskedPicToBuffer2(c.Operations[i].X, c.Operations[i].Y, pic);
          end;
      end;
    end;
    Runner.RunCanvas(c);
    if Compare(Format('canvas %d', [k])) > 0 then
      for i := 0 to High(c.Operations) do
      begin
        pic := CA_CacheLump(c.Operations[i].Lump);
        Writeln(Format('    kind %d lump %d at %d,%d size %dx%d origin %d,%d', [Ord(c.Operations[i].Kind), c.Operations[i].Lump, c.Operations[i].X, c.Operations[i].Y, pic.width, pic.height, pic.orgx, pic.orgy]));
      end;
    Golden.Add(Format('C %d %s', [k, IntToHex(OriginalPixelHash, 8)]));
  end;
end;

procedure RunTexts;
var
  k: Integer;
  c: THudTextCase;
  t: THudTrace;
begin
  for k := 0 to HUD_TEXT_CASES - 1 do
  begin
    c := THudScenarios.TextCase(Data, k);
    Progress := Format('text %d', [k]);
    approx_zero := c.ApproxZero;
    FillChar(viewbuffer, 64000, 0);
    case c.FontNumber of
      1: font := font1;
      2: font := font2;
    else
      font := font3;
    end;
    fontbasecolor := c.BaseColor;
    fontspacing := c.Spacing;
    printx := c.X;
    printy := c.Y;
    case c.Kind of
      htkRaw1: FN_RawPrint(c.Text);
      htkRaw2: FN_RawPrint2(c.Text);
      htkRaw3: FN_RawPrint3(c.Text);
      htkRaw4: FN_RawPrint4(c.Text);
      htkPrint: FN_Printf('%s', [c.Text]);
      htkCentered: FN_CenterPrintf('%s', [c.Text]);
      htkBlock: FN_BlockCenterPrintf('%s', [c.Text]);
    end;
    t.Clear;
    t.Add(printx);
    t.Add(printy);
    t.Add(FN_RawWidth(c.Text));
    Runner.RunText(c);
    if (Compare(Format('text %d', [k])) = 0) and (t.Hash <> Runner.Trace.Hash) then
    begin
      Inc(TotalDifferent);
      Writeln(Format('DIFF text %d: print position or width (original %d,%d library %d,%d)', [k, printx, printy,
        Runner.Printer.PrintX, Runner.Printer.PrintY]));
    end;
    Golden.Add(Format('T %d %s %s', [k, IntToHex(OriginalPixelHash, 8), IntToHex(t.Hash, 8)]));
  end;
  fontspacing := 1;
end;

procedure ApplyOriginal(const s: THudStep);
var
  i: Integer;
  inv: array[0..MAXINVENTORY - 1] of integer;
  holopic, holoscale: integer;
  sp: Pscaleobj_t;
begin
  Move(player.inventory, inv, SizeOf(inv));
  holopic := player.holopic;
  holoscale := player.holoscale;
  if SizeOf(player) <> SizeOf(TGreedPlayerRecord) then
    raise Exception.Create('player_t');
  Move(s.Player, player, SizeOf(player));
  if not s.First then
  begin
    Move(inv, player.inventory, SizeOf(inv));
    player.holopic := holopic;
    player.holoscale := holoscale;
  end
  else
  begin
    specialeffect := s.SpecialEffect;
    specialeffecttime := s.SpecialEffectTime;
    warpjammer := false;
    approx_zero := 1 + s.TimeCount mod 255;
  end;
  timecount := s.TimeCount;
  inventorytime := s.InventoryTime;
  goalitem := s.GoalItem;
  togglegoalitem := false;
  mapmode := s.MapMode;
  MapZoom := s.MapZoom;
  weapmode := s.WeapMode;
  heatmode := s.HeatMode;
  motionmode := s.MotionMode;
  exitexists := s.ExitExists;
  exitx := s.ExitX;
  exity := s.ExitY;
  for i := 0 to 3 do primaries[i] := s.Primaries[i];
  for i := 0 to 13 do secondaries[i] := s.Secondaries[i];
  for i := 0 to 1 do pcount[i] := s.PCount[i];
  for i := 0 to 6 do scount[i] := s.SCount[i];
  // the sprites of the step and, last, the one of the bonus item
  firstscaleobj.next := @lastscaleobj;
  lastscaleobj.prev := @firstscaleobj;
  freescaleobj_p := @scaleobjlist[0];
  FillChar(scaleobjlist, SizeOf(scaleobjlist), 0);
  for i := 0 to MAXSPRITES - 2 do
    scaleobjlist[i].next := @scaleobjlist[i + 1];
  for i := 0 to High(s.Sprites) do
  begin
    sp := RF_GetSprite;
    sp.x := s.Sprites[i].X;
    sp.y := s.Sprites[i].Y;
    sp.active := s.Sprites[i].Active;
    sp.hitpoints := s.Sprites[i].HitPoints;
    sp.basepic := s.Sprites[i].BasePic;
    sp.scale := s.Sprites[i].Scale;
  end;
  sp := RF_GetSprite;
  sp.x := s.BonusTileX * FRACTILEUNIT;
  sp.y := s.BonusTileY * FRACTILEUNIT;
  sp.basepic := s.BonusPic;
  BonusItem.sprite := sp;
  BonusItem.score := s.BonusScore;
  BonusItem.time := s.BonusTime;
  BonusItem.tilex := s.BonusTileX;
  BonusItem.tiley := s.BonusTileY;
  BonusItem.name := s.BonusName;
  FillChar(reallight, SizeOf(reallight), 0);
  for i := 0 to High(s.Lights) do
    reallight[s.Lights[i].Spot] := s.Lights[i].Value;
  mapeffects[s.Player.MapSpot] := s.MapEffect;
  maplights[s.Player.MapSpot] := s.MapLight;
  wallglow := s.WallGlow;
  wallflicker1 := s.WallFlicker1;
  wallflicker2 := s.WallFlicker2;
  wallflicker3 := s.WallFlicker3;
  wallflicker4 := s.WallFlicker4;
  wallcycle := s.WallCycle;
  currentViewSize := s.ViewSize;
end;

procedure FrameOriginal(const s: THudStep);
var
  i: Integer;
  b: TBytes;
begin
  HarnessTrace.Clear;
  ApplyOriginal(s);
  Progress := 'reset';
  if s.ResetDisplay then
    resetdisplay;
  Progress := 'ops';
  for i := 0 to High(s.Operations) do
    case s.Operations[i] of
      hioLeft: inventoryleft;
      hioRight: inventoryright;
      hioUse: useinventory;
      hioRefresh:
        begin
          oldinventory := -2;
          inventoryleft;
          inventoryright;
        end;
    end;
  Progress := 'grenade';
  H_Grenade;
  Progress := 'msg';
  for i := 0 to High(s.Messages) do
    writemsg(s.Messages[i]);
  Progress := 'loadweapon';
  if s.LoadWeapon >= 0 then
    loadweapon(s.LoadWeapon);
  Progress := 'draw';
  if s.Delta then
  begin
    if s.First then
    begin
      FillChar(viewbuffer, 64000, 0);
      VI_DrawPicSolidUntranslated(4, 149, CA_CacheLump(Data.Pictures[2]));
      VI_DrawPicSolidUntranslated(0, 0, CA_CacheLump(Data.Pictures[3]));
    end;
  end
  else
    FillChar(viewbuffer, 64000, 0);
  if s.DrawHolo and (player.holopic <> 0) then
    DrawHolo;
  RearViewTime := 0;
  if s.DrawRear then
  begin
    b := THudScenarios.RearPicture(s.RearSeed);
    Move(b[0], rearbuf, SizeOf(rearbuf));
    I_TranslateBuffer(@rearbuf, SizeOf(rearbuf));
    RearViewTime := timecount + 1;
  end;
  Progress := 'rear';
  H_RearBox;
  Progress := 'weapon';
  // the last lines of the weapon part of UpdateView
  if s.DrawWeapon and (player.angst <> 0) and (weaponpic[weapmode] <> nil) then
  begin
    if weapmode = 0 then
      VI_DrawMaskedPicToBuffer2(s.WeaponX, s.WeaponY, weaponpic[weapmode])
    else
      VI_DrawMaskedPicToBuffer(s.WeaponX, s.WeaponY, weaponpic[weapmode]);
  end;
  Progress := 'displays';
  H_Displays;
  Progress := 'trace';
  HarnessTrace.Add(oldshots);
  HarnessTrace.Add(oldgoalitem);
  HarnessTrace.Add(oldangle);
  HarnessTrace.Add(oldangst);
  HarnessTrace.Add(oldangstpic);
  HarnessTrace.Add(oldshield);
  HarnessTrace.Add(oldbodycount);
  HarnessTrace.Add(oldscore);
  HarnessTrace.Add(oldlevelscore);
  HarnessTrace.Add(statcursor);
  HarnessTrace.Add(inventorycursor);
  HarnessTrace.Add(oldinventory);
  HarnessTrace.Add(totaleffecttime);
  HarnessTrace.Add(Ord(firegrenade));
  HarnessTrace.Add(Ord(togglegoalitem));
  HarnessTrace.Add(printx);
  HarnessTrace.Add(printy);
  for i := 0 to MAXINVENTORY - 1 do
    HarnessTrace.Add(player.inventory[i]);
  HarnessTrace.Add(player.holopic);
  HarnessTrace.Add(player.holoscale);
  HarnessTrace.Add(specialeffect);
  HarnessTrace.Add(specialeffecttime);
  HarnessTrace.Add(Ord(warpjammer));
  for i := 0 to 18 do
  begin
    HarnessTrace.Add(weapons[i].charge);
    HarnessTrace.Add(weapons[i].chargetime);
  end;
  for i := 0 to 6 do
    if weaponpic[i] = nil then
    begin
      HarnessTrace.Add(0);
      HarnessTrace.Add(0);
    end
    else
    begin
      HarnessTrace.Add(weaponpic[i].width);
      HarnessTrace.Add(weaponpic[i].height);
    end;
end;

procedure RunFrames;
var
  k, f: Integer;
  frames: TArray<THudStep>;
begin
  FlushOriginal;
  Runner.FlushPictures;
  for k := 0 to HUD_SCENARIOS - 1 do
  begin
    frames := THudScenarios.Frames(Data, k);
    for f := 0 to High(frames) do
    begin
      Progress := Format('scenario %d frame %d original', [k, f]);
      FrameOriginal(frames[f]);
      Progress := Format('scenario %d frame %d library', [k, f]);
      Runner.RunFrame(frames[f]);
      if not CompareMem(@viewbuffer, @Runner.Canvas.Pixels[0], 64000) then
        Writeln(Format('  weapon %d: original rate %d type %d, library rate %d type %d; ammo %d %d %d', [player.weapons[player.currentweapon], weapons[player.weapons[player.currentweapon]].ammorate, weapons[player.weapons[player.currentweapon]].ammotype, Runner.State.Weapons[player.weapons[player.currentweapon]].AmmoRate, Runner.State.Weapons[player.weapons[player.currentweapon]].AmmoType, player.ammo[0], player.ammo[1], player.ammo[2]]));
      if (Compare(Format('scenario %d frame %d (view size %d)', [k, f, frames[f].ViewSize])) = 0) and
        (HarnessTrace.Hash <> Runner.Trace.Hash) then
      begin
        Inc(TotalDifferent);
        Writeln(Format('DIFF scenario %d frame %d: the state (cursor %d/%d oldinventory %d/%d oldshots %d/%d ' +
          'oldgoalitem %d/%d printx %d/%d printy %d/%d toggle %d/%d)', [k, f, inventorycursor,
          Runner.Inventory.Cursor, oldinventory, Runner.Inventory.OldInventory, oldshots, Runner.Hud.OldShots,
          oldgoalitem, Runner.Hud.OldGoalItem, printx, Runner.Printer.PrintX, printy, Runner.Printer.PrintY,
          Ord(togglegoalitem), Ord(Runner.State.ToggleGoalItem)]));
      end;
      Golden.Add(Format('H %d %d %s %s', [k, f, IntToHex(OriginalPixelHash, 8), IntToHex(HarnessTrace.Hash, 8)]));
    end;
  end;
end;

begin
  try
    if SameText(ParamStr(1), 'sintetico') or (ParamStr(1) = '') then
      Archive := THudScenarios.SyntheticArchive
    else
      Archive := TGreedFactory.OpenArchiveFile(ParamStr(1) + '\GREED.BLO');
    Data := THudScenarios.Describe(Archive);
    Runner := THudLibraryRunner.Create(Data);
    Golden := TStringList.Create;
    InitOriginal;
    RunPalettes;
    RunCanvases;
    RunTexts;
    RunFrames;
    Writeln(Format('CASES %d (palettes %d, canvas %d, texts %d, frames %d = %d scenarios x %d), DIFFERENT %d, ' +
      'PIXELS DIFFERENT %d', [TotalCases, HUD_PALETTE_CASES, HUD_CANVAS_CASES, HUD_TEXT_CASES,
      HUD_SCENARIOS * HUD_FRAMES, HUD_SCENARIOS, HUD_FRAMES, TotalDifferent, TotalPixels]));
    if (ParamStr(2) <> '') and not SameText(ParamStr(2), 'nessuno') then
      Golden.SaveToFile(ParamStr(2));
    if TotalDifferent > 0 then
      ExitCode := 2;
  except
    on E: Exception do
    begin
      Writeln('ERROR ', E.ClassName, ': ', E.Message, ' (', Progress, ')');
      ExitCode := 1;
    end;
  end;
end.
