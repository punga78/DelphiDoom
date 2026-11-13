{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - parity with the real C++     }
{                                                                              }
{  Runs Tests\Data\Decl\decl.input.txt with TDeclManager and compares the      }
{  output with decl.golden.txt, which is what the real DeclManager.cpp,        }
{  DeclTable.cpp, DeclSkin.cpp, DeclEntityDef.cpp and DeclPDA.cpp of Doom 3    }
{  printed for the same file (see Tests\Data\Decl\README.md).                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Golden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Types, DelphiDoom.Tests.Decl.Support;

type
  /// <summary>
  ///   The interpreter of the cases: the same operations and the same output lines as the driver of the
  ///   C++ harness, on the classes of Libs\Decl
  /// </summary>
  TDeclGoldenRunner = class
  strict private
    FKit: TDeclKit;
    procedure Emit(const ALine: string);
    function Esc(const AText: AnsiString): string;
    function TypeOf(const AName: string): Integer;
    procedure DumpDecl(const ADecl: IDecl; const ADeep: Boolean);
    procedure Execute(const AOperation: string);
    class function UnescapeOp(const AText: string): AnsiString; static;
    class function Words(const AText: string): TArray<string>; static;
  public
    /// <summary>Runs every case of the text and returns the output lines</summary>
    function RunAll(const AInput: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclGolden = class
  strict private
    function DataFolder: string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroDeclManager;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, DelphiDoom.Scanner.IdDict, DelphiDoom.Decl.Skin, DelphiDoom.Decl.Table,
  DelphiDoom.Decl.EntityDef, DelphiDoom.Decl.Pda, DelphiDoom.Decl.Email, DelphiDoom.Decl.Video,
  DelphiDoom.Decl.Audio, DelphiDoom.Decl.Base, DelphiDoom.Tests.Scanner.IdFakes;

{ TDeclGoldenRunner }

procedure TDeclGoldenRunner.Emit(const ALine: string);
begin
  FKit.Lines.Add(ALine);
end;

function TDeclGoldenRunner.Esc(const AText: AnsiString): string;
begin
  Result := TFakeIdLibLog.Escape(AText);
end;

function TDeclGoldenRunner.TypeOf(const AName: string): Integer;
begin
  Result := FKit.Manager.GetRegistry.GetDeclTypeFromName(AnsiString(AName));
end;

class function TDeclGoldenRunner.Words(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(AText);
    for LIndex := LList.Count - 1 downto 0 do
      if LList[LIndex] = '' then
        LList.Delete(LIndex);
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

class function TDeclGoldenRunner.UnescapeOp(const AText: string): AnsiString;
var
  LIndex: Integer;
  LText: string;
begin
  LText := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) and (AText[LIndex + 1] = 'n') then
    begin
      LText := LText + #10;
      Inc(LIndex, 2);
    end
    else if (AText[LIndex] = '\') and (LIndex < Length(AText)) and (AText[LIndex + 1] = 't') then
    begin
      LText := LText + #9;
      Inc(LIndex, 2);
    end
    else
    begin
      LText := LText + AText[LIndex];
      Inc(LIndex);
    end;
  end;
  Result := AnsiString(LText);
end;

procedure TDeclGoldenRunner.DumpDecl(const ADecl: IDecl; const ADeep: Boolean);
const
  SAMPLES: array[0..10] of Single = (-1.3, -0.25, 0.0, 0.1, 0.25, 0.5, 0.75, 0.99, 1.0, 1.5, 2.7);
var
  LType, LIndex, LCount: Integer;
  LFormat: TFormatSettings;
  LText: string;
  LTable: IDeclTable;
  LSkin: IDeclSkin;
  LEntity: IDeclEntityDef;
  LPda: IDeclPda;
  LEmail: IDeclEmail;
  LVideo: IDeclVideo;
  LAudio: IDeclAudio;
  LKeyValue: TIdKeyValue;
  LOther: IDecl;
  LRemap: IDecl;
  LName: string;
begin
  LFormat := TFormatSettings.Invariant;
  LType := ADecl.GetDeclType;
  Emit(Format('D %s %s state=%d implicit=%d valid=%d file=%s line=%d index=%d textlen=%d ever=%d',
    [string(FKit.Manager.GetRegistry.GetDeclNameFromType(LType)), Esc(ADecl.GetName), Ord(ADecl.GetState),
    Ord(ADecl.IsImplicit), Ord(ADecl.IsValid), Esc(ADecl.GetFileName), ADecl.GetLineNum, ADecl.GetIndex,
    ADecl.GetTextLength, Ord(ADecl.EverReferenced)]));
  if ADecl.GetTextLength > 0 then
    Emit('  text=' + Esc(ADecl.GetText));
  if not ADeep then
    Exit;

  if Supports(ADecl, IDeclTable, LTable) then
  begin
    LText := '  lookup';
    for LIndex := 0 to High(SAMPLES) do
      LText := LText + ' ' + Format('%.4f', [LTable.TableLookup(SAMPLES[LIndex])], LFormat);
    Emit(LText);
  end
  else if Supports(ADecl, IDeclSkin, LSkin) then
  begin
    LText := Format('  models=%d', [LSkin.GetNumModelAssociations]);
    for LIndex := 0 to LSkin.GetNumModelAssociations - 1 do
      LText := LText + ' [' + Esc(LSkin.GetAssociatedModel(LIndex)) + ']';
    Emit(LText + ' outofrange=[' + Esc(LSkin.GetAssociatedModel(LSkin.GetNumModelAssociations)) + ']');
    LCount := FKit.Manager.GetNumDecls(DECL_MATERIAL);
    for LIndex := 0 to LCount - 1 do
    begin
      LOther := FKit.Manager.DeclByIndex(DECL_MATERIAL, LIndex, False);
      LRemap := LSkin.RemapShaderBySkin(LOther, True);
      if Assigned(LRemap) then
        LName := Esc(LRemap.GetName)
      else
        LName := 'null';
      Emit(Format('  remap %s -> %s', [Esc(LOther.GetName), LName]));
    end;
  end
  else if Supports(ADecl, IDeclEntityDef, LEntity) then
  begin
    Emit(Format('  keys=%d', [LEntity.GetDict.GetNumKeyVals]));
    for LIndex := 0 to LEntity.GetDict.GetNumKeyVals - 1 do
    begin
      LEntity.GetDict.TryGetKeyVal(LIndex, LKeyValue);
      Emit(Format('  %s = %s', [Esc(LKeyValue.Key), Esc(LKeyValue.Value)]));
    end;
  end
  else if Supports(ADecl, IDeclPda, LPda) then
  begin
    Emit(Format('  name=[%s] full=[%s] icon=[%s] id=[%s] post=[%s] title=[%s] security=[%s]',
      [Esc(LPda.GetPdaName), Esc(LPda.GetFullName), Esc(LPda.GetIcon), Esc(LPda.GetID), Esc(LPda.GetPost),
      Esc(LPda.GetTitle), Esc(LPda.GetSecurity)]));
    Emit(Format('  emails=%d videos=%d audios=%d', [LPda.GetNumEmails, LPda.GetNumVideos, LPda.GetNumAudios]));
    for LIndex := 0 to LPda.GetNumEmails - 1 do
    begin
      LOther := LPda.GetEmailByIndex(LIndex);
      if Assigned(LOther) then LName := Esc(LOther.GetName) else LName := 'null';
      Emit(Format('  email %d %s', [LIndex, LName]));
    end;
    for LIndex := 0 to LPda.GetNumVideos - 1 do
    begin
      LOther := LPda.GetVideoByIndex(LIndex);
      if Assigned(LOther) then LName := Esc(LOther.GetName) else LName := 'null';
      Emit(Format('  video %d %s', [LIndex, LName]));
    end;
    for LIndex := 0 to LPda.GetNumAudios - 1 do
    begin
      LOther := LPda.GetAudioByIndex(LIndex);
      if Assigned(LOther) then LName := Esc(LOther.GetName) else LName := 'null';
      Emit(Format('  audio %d %s', [LIndex, LName]));
    end;
  end
  else if Supports(ADecl, IDeclEmail, LEmail) then
    Emit(Format('  from=[%s] to=[%s] subject=[%s] date=[%s] image=[%s] body=[%s]',
      [Esc(LEmail.GetFrom), Esc(LEmail.GetTo), Esc(LEmail.GetSubject), Esc(LEmail.GetDate), Esc(LEmail.GetImage),
      Esc(LEmail.GetBody)]))
  else if Supports(ADecl, IDeclVideo, LVideo) then
    Emit(Format('  name=[%s] preview=[%s] roq=[%s] info=[%s] wave=[%s]',
      [Esc(LVideo.GetVideoName), Esc(LVideo.GetPreview), Esc(LVideo.GetRoq), Esc(LVideo.GetInfo),
      Esc(LVideo.GetWave)]))
  else if Supports(ADecl, IDeclAudio, LAudio) then
    Emit(Format('  name=[%s] wave=[%s] info=[%s] preview=[%s]',
      [Esc(LAudio.GetAudioName), Esc(LAudio.GetWave), Esc(LAudio.GetInfo), Esc(LAudio.GetPreview)]));
end;

procedure TDeclGoldenRunner.Execute(const AOperation: string);
var
  LCommand, LArgument: string;
  LSpace, LIndex, LCount, LType: Integer;
  LWords: TArray<string>;
  LDecl: IDecl;
  LText: AnsiString;
  LTime: Int64;
  LPda: IDeclPda;
  LMode: TDeclListMode;
begin
  LCommand := AOperation;
  LArgument := '';
  LSpace := Pos(' ', AOperation);
  if LSpace > 0 then
  begin
    LCommand := Copy(AOperation, 1, LSpace - 1);
    LArgument := Copy(AOperation, LSpace + 1, MaxInt);
  end;
  LWords := Words(LArgument);
  Emit('> ' + AOperation);
  try
    if LCommand = 'folder' then
    begin
      if LWords[2] = 'none' then
        LType := DECL_MAX_TYPES
      else
        LType := TypeOf(LWords[2]);
      FKit.Manager.GetRegistry.RegisterDeclFolder(AnsiString(LWords[0]), AnsiString(LWords[1]), LType);
    end
    else if LCommand = 'find' then
    begin
      if Length(LWords) > 1 then
        LDecl := FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), True)
      else
        LDecl := FKit.Manager.FindType(TypeOf(LWords[0]), '', True);
      Emit('r=' + IfThen(Assigned(LDecl), 'found', 'null'));
    end
    else if LCommand = 'findnd' then
    begin
      LDecl := FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False);
      Emit('r=' + IfThen(Assigned(LDecl), 'found', 'null'));
    end
    else if (LCommand = 'dump') or (LCommand = 'dumpraw') then
    begin
      LType := TypeOf(LWords[0]);
      LCount := FKit.Manager.GetNumDecls(LType);
      Emit(Format('n=%d', [LCount]));
      for LIndex := 0 to LCount - 1 do
        DumpDecl(FKit.Manager.DeclByIndex(LType, LIndex, LCommand = 'dump'), LCommand = 'dump');
    end
    else if LCommand = 'write' then
      FKit.Source.WriteFile(AnsiString(LWords[0]), UnescapeOp(Copy(LArgument, Pos(' ', LArgument) + 1, MaxInt)))
    else if LCommand = 'remove' then
      FKit.Source.Remove(AnsiString(LWords[0]))
    else if LCommand = 'reload' then
      FKit.Manager.Reload((Length(LWords) > 0) and (LWords[0] = 'all'))
    else if LCommand = 'reloadfile' then
      FKit.Manager.ReloadFile(AnsiString(LWords[0]), Length(LWords) > 1)
    else if LCommand = 'levelbegin' then
      FKit.Manager.BeginLevelLoad
    else if LCommand = 'levelend' then
      FKit.Manager.EndLevelLoad
    else if LCommand = 'checksum' then
      Emit(Format('checksum=%d', [FKit.Manager.GetChecksum]))
    else if LCommand = 'regtype' then
      FKit.Manager.GetRegistry.RegisterDeclType(AnsiString(LWords[0]), StrToInt(LWords[1]),
        function: IDecl begin Result := TDecl.Create; end)
    else if LCommand = 'typename' then
      Emit('r=' + string(FKit.Manager.GetRegistry.GetDeclNameFromType(TypeOf(LWords[0]))))
    else if LCommand = 'typenum' then
      Emit(Format('r=%d', [TypeOf(LWords[0])]))
    else if LCommand = 'numtypes' then
      Emit(Format('r=%d', [FKit.Manager.GetRegistry.GetNumDeclTypes]))
    else if LCommand = 'numdecls' then
      Emit(Format('r=%d', [FKit.Manager.GetNumDecls(TypeOf(LWords[0]))]))
    else if LCommand = 'invalidate' then
      FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False).Invalidate
    else if LCommand = 'ensure' then
      FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False).EnsureNotPurged
    else if LCommand = 'settext' then
    begin
      LDecl := FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False);
      LSpace := Pos(' ', LArgument);
      LSpace := Pos(' ', Copy(LArgument, LSpace + 1, MaxInt)) + LSpace;
      LDecl.SetText(UnescapeOp(Copy(LArgument, LSpace + 1, MaxInt)));
    end
    else if LCommand = 'replace' then
      Emit(Format('r=%d', [Ord(FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False)
        .ReplaceSourceFileText)]))
    else if LCommand = 'changed' then
      Emit(Format('r=%d', [Ord(FKit.Manager.FindType(TypeOf(LWords[0]), AnsiString(LWords[1]), False)
        .SourceFileChanged)]))
    else if LCommand = 'showfile' then
    begin
      if FKit.Source.TryReadFile(AnsiString(LWords[0]), LText, LTime) then
        Emit('file=' + Esc(LText))
      else
        Emit('file=missing');
    end
    else if LCommand = 'new' then
    begin
      LDecl := FKit.Manager.CreateNewDecl(TypeOf(LWords[0]), AnsiString(LWords[1]), AnsiString(LWords[2]));
      Emit(Format('name=%s file=%s state=%d index=%d', [Esc(LDecl.GetName), Esc(LDecl.GetFileName),
        Ord(LDecl.GetState), LDecl.GetIndex]));
    end
    else if LCommand = 'rename' then
      Emit(Format('r=%d', [Ord(FKit.Manager.RenameDecl(TypeOf(LWords[0]), AnsiString(LWords[1]),
        AnsiString(LWords[2])))]))
    else if LCommand = 'list' then
    begin
      LMode := dlmCurrent;
      if (Length(LWords) > 1) and (LWords[1] = 'all') then
        LMode := dlmAll
      else if (Length(LWords) > 1) and (LWords[1] = 'ever') then
        LMode := dlmEver;
      FKit.Manager.ListType(TypeOf(LWords[0]), LMode);
    end
    else if LCommand = 'print' then
      FKit.Manager.PrintType(TypeOf(LWords[0]), AnsiString(LWords[1]))
    else if LCommand = 'precache' then
      Emit('precache=' + Esc(FKit.Manager.WritePrecacheCommands))
    else if LCommand = 'pda' then
    begin
      Supports(FKit.Manager.FindType(DECL_PDA, AnsiString(LWords[0]), False), IDeclPda, LPda);
      if LWords[1] = 'addemail' then
        LPda.AddEmail(AnsiString(LWords[2]), Length(LWords) < 4)
      else if LWords[1] = 'addvideo' then
        LPda.AddVideo(AnsiString(LWords[2]), Length(LWords) < 4)
      else if LWords[1] = 'addaudio' then
        LPda.AddAudio(AnsiString(LWords[2]), Length(LWords) < 4)
      else if LWords[1] = 'remove' then
        LPda.RemoveAddedEmailsAndVideos
      else if LWords[1] = 'security' then
        LPda.SetSecurity(AnsiString(LWords[2]));
      Emit(Format('emails=%d videos=%d audios=%d security=[%s]',
        [LPda.GetNumEmails, LPda.GetNumVideos, LPda.GetNumAudios, Esc(LPda.GetSecurity)]));
    end
    else
      Emit('unknown op');
  except
    on LError: EDeclException do
      Emit('ERR ' + Esc(AnsiString(LError.Message)));
  end;
end;

function TDeclGoldenRunner.RunAll(const AInput: TStrings): TStringList;
var
  LIndex, LFileCount: Integer;
  LLine, LCurrentFile: string;
  LOperations: TStringList;
  LFiles: TDictionary<string, string>;
  LFileOrder: TStringList;
  LPair: TPair<string, string>;
  LName: string;
begin
  Result := TStringList.Create;
  LOperations := TStringList.Create;
  LFiles := TDictionary<string, string>.Create;
  LFileOrder := TStringList.Create;
  try
    LIndex := 0;
    while LIndex < AInput.Count do
    begin
      if Copy(AInput[LIndex], 1, 6) <> '@case ' then
      begin
        Inc(LIndex);
        Continue;
      end;
      LName := Copy(AInput[LIndex], 7, MaxInt);
      Inc(LIndex);
      LOperations.Clear;
      LFiles.Clear;
      LFileOrder.Clear;
      LCurrentFile := '';
      while (LIndex < AInput.Count) and (AInput[LIndex] <> '@end') do
      begin
        LLine := AInput[LIndex];
        if Copy(LLine, 1, 4) = '@op ' then
        begin
          LOperations.Add(Copy(LLine, 5, MaxInt));
          LCurrentFile := '';
        end
        else if Copy(LLine, 1, 6) = '@file ' then
        begin
          LCurrentFile := LowerCase(Copy(LLine, 7, MaxInt));
          LFiles.AddOrSetValue(LCurrentFile, '');
          LFileOrder.Add(LCurrentFile);
        end
        else if LCurrentFile <> '' then
          LFiles[LCurrentFile] := LFiles[LCurrentFile] + LLine + #10;
        Inc(LIndex);
      end;
      Inc(LIndex);

      FKit := TDeclKit.Create;
      try
        for LFileCount := 0 to LFileOrder.Count - 1 do
          FKit.Source.Add(AnsiString(LFileOrder[LFileCount]), AnsiString(LFiles[LFileOrder[LFileCount]]));
        FKit.Start(True, True);
        FKit.Lines.Insert(0, '## ' + LName);
        for LFileCount := 0 to LOperations.Count - 1 do
          Execute(LOperations[LFileCount]);
        Result.AddStrings(FKit.Lines);
      finally
        FreeAndNil(FKit);
      end;
    end;
  finally
    LFileOrder.Free;
    LFiles.Free;
    LOperations.Free;
  end;
end;

{ TTestDeclGolden }

function TTestDeclGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Decl\');
end;

procedure TTestDeclGolden.DovrebbeDareLeStesseRisposteDelVeroDeclManager;
var
  LInput, LGolden, LActual: TStringList;
  LRunner: TDeclGoldenRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TDeclGoldenRunner.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'decl.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'decl.golden.txt', TEncoding.ANSI);
    LActual := LRunner.RunAll(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LActual[LIndex] <> LGolden[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.decl.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclGolden);

end.
