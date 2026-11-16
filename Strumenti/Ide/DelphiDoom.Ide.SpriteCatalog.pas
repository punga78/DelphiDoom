{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the "Sprites" panel                               }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.SpriteCatalog;

interface

uses
  System.Classes,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Outline;

type
  /// <summary>
  ///   The sprites of a game: for each sprite name (four letters) the frames the states use
  ///   (name and frame letter) and for each frame the actors that show it. The tree has the three
  ///   levels; the list shows the actors of the sprite or frame that is selected
  /// </summary>
  TIdeSpriteCatalog = class
  strict private
    FSprites: TStringList;
    procedure ClearSprites;
    procedure Link(const AStateSprites, AStateNext: TStringList; const AActorNames: TArray<string>;
      const AFrameColumn: TArray<string>);
  public
    constructor Create;
    destructor Destroy; override;
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
    function BuildOutline(const AFilter: string): TIdeOutline;
    /// <summary>
    ///   The list for a line of the tree: a sprite gives the actors of all its frames, a frame
    ///   gives its own actors, an actor gives itself. The level is 0 for a sprite, 1 for a frame,
    ///   2 for an actor
    /// </summary>
    function RowsFor(const ASelectedText: string; const ALevel: Integer): TArray<TIdeRow>;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Csv;

function NewSortedList: TStringList;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
end;

function FrameName(const ASpriteName: string; const ASubnumber: string): string;
begin
  Result := ASpriteName + Chr(Ord('A') + StrToIntDef(ASubnumber, 0) mod 32768);
end;

{ TIdeSpriteCatalog }

constructor TIdeSpriteCatalog.Create;
begin
  inherited Create;
  FSprites := TStringList.Create;
end;

destructor TIdeSpriteCatalog.Destroy;
begin
  ClearSprites;
  FSprites.Free;
  inherited Destroy;
end;

procedure TIdeSpriteCatalog.ClearSprites;
var
  LIndex, LFrame: Integer;
  LFrames: TStringList;
begin
  for LIndex := 0 to FSprites.Count - 1 do
  begin
    LFrames := FSprites.Objects[LIndex] as TStringList;
    if LFrames <> nil then
    begin
      for LFrame := 0 to LFrames.Count - 1 do
        LFrames.Objects[LFrame].Free;
      LFrames.Free;
    end;
  end;
  FSprites.Sorted := False;
  FSprites.Clear;
end;

procedure TIdeSpriteCatalog.Link(const AStateSprites, AStateNext: TStringList;
  const AActorNames: TArray<string>; const AFrameColumn: TArray<string>);
var
  LActor, LStart, LNumber, LPrevious, LSprite: Integer;
  LFrameName, LActorName: string;
  LFrames, LActors: TStringList;
begin
  for LActor := 0 to High(AFrameColumn) do
  begin
    LActorName := AActorNames[LActor];
    LNumber := StrToIntDef(AFrameColumn[LActor], -1);
    LStart := LNumber;
    while True do
    begin
      if (LNumber >= 0) and (LNumber < AStateSprites.Count) then
      begin
        LFrameName := AStateSprites[LNumber];
        if Length(LFrameName) = 5 then
        begin
          LSprite := FSprites.IndexOf(Copy(LFrameName, 1, 4));
          if LSprite >= 0 then
          begin
            LFrames := FSprites.Objects[LSprite] as TStringList;
            LSprite := LFrames.IndexOf(LFrameName);
            if LSprite >= 0 then
            begin
              LActors := LFrames.Objects[LSprite] as TStringList;
              if LActors.IndexOf(LActorName) < 0 then
                LActors.Add(LActorName)
              else
                Break;
            end;
          end;
        end;
      end;
      LPrevious := LNumber;
      if (LNumber >= 0) and (LNumber < AStateNext.Count) then
        LNumber := StrToIntDef(AStateNext[LNumber], 0)
      else
        LNumber := 0;
      if (LNumber = 0) or (LNumber = LStart) or (LNumber = LPrevious) then
        Break;
    end;
  end;
end;

function TIdeSpriteCatalog.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LSprites, LStates, LMobjinfo: TArray<string>;
  LNames, LNumbers, LSubnumbers, LNext, LActorNames, LFrameColumns: TArray<string>;
  LStateSprites, LStateNext: TStringList;
  LHeader: TArray<string>;
  LIndex, LNumber: Integer;
  LFrames: TStringList;
  LFrameName: string;
begin
  Result := ALibrary.TryGetLines(ldSpritesCsv, AGame, LSprites);
  if not Result then
    Exit;
  Result := Length(LSprites) > 0;
  if not Result then
    Exit;

  ClearSprites;
  LNames := TIdeCsv.Column(LSprites, 'Sprite');
  for LIndex := 0 to High(LNames) do
    FSprites.AddObject(LNames[LIndex], NewSortedList);

  if not ALibrary.TryGetLines(ldStatesCsv, AGame, LStates) then
    LStates := nil;
  LNumbers := TIdeCsv.Column(LStates, 'Sprite Number');
  LSubnumbers := TIdeCsv.Column(LStates, 'Sprite Subnumber');
  LNext := TIdeCsv.Column(LStates, 'Next Frame');

  LStateSprites := TStringList.Create;
  LStateNext := TStringList.Create;
  try
    for LIndex := 0 to High(LNumbers) do
    begin
      LNumber := StrToIntDef(LNumbers[LIndex], -1);
      if (LNumber >= 0) and (LNumber < FSprites.Count) then
      begin
        LFrames := FSprites.Objects[LNumber] as TStringList;
        LFrameName := FrameName(FSprites[LNumber], LSubnumbers[LIndex]);
        if LFrames.IndexOf(LFrameName) < 0 then
          LFrames.AddObject(LFrameName, NewSortedList);
      end;
    end;

    for LIndex := 0 to High(LNumbers) do
    begin
      LNumber := StrToIntDef(LNumbers[LIndex], 0);
      if (LNumber >= 0) and (LNumber < FSprites.Count) then
        LStateSprites.Add(FrameName(FSprites[LNumber], LSubnumbers[LIndex]))
      else
        LStateSprites.Add('');
    end;
    for LIndex := 0 to High(LNext) do
      LStateNext.Add(LNext[LIndex]);

    if not ALibrary.TryGetLines(ldMobjinfoCsv, AGame, LMobjinfo) then
      LMobjinfo := nil;
    if Length(LMobjinfo) > 0 then
    begin
      LHeader := TIdeCsv.ParseLine(LMobjinfo[0]);
      LActorNames := TIdeCsv.Column(LMobjinfo, 'Name');
      for LIndex := 0 to High(LHeader) do
        if Pos(' FRAME: ', UpperCase(LHeader[LIndex]) + ': ') > 0 then
        begin
          LFrameColumns := TIdeCsv.Column(LMobjinfo, LHeader[LIndex]);
          Link(LStateSprites, LStateNext, LActorNames, LFrameColumns);
        end;
    end;
  finally
    LStateNext.Free;
    LStateSprites.Free;
  end;
  FSprites.Sorted := True;
end;

function TIdeSpriteCatalog.BuildOutline(const AFilter: string): TIdeOutline;
var
  LFilter: string;
  LIndex, LFrame, LActor: Integer;
  LSpriteNode, LFrameNode: TIdeOutlineNode;
  LFrames, LActors: TStringList;
begin
  Result := TIdeOutline.Create;
  LFilter := LowerCase(Trim(AFilter));
  for LIndex := 0 to FSprites.Count - 1 do
  begin
    if (LFilter <> '') and (Pos(LFilter, LowerCase(FSprites[LIndex])) = 0) then
      Continue;
    LSpriteNode := Result.AddRoot(FSprites[LIndex]);
    LFrames := FSprites.Objects[LIndex] as TStringList;
    if LFrames = nil then
      Continue;
    for LFrame := 0 to LFrames.Count - 1 do
    begin
      LFrameNode := LSpriteNode.AddChild(LFrames[LFrame]);
      LActors := LFrames.Objects[LFrame] as TStringList;
      if LActors <> nil then
        for LActor := 0 to LActors.Count - 1 do
          LFrameNode.AddChild(LActors[LActor]);
    end;
  end;
end;

function TIdeSpriteCatalog.RowsFor(const ASelectedText: string; const ALevel: Integer): TArray<TIdeRow>;
var
  LSprite4, LSprite5: string;
  LSpriteIndex, LFrameIndex, LIndex, LActor: Integer;
  LPool, LFrames, LActors: TStringList;
begin
  Result := nil;
  if ALevel >= 2 then
  begin
    SetLength(Result, 1);
    Result[0].Caption := ASelectedText;
    Result[0].Tag := 0;
    Exit;
  end;
  LSprite4 := '';
  LSprite5 := '';
  if Length(ASelectedText) = 4 then
    LSprite4 := ASelectedText
  else if Length(ASelectedText) = 5 then
  begin
    LSprite4 := Copy(ASelectedText, 1, 4);
    LSprite5 := ASelectedText;
  end;
  LSpriteIndex := FSprites.IndexOf(LSprite4);
  if (LSprite4 = '') or (LSpriteIndex < 0) then
    Exit;
  LPool := TStringList.Create;
  try
    LFrames := FSprites.Objects[LSpriteIndex] as TStringList;
    if LSprite5 <> '' then
    begin
      LFrameIndex := LFrames.IndexOf(LSprite5);
      if LFrameIndex >= 0 then
      begin
        LActors := LFrames.Objects[LFrameIndex] as TStringList;
        for LIndex := 0 to LActors.Count - 1 do
          LPool.Add(LActors[LIndex]);
      end;
    end
    else
      for LIndex := 0 to LFrames.Count - 1 do
      begin
        LActors := LFrames.Objects[LIndex] as TStringList;
        if LActors <> nil then
          for LActor := 0 to LActors.Count - 1 do
            if LPool.IndexOf(LActors[LActor]) < 0 then
              LPool.Add(LActors[LActor]);
      end;
    LPool.Sort;
    SetLength(Result, LPool.Count);
    for LIndex := 0 to LPool.Count - 1 do
    begin
      Result[LIndex].Caption := LPool[LIndex];
      Result[LIndex].Tag := LIndex;
    end;
  finally
    LPool.Free;
  end;
end;

end.
