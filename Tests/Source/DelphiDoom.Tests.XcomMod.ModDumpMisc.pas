{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - the dump of the         }
{  articles, scripts, extras, interface, constants and indexes of a ruleset     }
{  (the same lines that modload.exe prints from the real Mod)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.ModDumpMisc;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.IntStringMap, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.Tests.XcomMod.DumpWriter;

type
  /// <summary>Prints the parts of a ruleset that are not rules by name: see TXcomModDump</summary>
  TXcomModDumpMisc = class
  strict private
    FWriter: TXcomDumpWriter;
    FMod: TXcomRuleset;
    class function MapText(const AValues: TXcomIntStringMap): string; static;
    class function ModText(const AMod: TXcomModData): string; static;
    class function PairsText(const AChanges: TArray<Cardinal>; const AValues: TArray<Integer>): string; static;
    procedure DumpArticles;
    procedure DumpMapScripts;
    procedure DumpMcdPatches;
    procedure DumpExtras;
    procedure DumpInterfaces;
    procedure DumpVideos;
    procedure DumpConverter;
    procedure DumpConstants;
    procedure DumpSettings;
    procedure DumpIndexes;
  public
    constructor Create(const AMod: TXcomRuleset; const AWriter: TXcomDumpWriter);
    /// <summary>The sections that Dump prints, in order</summary>
    class function Sections: TArray<string>; static;
    procedure Dump;
  end;

implementation

uses
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.McdPatch,
  DelphiDoom.XcomMod.ExtraSprites, DelphiDoom.XcomMod.ExtraSounds, DelphiDoom.XcomMod.ExtraStrings,
  DelphiDoom.XcomMod.StatString, DelphiDoom.XcomMod.RuleInterface, DelphiDoom.XcomMod.RuleVideo,
  DelphiDoom.XcomMod.RuleConverter, DelphiDoom.XcomMod.ModConstants, DelphiDoom.XcomMod.RulesetSettings;

{ TXcomModDumpMisc }

constructor TXcomModDumpMisc.Create(const AMod: TXcomRuleset; const AWriter: TXcomDumpWriter);
begin
  inherited Create;
  FMod := AMod;
  FWriter := AWriter;
end;

class function TXcomModDumpMisc.Sections: TArray<string>;
begin
  Result := TArray<string>.Create('ufopaedia', 'mapScripts', 'mcdPatches', 'extraSprites', 'extraSounds',
    'extraStrings', 'statStrings', 'interfaces', 'videos', 'converter', 'constants', 'settings', 'startingBase',
    'indexes');
end;

class function TXcomModDumpMisc.MapText(const AValues: TXcomIntStringMap): string;
var
  LIndex: Integer;
begin
  Result := '{';
  for LIndex := 0 to AValues.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(AValues.Key(LIndex)) + ':' + TXcomDumpWriter.Quote(AValues.Value(LIndex));
  end;
  Result := Result + '}';
end;

class function TXcomModDumpMisc.ModText(const AMod: TXcomModData): string;
begin
  Result := AMod.Name + ':' + UIntToStr(AMod.Offset) + ':' + UIntToStr(AMod.Size);
end;

class function TXcomModDumpMisc.PairsText(const AChanges: TArray<Cardinal>; const AValues: TArray<Integer>): string;
var
  LIndex: Integer;
begin
  Result := '[';
  for LIndex := 0 to High(AChanges) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + '(' + UIntToStr(AChanges[LIndex]) + ',' + IntToStr(AValues[LIndex]) + ')';
  end;
  Result := Result + ']';
end;

procedure TXcomModDumpMisc.DumpArticles;
var
  LIndex: Integer;
  LRule: TXcomArticleDefinition;
  function RectText(const ARect: TXcomArticleRect): string;
  begin
    Result := Format('%d/%d/%d/%d', [ARect.X, ARect.Y, ARect.Width, ARect.Height]);
  end;
begin
  for LIndex := 0 to FMod.Articles.Count - 1 do
  begin
    LRule := FMod.Articles.Rule(LIndex);
    FWriter.Begin_('ufopaedia', FMod.Articles.Name(LIndex));
    FWriter.Str('id', LRule.Id);
    FWriter.Str('title', LRule.Title);
    FWriter.Str('section', LRule.Section);
    FWriter.Strs('requires', LRule.Requirements);
    FWriter.Int('listOrder', LRule.ListOrder);
    case LRule.Kind of
      TXcomArticleDefinition.UFOPAEDIA_TYPE_CRAFT:
        begin
          FWriter.Str('class', 'craft');
          FWriter.Str('image_id', LRule.ImageId);
          FWriter.Line('rect_stats', RectText(LRule.RectStats));
          FWriter.Line('rect_text', RectText(LRule.RectText));
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_CRAFT_WEAPON:
        begin
          FWriter.Str('class', 'craftWeapon');
          FWriter.Str('image_id', LRule.ImageId);
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_TEXTIMAGE:
        begin
          FWriter.Str('class', 'textImage');
          FWriter.Str('image_id', LRule.ImageId);
          FWriter.Str('text', LRule.Text);
          FWriter.Int('text_width', LRule.TextWidth);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_VEHICLE:
        begin
          FWriter.Str('class', 'vehicle');
          FWriter.Str('weapon', LRule.Weapon);
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_ITEM:
        begin
          FWriter.Str('class', 'item');
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_ARMOR:
        begin
          FWriter.Str('class', 'armor');
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_BASE_FACILITY:
        begin
          FWriter.Str('class', 'baseFacility');
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_TEXT:
        begin
          FWriter.Str('class', 'text');
          FWriter.Str('text', LRule.Text);
        end;
      TXcomArticleDefinition.UFOPAEDIA_TYPE_UFO:
        begin
          FWriter.Str('class', 'ufo');
          FWriter.Str('text', LRule.Text);
        end;
    else
      FWriter.Str('class', 'tftd');
      FWriter.Int('type_id', LRule.Kind);
      FWriter.Str('image_id', LRule.ImageId);
      FWriter.Str('text', LRule.Text);
      FWriter.Int('text_width', LRule.TextWidth);
      FWriter.Str('weapon', LRule.Weapon);
    end;
  end;
end;

procedure TXcomModDumpMisc.DumpMapScripts;
var
  LIndex, LCommand, LRect, LName: Integer;
  LList: TObjectList<TXcomMapScript>;
  LScript: TXcomMapScript;
  LRects, LTunnel: string;
  LReplacement: TXcomMcdReplacement;
begin
  for LIndex := 0 to FMod.MapScripts.Count - 1 do
  begin
    LList := FMod.MapScripts.Value(LIndex);
    FWriter.Begin_('mapScripts', FMod.MapScripts.Key(LIndex));
    FWriter.Card('count', LList.Count);
    for LCommand := 0 to LList.Count - 1 do
    begin
      LScript := LList[LCommand];
      LRects := '[';
      for LRect := 0 to High(LScript.Rects) do
      begin
        if LRect > 0 then
          LRects := LRects + ';';
        LRects := LRects + Format('%d/%d/%d/%d', [LScript.Rects[LRect].X, LScript.Rects[LRect].Y,
          LScript.Rects[LRect].W, LScript.Rects[LRect].H]);
      end;
      LTunnel := 'none';
      if Assigned(LScript.TunnelData) then
      begin
        LTunnel := 'level' + IntToStr(LScript.TunnelData.Level) + '{';
        for LName := 0 to LScript.TunnelData.Replacements.Count - 1 do
        begin
          if LName > 0 then
            LTunnel := LTunnel + ',';
          LReplacement := LScript.TunnelData.Replacements.Value(LName);
          LTunnel := LTunnel + TXcomDumpWriter.Quote(LScript.TunnelData.Replacements.Key(LName)) + ':' +
            IntToStr(LReplacement.TileSet) + '/' + IntToStr(LReplacement.Entry);
        end;
        LTunnel := LTunnel + '}';
      end;
      FWriter.Line('cmd' + IntToStr(LCommand), IntToStr(LScript.CommandType) + '|' + LRects + ']|' +
        TXcomDumpWriter.IntList(LScript.Groups) + '|' + TXcomDumpWriter.IntList(LScript.Blocks) + '|' +
        TXcomDumpWriter.IntList(LScript.Frequencies) + '|' + TXcomDumpWriter.IntList(LScript.MaxUses) + '|' +
        TXcomDumpWriter.IntList(LScript.Conditionals) + '|' + Format('%d,%d,%d', [LScript.SizeX, LScript.SizeY,
        LScript.SizeZ]) + '|' + Format('%d,%d,%d', [LScript.ChancesOfExecution, LScript.Executions,
        LScript.ScriptLabel]) + '|' + IntToStr(LScript.Direction) + '|' + LTunnel + '|' +
        TXcomDumpWriter.Quote(LScript.UfoName));
    end;
  end;
end;

procedure TXcomModDumpMisc.DumpMcdPatches;
const
  NUMBER_NAMES: array[0..12] of string = ('bigWalls', 'TUWalks', 'TUFlys', 'TUSlides', 'deathTiles',
    'terrainHeight', 'specialTypes', 'explosives', 'armors', 'flammabilities', 'fuels', 'footstepSounds',
    'HEBlocks');
var
  LIndex, LField, LChange: Integer;
  LPatch: TXcomMcdPatch;
  LText: string;
  procedure FlagText(const AKey: string; const AList: TArray<TXcomMcdChange>);
  var
    LItem: Integer;
    LResult: string;
  begin
    LResult := '[';
    for LItem := 0 to High(AList) do
    begin
      if LItem > 0 then
        LResult := LResult + ',';
      LResult := LResult + '(' + UIntToStr(AList[LItem].McdIndex) + ',' + IntToStr(AList[LItem].Value) + ')';
    end;
    FWriter.Line(AKey, LResult + ']');
  end;
begin
  for LIndex := 0 to FMod.McdPatches.Count - 1 do
  begin
    LPatch := FMod.McdPatches.Value(LIndex);
    FWriter.Begin_('mcdPatches', FMod.McdPatches.Key(LIndex));
    for LField := 0 to High(NUMBER_NAMES) do
      FlagText(NUMBER_NAMES[LField], LPatch.Numbers(TXcomMcdPatch.NUMBER_FIELDS[LField]));
    FlagText('noFloors', LPatch.NoFloors);
    LText := '[';
    for LChange := 0 to High(LPatch.Lofts) do
    begin
      if LChange > 0 then
        LText := LText + ',';
      LText := LText + '(' + UIntToStr(LPatch.Lofts[LChange]) + ',' + TXcomDumpWriter.IntList(LPatch.LoftValues[LChange]) + ')';
    end;
    FWriter.Line('LOFTS', LText + ']');
    FlagText('stopLOSses', LPatch.StopLos);
    FlagText('objectTypes', LPatch.ObjectTypes);
  end;
end;

procedure TXcomModDumpMisc.DumpExtras;
var
  LIndex, LSet, LName: Integer;
  LSprites: TObjectList<TXcomExtraSprites>;
  LRule: TXcomExtraSprites;
  LSounds: TXcomExtraSounds;
  LStrings: TXcomExtraStrings;
  LStat: TXcomStatString;
  LText: string;
begin
  for LIndex := 0 to FMod.ExtraSprites.Count - 1 do
  begin
    LSprites := FMod.ExtraSprites.Value(LIndex);
    FWriter.Begin_('extraSprites', FMod.ExtraSprites.Key(LIndex));
    FWriter.Card('count', LSprites.Count);
    for LSet := 0 to LSprites.Count - 1 do
    begin
      LRule := LSprites[LSet];
      FWriter.Line('set' + IntToStr(LSet), TXcomDumpWriter.Quote(LRule.SetName) + '|' + MapText(LRule.Sprites) + '|' +
        Format('%d,%d,%d,%d,%d', [LRule.Width, LRule.Height, Ord(LRule.SingleImage), LRule.SubX, LRule.SubY]) + '|' +
        ModText(LRule.ModData));
    end;
  end;
  FWriter.Begin_('extraSounds', 'list');
  FWriter.Card('count', FMod.ExtraSounds.Count);
  for LSet := 0 to FMod.ExtraSounds.Count - 1 do
  begin
    LSounds := FMod.ExtraSounds[LSet];
    FWriter.Line('set' + IntToStr(LSet), TXcomDumpWriter.Quote(LSounds.SetName) + '|' +
      TXcomDumpWriter.Quote(LSounds.SetName) + '|' + MapText(LSounds.Sounds) + '|' + ModText(LSounds.ModData));
  end;
  for LIndex := 0 to FMod.ExtraStrings.Count - 1 do
  begin
    LStrings := FMod.ExtraStrings.Value(LIndex);
    FWriter.Begin_('extraStrings', FMod.ExtraStrings.Key(LIndex));
    LText := '{';
    for LName := 0 to LStrings.Strings.Count - 1 do
    begin
      if LName > 0 then
        LText := LText + ',';
      LText := LText + TXcomDumpWriter.Quote(LStrings.Strings.Key(LName)) + ':' +
        TXcomDumpWriter.Quote(LStrings.Strings.Value(LName));
    end;
    FWriter.Line('strings', LText + '}');
  end;
  FWriter.Begin_('statStrings', 'list');
  FWriter.Card('count', FMod.StatStrings.Count);
  for LSet := 0 to FMod.StatStrings.Count - 1 do
  begin
    LStat := FMod.StatStrings[LSet];
    LText := '[';
    for LName := 0 to High(LStat.Conditions) do
    begin
      if LName > 0 then
        LText := LText + ';';
      LText := LText + TXcomDumpWriter.Quote(LStat.Conditions[LName].ConditionName) + '/' +
        IntToStr(LStat.Conditions[LName].MinVal) + '/' + IntToStr(LStat.Conditions[LName].MaxVal);
    end;
    FWriter.Line('s' + IntToStr(LSet), TXcomDumpWriter.Quote(LStat.Text) + '|' + LText + ']');
  end;
end;

procedure TXcomModDumpMisc.DumpInterfaces;
var
  LIndex, LElement: Integer;
  LRule: TXcomRuleInterface;
  LItem: TXcomInterfaceElement;
begin
  for LIndex := 0 to FMod.Interfaces.Count - 1 do
  begin
    LRule := FMod.Interfaces.Rule(LIndex);
    FWriter.Begin_('interfaces', FMod.Interfaces.Name(LIndex));
    FWriter.Str('type', LRule.InterfaceType);
    FWriter.Str('palette', LRule.Palette);
    FWriter.Str('parent', LRule.Parent);
    FWriter.Str('music', LRule.Music);
    FWriter.Card('count', LRule.Elements.Count);
    for LElement := 0 to LRule.Elements.Count - 1 do
    begin
      LItem := LRule.Elements.Value(LElement);
      FWriter.Line('e_' + TXcomDumpWriter.Escape(LRule.Elements.Key(LElement)),
        Format('%d/%d/%d/%d/%d/%d/%d/%d', [LItem.X, LItem.Y, LItem.W, LItem.H, LItem.Color, LItem.Color2,
        LItem.Border, Ord(LItem.TFTDMode)]));
    end;
  end;
end;

procedure TXcomModDumpMisc.DumpVideos;
var
  LIndex, LSlide: Integer;
  LRule: TXcomRuleVideo;
  LItem: TXcomSlideshowSlide;
begin
  for LIndex := 0 to FMod.Videos.Count - 1 do
  begin
    LRule := FMod.Videos.Rule(LIndex);
    FWriter.Begin_('videos', FMod.Videos.Name(LIndex));
    FWriter.Str('id', LRule.VideoId);
    FWriter.Bool('useUfoAudioSequence', LRule.UseUfoAudioSequence);
    FWriter.Strs('videos', LRule.Videos);
    FWriter.Strs('audioTracks', LRule.AudioTracks);
    FWriter.Line('header', TXcomDumpWriter.Quote(LRule.SlideshowHeader.MusicId) + ',' +
      IntToStr(LRule.SlideshowHeader.TransitionSeconds));
    FWriter.Card('slides', Length(LRule.Slides));
    for LSlide := 0 to High(LRule.Slides) do
    begin
      LItem := LRule.Slides[LSlide];
      FWriter.Line('slide' + IntToStr(LSlide), TXcomDumpWriter.Quote(LItem.ImagePath) + ',' +
        TXcomDumpWriter.Quote(LItem.Caption) + Format(',%d,%d,%d,%d,%d,%d,%d', [LItem.W, LItem.H, LItem.X, LItem.Y,
        LItem.Color, LItem.Align, LItem.TransitionSeconds]));
    end;
  end;
end;

procedure TXcomModDumpMisc.DumpConverter;
var
  LName: string;
begin
  FWriter.Begin_('converter', 'data');
  FWriter.IntMap('offsets', FMod.Converter.Offsets);
  for LName in TXcomRuleConverter.LIST_NAMES do
    FWriter.Strs(LName, FMod.Converter.List(LName));
end;

procedure TXcomModDumpMisc.DumpConstants;
var
  LConstants: TXcomModConstants;
begin
  LConstants := FMod.Constants;
  FWriter.Begin_('constants', 'values');
  FWriter.Int('DOOR_OPEN', LConstants.DoorOpen);
  FWriter.Int('SLIDING_DOOR_OPEN', LConstants.SlidingDoorOpen);
  FWriter.Int('SLIDING_DOOR_CLOSE', LConstants.SlidingDoorClose);
  FWriter.Int('SMALL_EXPLOSION', LConstants.SmallExplosion);
  FWriter.Int('LARGE_EXPLOSION', LConstants.LargeExplosion);
  FWriter.Int('EXPLOSION_OFFSET', LConstants.ExplosionOffset);
  FWriter.Int('SMOKE_OFFSET', LConstants.SmokeOffset);
  FWriter.Int('UNDERWATER_SMOKE_OFFSET', LConstants.UnderwaterSmokeOffset);
  FWriter.Int('ITEM_DROP', LConstants.ItemDrop);
  FWriter.Int('ITEM_THROW', LConstants.ItemThrow);
  FWriter.Int('ITEM_RELOAD', LConstants.ItemReload);
  FWriter.Int('WALK_OFFSET', LConstants.WalkOffset);
  FWriter.Int('FLYING_SOUND', LConstants.FlyingSound);
  FWriter.Int('BUTTON_PRESS', LConstants.ButtonPress);
  FWriter.Ints('WINDOW_POPUP', TArray<Integer>.Create(LConstants.WindowPopup[0], LConstants.WindowPopup[1],
    LConstants.WindowPopup[2]));
  FWriter.Int('UFO_FIRE', LConstants.UfoFire);
  FWriter.Int('UFO_HIT', LConstants.UfoHit);
  FWriter.Int('UFO_CRASH', LConstants.UfoCrash);
  FWriter.Int('UFO_EXPLODE', LConstants.UfoExplode);
  FWriter.Int('INTERCEPTOR_HIT', LConstants.InterceptorHit);
  FWriter.Int('INTERCEPTOR_EXPLODE', LConstants.InterceptorExplode);
  FWriter.Int('GEOSCAPE_CURSOR', LConstants.GeoscapeCursor);
  FWriter.Int('BASESCAPE_CURSOR', LConstants.BasescapeCursor);
  FWriter.Int('BATTLESCAPE_CURSOR', LConstants.BattlescapeCursor);
  FWriter.Int('UFOPAEDIA_CURSOR', LConstants.UfopaediaCursor);
  FWriter.Int('GRAPHS_CURSOR', LConstants.GraphsCursor);
  FWriter.Int('DAMAGE_RANGE', LConstants.DamageRange);
  FWriter.Int('EXPLOSIVE_DAMAGE_RANGE', LConstants.ExplosiveDamageRange);
  FWriter.Ints('FIRE_DAMAGE_RANGE', TArray<Integer>.Create(LConstants.FireDamageRange[0],
    LConstants.FireDamageRange[1]));
  FWriter.Str('DEBRIEF_MUSIC_GOOD', LConstants.DebriefMusicGood);
  FWriter.Str('DEBRIEF_MUSIC_BAD', LConstants.DebriefMusicBad);
end;

procedure TXcomModDumpMisc.DumpSettings;
var
  LSettings: TXcomRulesetSettings;
  LLevel, LRow: Integer;
  LRows: string;
  LKeys: TArray<string>;
  LIndex: Integer;
begin
  LSettings := FMod.Settings;
  FWriter.Begin_('settings', 'values');
  FWriter.Int('costEngineer', LSettings.CostEngineer);
  FWriter.Int('costScientist', LSettings.CostScientist);
  FWriter.Int('timePersonnel', LSettings.TimePersonnel);
  FWriter.Int('initialFunding', LSettings.InitialFunding);
  FWriter.Int('turnAIUseGrenade', LSettings.TurnAIUseGrenade);
  FWriter.Int('turnAIUseBlaster', LSettings.TurnAIUseBlaster);
  FWriter.Int('defeatScore', LSettings.DefeatScore);
  FWriter.Int('defeatFunds', LSettings.DefeatFunds);
  FWriter.Bool('difficultyDemigod', LSettings.DifficultyDemigod);
  FWriter.Line('alienFuel', '(' + TXcomDumpWriter.Quote(LSettings.AlienFuelName) + ',' +
    IntToStr(LSettings.AlienFuelQuantity) + ')');
  FWriter.Str('fontName', LSettings.FontName);
  LRows := '[';
  for LRow := 0 to High(LSettings.AlienItemLevels) do
  begin
    if LRow > 0 then
      LRows := LRows + ',';
    LRows := LRows + TXcomDumpWriter.IntList(LSettings.AlienItemLevels[LRow]);
  end;
  FWriter.Line('alienItemLevels', LRows + ']');
  FWriter.Ints('difficultyCoefficient', TArray<Integer>.Create(LSettings.DifficultyCoefficient[0],
    LSettings.DifficultyCoefficient[1], LSettings.DifficultyCoefficient[2], LSettings.DifficultyCoefficient[3],
    LSettings.DifficultyCoefficient[4]));
  for LLevel := 0 to TXcomRulesetSettings.DIFFICULTY_LEVELS - 1 do
    FWriter.Line('adjust' + IntToStr(LLevel), TXcomDumpWriter.StatsText(LSettings.StatAdjustment[LLevel].StatGrowth) + '|' +
      IntToStr(LSettings.StatAdjustment[LLevel].GrowthMultiplier) + '|' +
      TXcomDumpWriter.HexDouble(LSettings.StatAdjustment[LLevel].AimAndArmorMultiplier));
  FWriter.Begin_('startingBase', 'keys');
  SetLength(LKeys, FMod.StartingBase.Count);
  for LIndex := 0 to High(LKeys) do
    LKeys[LIndex] := FMod.StartingBase.Key(LIndex);
  FWriter.Strs('keys', LKeys);
end;

procedure TXcomModDumpMisc.DumpIndexes;
var
  LSections: TXcomStringMap<Integer>;
begin
  FWriter.Begin_('indexes', 'lists');
  FWriter.Strs('countries', FMod.Countries.Index);
  FWriter.Strs('regions', FMod.Regions.Index);
  FWriter.Strs('facilities', FMod.Facilities.Index);
  FWriter.Strs('crafts', FMod.Crafts.Index);
  FWriter.Strs('craftWeapons', FMod.CraftWeapons.Index);
  FWriter.Strs('items', FMod.Items.Index);
  FWriter.Strs('invs', FMod.Inventories.Index);
  FWriter.Strs('ufos', FMod.Ufos.Index);
  FWriter.Strs('soldiers', FMod.Soldiers.Index);
  FWriter.Strs('aliens', FMod.AlienRaces.Index);
  FWriter.Strs('deployments', FMod.AlienDeployments.Index);
  FWriter.Strs('ufopaedia', FMod.Articles.Index);
  FWriter.Strs('ufopaediaCat', FMod.ArticleSectionIndex.ToArray);
  FWriter.Strs('research', FMod.Research.Index);
  FWriter.Strs('manufacture', FMod.Manufacture.Index);
  FWriter.Strs('alienMissions', FMod.AlienMissions.Index);
  FWriter.Strs('terrains', FMod.Terrains.Index);
  FWriter.Strs('missionScripts', FMod.MissionScripts.Index);
  LSections := FMod.ArticleSections;
  FWriter.IntMap('ufopaediaSections', LSections);
end;

procedure TXcomModDumpMisc.Dump;
begin
  DumpArticles;
  DumpMapScripts;
  DumpMcdPatches;
  DumpExtras;
  DumpInterfaces;
  DumpVideos;
  DumpConverter;
  DumpConstants;
  DumpSettings;
  DumpIndexes;
end;

end.
