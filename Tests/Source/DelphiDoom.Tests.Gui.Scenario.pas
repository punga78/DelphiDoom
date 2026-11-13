{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the scenarios of the C driver        }
{                                                                              }
{  Runs the scenario files of Tests\Data\Gui\scenarios as Tools\Verifica\125   }
{  (uiparse.c) runs them on the real Quake III code, and writes the same dump  }
{  lines: hexadecimal float bits, strings with escapes, one text per line.     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Scenario;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu,
  DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.Font;

type
  /// <summary>The dump functions of uiparse.c over the model of the library</summary>
  TGuiDump = class
  strict private
    FText: string;
    procedure PF(const AName: string; const AValue: Single);
    procedure PI(const AName: string; const AValue: Integer);
    procedure PS(const AName: string; const AValue: AnsiString);
    procedure PR(const AName: string; const ARect: TGuiRect);
    procedure PC(const AName: string; const AColor: TGuiColor);
    procedure Raw(const AText: string);
    class function Bits(const AValue: Single): string; static;
    procedure DumpWindow(const AWindow: TGuiWindowDef);
    procedure DumpItem(const AIndex: Integer; const AItem: TGuiItem);
    procedure DumpMenu(const AIndex: Integer; const AMenu: TGuiMenu);
  public
    procedure Menus(const AMenus: TGuiMenuSet);
    procedure WindowState(const AWindow: TGuiWindowDef);
    /// <summary>The line "dummy" and the state of an item that is not in a menu</summary>
    procedure DummyState(const AWindow: TGuiWindowDef);
    procedure State(const AMenus: TGuiMenuSet);
    procedure Font(const ALabel: string; const AFont: TGuiFont);
    /// <summary>Lines that were written, and then forgotten</summary>
    procedure Flush(const ALines: TStrings);
  end;

  /// <summary>Runs a scenario file and collects the transcript</summary>
  TGuiScenarioRunner = class
  public
    /// <summary>The root folder holds ui/ and fonts/; the transcript is the text the C driver prints</summary>
    class function Run(const ARoot, AScenarioFile: string; const ATranscript: TStrings): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Gui.Intf, DelphiDoom.Gui.Factory, DelphiDoom.Gui.FontRegistry, DelphiDoom.Gui.MenuFileReader,
  DelphiDoom.Gui.ScriptRunner, DelphiDoom.Gui.Font.Types, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Tests.Gui.Fakes;

const
  // the glyphs that uiparse.c prints in full
  SHOWN_GLYPHS: array[0..5] of Integer = (0, 32, 65, 200, 254, 255);

{ TGuiDump }

class function TGuiDump.Bits(const AValue: Single): string;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result := LowerCase(IntToHex(LBits, 8));
end;

procedure TGuiDump.Raw(const AText: string);
begin
  FText := FText + AText;
end;

procedure TGuiDump.PF(const AName: string; const AValue: Single);
begin
  Raw(' ' + AName + '=' + Bits(AValue));
end;

procedure TGuiDump.PI(const AName: string; const AValue: Integer);
begin
  Raw(' ' + AName + '=' + IntToStr(AValue));
end;

procedure TGuiDump.PS(const AName: string; const AValue: AnsiString);
var
  LIndex: Integer;
  LCode: Byte;
begin
  Raw(' ' + AName + '="');
  for LIndex := 1 to Length(AValue) do
  begin
    LCode := Byte(AValue[LIndex]);
    if (LCode = Ord('\')) or (LCode = Ord('"')) then
      Raw('\' + Chr(LCode))
    else if (LCode < 32) or (LCode > 126) then
      Raw('\x' + LowerCase(IntToHex(LCode, 2)))
    else
      Raw(Chr(LCode));
  end;
  Raw('"');
end;

procedure TGuiDump.PR(const AName: string; const ARect: TGuiRect);
begin
  Raw(' ' + AName + '=' + Bits(ARect.X) + ',' + Bits(ARect.Y) + ',' + Bits(ARect.W) + ',' + Bits(ARect.H));
end;

procedure TGuiDump.PC(const AName: string; const AColor: TGuiColor);
begin
  Raw(' ' + AName + '=' + Bits(AColor[0]) + ',' + Bits(AColor[1]) + ',' + Bits(AColor[2]) + ',' + Bits(AColor[3]));
end;

procedure TGuiDump.Flush(const ALines: TStrings);
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := FText;
    ALines.AddStrings(LLines);
  finally
    LLines.Free;
  end;
  FText := '';
end;

procedure TGuiDump.WindowState(const AWindow: TGuiWindowDef);
begin
  PR('rect', AWindow.Rect);
  PR('rectClient', AWindow.RectClient);
  PI('flags', AWindow.Flags);
  PR('rectEffects', AWindow.RectEffects);
  PR('rectEffects2', AWindow.RectEffects2);
  PI('offsetTime', AWindow.OffsetTime);
  PC('foreColor', AWindow.ForeColor);
  PC('backColor', AWindow.BackColor);
  PC('borderColor', AWindow.BorderColor);
  PI('background', AWindow.Background);
  PI('cinematic', AWindow.Cinematic);
  Raw(#10);
end;

procedure TGuiDump.DummyState(const AWindow: TGuiWindowDef);
begin
  Raw('dummy');
  WindowState(AWindow);
end;

procedure TGuiDump.DumpWindow(const AWindow: TGuiWindowDef);
begin
  PS('name', AWindow.Name);
  PS('group', AWindow.Group);
  PS('cinematicName', AWindow.CinematicName);
  PI('cinematic', AWindow.Cinematic);
  PI('style', AWindow.Style);
  PI('border', AWindow.Border);
  PI('ownerDraw', AWindow.OwnerDraw);
  PI('ownerDrawFlags', AWindow.OwnerDrawFlags);
  PF('borderSize', AWindow.BorderSize);
  PI('flags', AWindow.Flags);
  Raw(#10 + '    ');
  PR('rect', AWindow.Rect);
  PR('rectClient', AWindow.RectClient);
  PR('rectEffects', AWindow.RectEffects);
  PR('rectEffects2', AWindow.RectEffects2);
  PI('offsetTime', AWindow.OffsetTime);
  PI('nextTime', AWindow.NextTime);
  Raw(#10 + '    ');
  PC('foreColor', AWindow.ForeColor);
  PC('backColor', AWindow.BackColor);
  PC('borderColor', AWindow.BorderColor);
  PC('outlineColor', AWindow.OutlineColor);
  PI('background', AWindow.Background);
  Raw(#10);
end;

procedure TGuiDump.DumpItem(const AIndex: Integer; const AItem: TGuiItem);
var
  LIndex: Integer;
begin
  Raw('  item ' + IntToStr(AIndex) + #10 + '   window');
  DumpWindow(AItem.Window);
  Raw('   ');
  PR('textRect', AItem.TextRect);
  PI('type', AItem.ItemType);
  PI('alignment', AItem.Alignment);
  PI('textalignment', AItem.TextAlignment);
  PF('textalignx', AItem.TextAlignX);
  PF('textaligny', AItem.TextAlignY);
  PF('textscale', AItem.TextScale);
  PI('textStyle', AItem.TextStyle);
  PI('asset', AItem.Asset);
  PI('focusSound', AItem.FocusSound);
  PF('special', AItem.Special);
  PI('cursorPos', AItem.CursorPos);
  PI('cvarFlags', AItem.CvarFlags);
  Raw(#10 + '   ');
  PS('text', AItem.Text);
  PS('cvar', AItem.Cvar);
  PS('cvarTest', AItem.CvarTest);
  PS('enableCvar', AItem.EnableCvar);
  Raw(#10 + '   ');
  PS('mouseEnterText', AItem.MouseEnterText);
  PS('mouseExitText', AItem.MouseExitText);
  PS('mouseEnter', AItem.MouseEnter);
  PS('mouseExit', AItem.MouseExit);
  PS('action', AItem.Action);
  PS('onFocus', AItem.OnFocus);
  PS('leaveFocus', AItem.LeaveFocus);
  Raw(#10);
  PI('   numColors', AItem.NumColors);
  Raw(#10);
  for LIndex := 0 to AItem.NumColors - 1 do
  begin
    Raw('   colorRange ' + IntToStr(LIndex));
    PF('low', AItem.ColorRanges[LIndex].Low);
    PF('high', AItem.ColorRanges[LIndex].High);
    PC('color', AItem.ColorRanges[LIndex].Color);
    Raw(#10);
  end;
  case AItem.DataKind of
    gdkListBox:
      begin
        Raw('   listbox');
        PI('startPos', AItem.ListBox.StartPos);
        PI('endPos', AItem.ListBox.EndPos);
        PI('drawPadding', AItem.ListBox.DrawPadding);
        PI('cursorPos', AItem.ListBox.CursorPos);
        PF('elementWidth', AItem.ListBox.ElementWidth);
        PF('elementHeight', AItem.ListBox.ElementHeight);
        PI('elementStyle', AItem.ListBox.ElementStyle);
        PI('numColumns', AItem.ListBox.NumColumns);
        PS('doubleClick', AItem.ListBox.DoubleClick);
        PI('notselectable', Ord(AItem.ListBox.NotSelectable));
        Raw(#10);
        for LIndex := 0 to GUI_MAX_LB_COLUMNS - 1 do
          if (AItem.ListBox.ColumnInfo[LIndex].Pos <> 0) or (AItem.ListBox.ColumnInfo[LIndex].Width <> 0) or
            (AItem.ListBox.ColumnInfo[LIndex].MaxChars <> 0) then
          begin
            Raw('   column ' + IntToStr(LIndex));
            PI('pos', AItem.ListBox.ColumnInfo[LIndex].Pos);
            PI('width', AItem.ListBox.ColumnInfo[LIndex].Width);
            PI('maxChars', AItem.ListBox.ColumnInfo[LIndex].MaxChars);
            Raw(#10);
          end;
      end;
    gdkEditField:
      begin
        Raw('   editfield');
        PF('minVal', AItem.EditField.MinVal);
        PF('maxVal', AItem.EditField.MaxVal);
        PF('defVal', AItem.EditField.DefVal);
        PF('range', AItem.EditField.Range);
        PI('maxChars', AItem.EditField.MaxChars);
        PI('maxPaintChars', AItem.EditField.MaxPaintChars);
        PI('paintOffset', AItem.EditField.PaintOffset);
        Raw(#10);
      end;
    gdkMulti:
      begin
        Raw('   multi');
        PI('count', AItem.Multi.Count);
        PI('strDef', Ord(AItem.Multi.StrDef));
        Raw(#10);
        for LIndex := 0 to AItem.Multi.Count - 1 do
        begin
          Raw('   entry ' + IntToStr(LIndex));
          PS('cvar', AItem.Multi.CvarList[LIndex]);
          PS('str', AItem.Multi.CvarStr[LIndex]);
          PF('value', AItem.Multi.CvarValue[LIndex]);
          Raw(#10);
        end;
      end;
    gdkModel:
      begin
        Raw('   model');
        PF('o0', AItem.Model.Origin[0]);
        PF('o1', AItem.Model.Origin[1]);
        PF('o2', AItem.Model.Origin[2]);
        PF('fov_x', AItem.Model.FovX);
        PF('fov_y', AItem.Model.FovY);
        PI('rotationSpeed', AItem.Model.RotationSpeed);
        // the angle is rand() % 360 in the C driver: not compared
        Raw(#10);
      end;
  end;
end;

procedure TGuiDump.DumpMenu(const AIndex: Integer; const AMenu: TGuiMenu);
var
  LIndex: Integer;
begin
  Raw('menu ' + IntToStr(AIndex) + #10 + ' window');
  DumpWindow(AMenu.Window);
  Raw(' ');
  PS('font', AMenu.Font);
  PI('fullScreen', AMenu.FullScreen);
  PI('itemCount', AMenu.Items.Count);
  PI('fontIndex', AMenu.FontIndex);
  PI('cursorItem', AMenu.CursorItem);
  PI('fadeCycle', AMenu.FadeCycle);
  PF('fadeClamp', AMenu.FadeClamp);
  PF('fadeAmount', AMenu.FadeAmount);
  Raw(#10 + ' ');
  PS('onOpen', AMenu.OnOpen);
  PS('onClose', AMenu.OnClose);
  PS('onESC', AMenu.OnESC);
  PS('soundName', AMenu.SoundName);
  PC('focusColor', AMenu.FocusColor);
  PC('disableColor', AMenu.DisableColor);
  Raw(#10);
  for LIndex := 0 to AMenu.Items.Count - 1 do
    DumpItem(LIndex, AMenu.Items[LIndex]);
end;

procedure TGuiDump.Menus(const AMenus: TGuiMenuSet);
var
  LIndex: Integer;
begin
  Raw('menus ' + IntToStr(AMenus.Count) + #10);
  for LIndex := 0 to AMenus.Count - 1 do
    DumpMenu(LIndex, AMenus[LIndex]);
  Raw('assets');
  PF('fadeClamp', AMenus.Assets.FadeClamp);
  PI('fadeCycle', AMenus.Assets.FadeCycle);
  PF('fadeAmount', AMenus.Assets.FadeAmount);
  PF('shadowX', AMenus.Assets.ShadowX);
  PF('shadowY', AMenus.Assets.ShadowY);
  PC('shadowColor', AMenus.Assets.ShadowColor);
  PF('shadowFadeClamp', AMenus.Assets.ShadowFadeClamp);
  PS('cursorStr', AMenus.Assets.CursorStr);
  PI('cursor', AMenus.Assets.Cursor);
  PI('gradientBar', AMenus.Assets.GradientBar);
  PI('menuEnterSound', AMenus.Assets.MenuEnterSound);
  PI('menuExitSound', AMenus.Assets.MenuExitSound);
  PI('menuBuzzSound', AMenus.Assets.MenuBuzzSound);
  PI('itemFocusSound', AMenus.Assets.ItemFocusSound);
  PI('fontRegistered', Ord(AMenus.Assets.FontRegistered));
  Raw(#10);
end;

procedure TGuiDump.State(const AMenus: TGuiMenuSet);
var
  LMenu: Integer;
  LItem: Integer;
begin
  for LMenu := 0 to AMenus.Count - 1 do
  begin
    Raw('state menu ' + IntToStr(LMenu));
    WindowState(AMenus[LMenu].Window);
    for LItem := 0 to AMenus[LMenu].Items.Count - 1 do
    begin
      Raw('state item ' + IntToStr(LMenu) + '.' + IntToStr(LItem));
      WindowState(AMenus[LMenu].Items[LItem].Window);
    end;
  end;
end;

procedure TGuiDump.Font(const ALabel: string; const AFont: TGuiFont);
var
  LIndex: Integer;
  LHash: Cardinal;
  LGlyph: TGuiGlyph;
  LGlyphHash: Cardinal;
  LByte: Integer;
  LBytes: PByte;
  LShown: Integer;
begin
  Raw('font ' + ALabel);
  PS('name', AFont.Name);
  PF('glyphScale', AFont.GlyphScale);
  LHash := 2166136261;
  for LIndex := 0 to GUI_GLYPHS_PER_FONT - 1 do
  begin
    LGlyph := AFont.Glyphs[LIndex];
    LGlyphHash := 2166136261;
    LBytes := @LGlyph;
    for LByte := 0 to SizeOf(LGlyph) - 1 do
    begin
      LGlyphHash := LGlyphHash xor LBytes^;
      LGlyphHash := LGlyphHash * 16777619;
      Inc(LBytes);
    end;
    LHash := LHash xor LGlyphHash;
    LHash := LHash * 16777619;
  end;
  Raw(' glyphs=' + LowerCase(IntToHex(LHash, 8)) + #10);
  for LShown := 0 to High(SHOWN_GLYPHS) do
  begin
    LIndex := SHOWN_GLYPHS[LShown];
    LGlyph := AFont.Glyphs[LIndex];
    Raw(' glyph ' + IntToStr(LIndex));
    PI('height', LGlyph.Height);
    PI('top', LGlyph.Top);
    PI('bottom', LGlyph.Bottom);
    PI('pitch', LGlyph.Pitch);
    PI('xSkip', LGlyph.XSkip);
    PI('imageWidth', LGlyph.ImageWidth);
    PI('imageHeight', LGlyph.ImageHeight);
    PF('s', LGlyph.S);
    PF('t', LGlyph.T);
    PF('s2', LGlyph.S2);
    PF('t2', LGlyph.T2);
    PI('glyph', LGlyph.Glyph);
    PS('shaderName', AFont.ShaderName(LIndex));
    Raw(#10);
  end;
end;

{ TGuiScenarioRunner }

class function TGuiScenarioRunner.Run(const ARoot, AScenarioFile: string; const ATranscript: TStrings): Boolean;
var
  LScenario: TStringList;
  LFileSystem: IIdLibFileSystem;
  LLog: IGuiLog;
  LAssets: IGuiAssetRegistry;
  LHostScript: IGuiScriptHost;
  LHostMedia: IGuiMediaHost;
  LFonts: TGuiFontRegistry;
  LMenus: TGuiMenuSet;
  LFileReader: TGuiMenuFileReader;
  LRunner: TGuiScriptRunner;
  LDump: TGuiDump;
  LLine: string;
  LMenuName: string;
  LItemName: string;
  LScript: string;
  LMenu: TGuiMenu;
  LItem: TGuiItem;
  LDummy: TGuiItem;
  LFont: TGuiFont;
  LSpace: Integer;
begin
  Result := True;
  LScenario := TStringList.Create;
  LDump := TGuiDump.Create;
  try
    LScenario.LoadFromFile(AScenarioFile);
    LFileSystem := TGuiFakeFileSystem.Create(ARoot);
    LLog := TGuiFakeLog.Create(ATranscript);
    LAssets := TGuiFakeAssets.Create(ATranscript);
    LHostScript := TGuiFakeHost.Create(ATranscript);
    LHostMedia := LHostScript as IGuiMediaHost;
    LFonts := TGuiFactory.CreateFontRegistry(LFileSystem, LAssets, LLog);
    LMenus := TGuiFactory.CreateMenuSet(LAssets, LFonts);
    LFileReader := TGuiFactory.CreateMenuFileReader(TGuiFactory.CreateSourceLoader(LFileSystem, LLog), LMenus, LLog);
    LRunner := TGuiFactory.CreateScriptRunner(LMenus, LHostScript, LHostMedia);
    try
      // the defaults the C driver gives its display context
      LMenus.Assets.FadeClamp := 1.0;
      LMenus.Assets.FadeCycle := 1;
      LMenus.Assets.FadeAmount := 0.1;
      for LLine in LScenario do
      begin
        if (LLine = '') or (LLine[1] = '#') then
          Continue;
        ATranscript.Add('> ' + LLine);
        if Copy(LLine, 1, 5) = 'menu ' then
          LFileReader.ParseMenu(AnsiString(Copy(LLine, 6, MaxInt)))
        else if Copy(LLine, 1, 6) = 'menus ' then
          LFileReader.LoadMenus(AnsiString(Copy(LLine, 7, MaxInt)), False)
        else if Copy(LLine, 1, 5) = 'font ' then
        begin
          LFont := TGuiFont.Create;
          try
            LFonts.Register('ignored.ttf', StrToInt(Copy(LLine, 6, MaxInt)), LFont);
            LDump.Font('result', LFont);
            LDump.Flush(ATranscript);
          finally
            LFont.Free;
          end;
        end
        else if Copy(LLine, 1, 4) = 'run ' then
        begin
          LMenuName := Copy(LLine, 5, MaxInt);
          LSpace := Pos(' ', LMenuName);
          LItemName := Copy(LMenuName, LSpace + 1, MaxInt);
          LMenuName := Copy(LMenuName, 1, LSpace - 1);
          LSpace := Pos(' ', LItemName);
          LScript := Copy(LItemName, LSpace + 1, MaxInt);
          LItemName := Copy(LItemName, 1, LSpace - 1);
          LMenu := LMenus.FindByName(AnsiString(LMenuName));
          if not Assigned(LMenu) then
          begin
            ATranscript.Add('no menu');
            Continue;
          end;
          LDummy := nil;
          if LItemName = '-' then
          begin
            LDummy := TGuiItem.Create;
            // the C driver zeroes the item (memset), without Item_Init
            LDummy.Window := Default(TGuiWindowDef);
            LDummy.Parent := LMenu;
            LItem := LDummy;
          end
          else
            LItem := LMenu.FindItemByName(AnsiString(LItemName));
          try
            if not Assigned(LItem) then
            begin
              ATranscript.Add('no item');
              Continue;
            end;
            LRunner.Run(LItem, AnsiString(LScript));
            LDump.State(LMenus);
            if Assigned(LDummy) then
              LDump.DummyState(LDummy.Window);
            LDump.Flush(ATranscript);
          finally
            LDummy.Free;
          end;
        end
        else if LLine = 'dump' then
        begin
          LDump.Menus(LMenus);
          LDump.Flush(ATranscript);
        end
        else if LLine = 'state' then
        begin
          LDump.State(LMenus);
          LDump.Flush(ATranscript);
        end
        else if LLine = 'reset' then
          LMenus.Reset
        else
          ATranscript.Add('unknown scenario line');
      end;
    finally
      LRunner.Free;
      LFileReader.Free;
      LMenus.Free;
      LFonts.Free;
    end;
  finally
    LDump.Free;
    LScenario.Free;
  end;
end;

end.
