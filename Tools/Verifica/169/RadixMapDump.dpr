program RadixMapDump;

{$APPTYPE CONSOLE}

// Writes a level of RADIX.DAT, as the engine gets it from the translator, as text: things (with the height and
// the number of RTHINGS), lines, sectors, the script RMAP, actions, triggers and the cells of the grid that have a
// trigger (with their place in the map). It is what one needs to find the way through a level (issue #169):
//   RadixMapDump <RADIX.DAT> <E1M1> <out.txt>

uses
  System.SysUtils, System.Classes,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory, DelphiDoom.Radix.Types,
  DelphiDoom.Radix.Level.Types;

var
  Wad: IGameWadComposer;
  Output: TStringList;
  First: Integer;

function Lump(const AName: string): TBytes;
var
  LIndex: Integer;
begin
  // the lumps of a level follow its marker
  for LIndex := First + 1 to First + 20 do
    if (LIndex < Wad.Count) and SameText(Wad.LumpNames[LIndex], AName) then
      Exit(Wad.LumpData[LIndex]);
  raise Exception.CreateFmt('The level has no lump %s', [AName]);
end;

function Name8(const AName: TRadixName8): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to 7 do
    if AName.Chars[LIndex] <> #0 then
      Result := Result + string(AName.Chars[LIndex]);
  if Result = '' then
    Result := '-';
end;

function NameOf(const AChars: array of AnsiChar): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AChars) do
  begin
    if AChars[LIndex] = #0 then
      Break;
    Result := Result + string(AChars[LIndex]);
  end;
end;

procedure DumpLevel;
var
  LThings, LExtras, LLines, LSides, LVertexes, LSectors, LActions, LTriggers, LGrid, LPoints, LScript: TBytes;
  LThing: TRadixDoomThing;
  LExtra: TRadixDoomThingExtra;
  LLine: TRadixDoomLineDef;
  LSide: TRadixDoomSideDef;
  LVertex1, LVertex2: TRadixDoomVertex;
  LSector: TRadixDoomSector;
  LAction: TRadixLevelAction;
  LTrigger: TRadixLevelTrigger;
  LIndex, LItem, LLast, LFront, LBack, LCell: Integer;
  LText: string;
  LCellValue: SmallInt;
  LPoint: TRadixLevelMapPoint;
  LWidth, LHeight: Integer;
begin
  LThings := Lump('THINGS');
  LExtras := Lump('RTHINGS');
  Output.Add(Format('THINGS %d: index type x y angle options | z skill radixid', [Length(LThings) div SizeOf(LThing)]));
  for LIndex := 0 to Length(LThings) div SizeOf(LThing) - 1 do
  begin
    Move(LThings[LIndex * SizeOf(LThing)], LThing, SizeOf(LThing));
    FillChar(LExtra, SizeOf(LExtra), 0);
    if (LIndex + 1) * SizeOf(LExtra) <= Length(LExtras) then
      Move(LExtras[LIndex * SizeOf(LExtra)], LExtra, SizeOf(LExtra));
    Output.Add(Format('T %d %d %d %d %d %d | %d %d %d', [LIndex, LThing.ThingType, LThing.X, LThing.Y, LThing.Angle,
      LThing.Options, LExtra.Z, LExtra.RadixSkill, LExtra.RadixId]));
  end;

  LSectors := Lump('SECTORS');
  Output.Add(Format('SECTORS %d: index floor ceiling light special tag floorpic ceilingpic',
    [Length(LSectors) div SizeOf(LSector)]));
  for LIndex := 0 to Length(LSectors) div SizeOf(LSector) - 1 do
  begin
    Move(LSectors[LIndex * SizeOf(LSector)], LSector, SizeOf(LSector));
    Output.Add(Format('S %d %d %d %d %d %d %s %s', [LIndex, LSector.FloorHeight, LSector.CeilingHeight,
      LSector.LightLevel, LSector.Special, LSector.Tag, Name8(LSector.FloorPic), Name8(LSector.CeilingPic)]));
  end;

  LLines := Lump('LINEDEFS');
  LSides := Lump('SIDEDEFS');
  LVertexes := Lump('VERTEXES');
  Output.Add(Format('LINES %d: index x1 y1 x2 y2 flags special tag frontsector backsector midtexture',
    [Length(LLines) div SizeOf(LLine)]));
  for LIndex := 0 to Length(LLines) div SizeOf(LLine) - 1 do
  begin
    Move(LLines[LIndex * SizeOf(LLine)], LLine, SizeOf(LLine));
    Move(LVertexes[LLine.V1 * SizeOf(LVertex1)], LVertex1, SizeOf(LVertex1));
    Move(LVertexes[LLine.V2 * SizeOf(LVertex2)], LVertex2, SizeOf(LVertex2));
    LFront := -1;
    LBack := -1;
    LText := '-';
    if LLine.SideNum[0] >= 0 then
    begin
      Move(LSides[LLine.SideNum[0] * SizeOf(LSide)], LSide, SizeOf(LSide));
      LFront := LSide.Sector;
      LText := Name8(LSide.MidTexture);
    end;
    if LLine.SideNum[1] >= 0 then
    begin
      Move(LSides[LLine.SideNum[1] * SizeOf(LSide)], LSide, SizeOf(LSide));
      LBack := LSide.Sector;
    end;
    Output.Add(Format('L %d %d %d %d %d %d %d %d %d %d %s', [LIndex, LVertex1.X, LVertex1.Y, LVertex2.X, LVertex2.Y,
      LLine.Flags, LLine.Special, LLine.Tag, LFront, LBack, LText]));
  end;

  LScript := Lump('RMAP');
  Output.Add('RMAP');
  SetString(LText, PAnsiChar(@LScript[0]), Length(LScript));
  Output.Add(string(AnsiString(TEncoding.ANSI.GetString(LScript))));

  LActions := Lump('RACTION');
  Output.Add(Format('ACTIONS %d: index enabled suspend type name | params', [Length(LActions) div SizeOf(LAction)]));
  for LIndex := 0 to Length(LActions) div SizeOf(LAction) - 1 do
  begin
    Move(LActions[LIndex * SizeOf(LAction)], LAction, SizeOf(LAction));
    LLast := -1;
    for LItem := 0 to RADIX_MAX_ACTION_PARAMS - 1 do
      if LAction.Params[LItem] <> 0 then
        LLast := LItem;
    LText := '';
    for LItem := 0 to LLast do
      LText := LText + ' ' + IntToStr(LAction.Params[LItem]);
    Output.Add(Format('A %d %d %d %d %s |%s', [LIndex, LAction.Enabled, LAction.Suspend, LAction.ActionType,
      NameOf(LAction.NameId), LText]));
  end;

  LTriggers := Lump('RTRIGGER');
  Output.Add(Format('TRIGGERS %d: index suspended name | action:trigger:flags ...',
    [Length(LTriggers) div SizeOf(LTrigger)]));
  for LIndex := 0 to Length(LTriggers) div SizeOf(LTrigger) - 1 do
  begin
    Move(LTriggers[LIndex * SizeOf(LTrigger)], LTrigger, SizeOf(LTrigger));
    LText := '';
    for LItem := 0 to LTrigger.NumActions - 1 do
      if LItem < RADIX_MAX_TRIGGER_ACTIONS then
        LText := LText + Format(' %d:%d:%d', [LTrigger.Actions[LItem].ActionId, LTrigger.Actions[LItem].Trigger,
          LTrigger.Actions[LItem].ActivationFlags]);
    Output.Add(Format('G %d %d %s |%s', [LIndex, LTrigger.Suspended, NameOf(LTrigger.NameId), LText]));
  end;

  LGrid := Lump('RGRID');
  LPoints := Lump('RMAPGRID');
  Move(LGrid[0], LWidth, 4);
  Move(LGrid[4], LHeight, 4);
  Output.Add(Format('GRID %d x %d: cell column row trigger mapx mapy (the upper left corner of the cell)',
    [LWidth, LHeight]));
  for LCell := 0 to RADIX_GRID_SIZE - 1 do
  begin
    Move(LGrid[8 + LCell * 2], LCellValue, 2);
    if (LCellValue < 0) or (LWidth = 0) then
      Continue;
    Move(LPoints[LCell * SizeOf(LPoint)], LPoint, SizeOf(LPoint));
    Output.Add(Format('C %d %d %d %d %d %d', [LCell, LCell mod LWidth, LCell div LWidth, LCellValue, LPoint.X, LPoint.Y]));
  end;
end;

begin
  try
    if ParamCount < 3 then
    begin
      Writeln('RadixMapDump <RADIX.DAT> <E1M1> <out.txt>');
      Halt(2);
    end;
    Wad := TRadixFactory.CreateTranslator(TRadixLumpNames.Doom).Translate(TRadixFactory.OpenContainer(ParamStr(1)));
    First := Wad.IndexOf(ParamStr(2));
    if First < 0 then
      raise Exception.CreateFmt('No level %s', [ParamStr(2)]);
    Output := TStringList.Create;
    try
      DumpLevel;
      Output.SaveToFile(ParamStr(3));
    finally
      Output.Free;
    end;
    Writeln('written ', ParamStr(3));
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
