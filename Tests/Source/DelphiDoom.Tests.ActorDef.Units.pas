{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ActorDef library - the small classes               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.Units;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Recorder, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf;

type
  TRecordingListener = class(TInterfacedObject, IActorDefSoundInfoListener)
  public
    Songs: TStringList;
    Names: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure SongForMap(AMapId: Integer; const ASongName: string);
    procedure AliasDeclared(const AName, AValue: string);
  end;

  [TestFixture]
  [Category('actordef')]
  TTestActorDefUnits = class(TObject)
  private
    FRecorder: TLogRecorder;
    FRecorderSink: ILogSink;
    FLog: ILog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAFlagWithoutTheMfPrefixIsNotTakenOff;
    [Test]
    procedure TestAFlagWithThePrefixIsTakenOffAndTheWordsGoToUpperCase;
    [Test]
    procedure TestTheMf2PrefixCountsOnlyInTheGamesWithFlags2;
    [Test]
    procedure TestALabelIsMatchedWithOrWithoutAnOffset;
    [Test]
    procedure TestALabelFollowedByAnotherLetterIsNotTheLabel;
    [Test]
    procedure TestIsIntegerWantsOnlyDigitsAndAMinus;
    [Test]
    procedure TestFirstAndLastWord;
    [Test]
    procedure TestEachGameHasItsProfile;
    [Test]
    procedure TestTheGamesAreFoundByName;
    [Test]
    procedure TestASoundWithAnAliasGivesTheLump;
    [Test]
    procedure TestASoundThatIsTooLongOrHasNoAliasGivesZero;
    [Test]
    procedure TestRandomTakesTheSecondWord;
    [Test]
    procedure TestSndinfoHasOneAliasForEachLine;
    [Test]
    procedure TestAnEqualsSignBetweenTheWordsIsKept;
    [Test]
    procedure TestSndinfoDropsTheCommentsAndTheLinesWithoutValue;
    [Test]
    procedure TestHexenSndinfoGivesTheSongsAndTheNamesToTheListener;
    [Test]
    procedure TestOtherGamesReadMapAsAnAlias;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.ActorDef.FlagEditor,
  DelphiDoom.ActorDef.LabelMatcher, DelphiDoom.ActorDef.Text, DelphiDoom.ActorDef.Profiles,
  DelphiDoom.ActorDef.Factory;

{ TRecordingListener }

constructor TRecordingListener.Create;
begin
  inherited Create;
  Songs := TStringList.Create;
  Names := TStringList.Create;
end;

destructor TRecordingListener.Destroy;
begin
  Names.Free;
  Songs.Free;
  inherited Destroy;
end;

procedure TRecordingListener.SongForMap(AMapId: Integer; const ASongName: string);
begin
  Songs.Add(IntToStr(AMapId) + '=' + ASongName);
end;

procedure TRecordingListener.AliasDeclared(const AName, AValue: string);
begin
  Names.Add(AName + '=' + AValue);
end;

{ TTestActorDefUnits }

procedure TTestActorDefUnits.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FRecorderSink := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderSink), nil);
end;

procedure TTestActorDefUnits.TearDown;
begin
  FLog := nil;
  FRecorderSink := nil;
end;

procedure TTestActorDefUnits.TestAFlagWithoutTheMfPrefixIsNotTakenOff;
begin
  // the old rule: a word that starts with M goes only with a prefix; a word without prefix stays
  Assert.AreEqual('SOLID MISSILE ', TActorDefFlagEditor.Remove('SOLID MISSILE ', 'MISSILE', False, FLog));
  Assert.AreEqual('SOLID MISSILE ', TActorDefFlagEditor.Remove('SOLID MISSILE ', 'SOLID', False, FLog));
end;

procedure TTestActorDefUnits.TestAFlagWithThePrefixIsTakenOffAndTheWordsGoToUpperCase;
begin
  Assert.AreEqual('MF_SHOOTABLE ', TActorDefFlagEditor.Remove('mf_solid MF_SHOOTABLE ', 'SOLID', False, FLog));
  Assert.AreEqual('MF_SOLID ', TActorDefFlagEditor.Remove('MF_SOLID MF_EX_FLOATBOB ', 'FLOATBOB', False, FLog));
  Assert.AreEqual('MF_SOLID ', TActorDefFlagEditor.Remove('MF_SOLID MF3_EX_NOCRUSH ', 'MF3_EX_NOCRUSH', False, FLog));
  Assert.AreEqual('A B ', TActorDefFlagEditor.Remove('A B ', '', False, FLog) + '', 'no flag: the list as it was');
end;

procedure TTestActorDefUnits.TestTheMf2PrefixCountsOnlyInTheGamesWithFlags2;
begin
  Assert.AreEqual('', TActorDefFlagEditor.Remove('MF2_FLY ', 'MF2_FLY', True, FLog));
  Assert.AreEqual('MF2_FLY ', TActorDefFlagEditor.Remove('MF2_FLY ', 'MF2_FLY', False, FLog));
end;

procedure TTestActorDefUnits.TestALabelIsMatchedWithOrWithoutAnOffset;
var
  LOffset: Integer;
begin
  Assert.IsTrue(TActorDefLabelMatcher.Match('SPAWN', 'SPAWN', LOffset));
  Assert.AreEqual(0, LOffset);
  Assert.IsTrue(TActorDefLabelMatcher.Match('SPAWN + 2', 'SPAWN', LOffset));
  Assert.AreEqual(2, LOffset);
  Assert.IsTrue(TActorDefLabelMatcher.Match('SPAWN-1', 'SPAWN', LOffset));
  Assert.AreEqual(-1, LOffset);
  Assert.IsTrue(TActorDefLabelMatcher.Match('SEE+0X10', 'SEE', LOffset), 'a number as the other parts read it');
end;

procedure TTestActorDefUnits.TestALabelFollowedByAnotherLetterIsNotTheLabel;
var
  LOffset: Integer;
begin
  Assert.IsFalse(TActorDefLabelMatcher.Match('SEEKER', 'SEE', LOffset));
  Assert.IsFalse(TActorDefLabelMatcher.Match('DEATH', 'SPAWN', LOffset));
  Assert.IsFalse(TActorDefLabelMatcher.Match('', 'SPAWN', LOffset));
end;

procedure TTestActorDefUnits.TestIsIntegerWantsOnlyDigitsAndAMinus;
begin
  Assert.IsTrue(TActorDefText.IsInteger('123'));
  Assert.IsTrue(TActorDefText.IsInteger('-5'));
  Assert.IsFalse(TActorDefText.IsInteger(''));
  Assert.IsFalse(TActorDefText.IsInteger('-'));
  Assert.IsFalse(TActorDefText.IsInteger('+5'));
  Assert.IsFalse(TActorDefText.IsInteger('0x10'));
  Assert.IsFalse(TActorDefText.IsInteger('1.5'));
end;

procedure TTestActorDefUnits.TestFirstAndLastWord;
begin
  Assert.AreEqual('A', TActorDefText.FirstWord('A B C'));
  Assert.AreEqual('C', TActorDefText.LastWord('A B C'));
  Assert.AreEqual('ABC', TActorDefText.FirstWord('ABC'));
  Assert.AreEqual('ABC', TActorDefText.LastWord('ABC'));
  Assert.AreEqual('', TActorDefText.LastWord('A B '));
  Assert.AreEqual('AB', TActorDefText.RemoveSpaces(' A  B '));
end;

procedure TTestActorDefUnits.TestEachGameHasItsProfile;
var
  LProfile: TActorDefProfile;
begin
  LProfile := TActorDefProfiles.ForGame(TActorDefGame.Doom);
  Assert.IsFalse(LProfile.HasFlags2 or LProfile.HasStrifeName or LProfile.WeaponHasLevel);
  Assert.IsTrue(LProfile.WeaponStatesWriteFlagsEx);
  LProfile := TActorDefProfiles.ForGame(TActorDefGame.Heretic);
  Assert.IsTrue(LProfile.HasFlags2);
  Assert.IsTrue(LProfile.WeaponHasLevel);
  Assert.AreEqual(1, LProfile.WeaponDefaultLevel);
  Assert.IsFalse(LProfile.KeywordsUseFlags2);
  LProfile := TActorDefProfiles.ForGame(TActorDefGame.Hexen);
  Assert.IsTrue(LProfile.HasFlags2 and LProfile.KeywordsUseFlags2 and LProfile.WeaponHasPlayerClass);
  Assert.IsTrue(LProfile.SoundInfoHexenExtensions);
  LProfile := TActorDefProfiles.ForGame(TActorDefGame.Strife);
  Assert.IsTrue(LProfile.HasStrifeName);
  Assert.IsFalse(LProfile.WeaponStatesWriteFlagsEx);
  Assert.IsFalse(LProfile.SoundInfoHexenExtensions);
end;

procedure TTestActorDefUnits.TestTheGamesAreFoundByName;
var
  LGame: TActorDefGame;
begin
  Assert.IsTrue(TActorDefProfiles.TryFromName('hexen', LGame));
  Assert.AreEqual(Ord(TActorDefGame.Hexen), Ord(LGame));
  Assert.IsFalse(TActorDefProfiles.TryFromName('quake', LGame));
  Assert.AreEqual('STRIFE', TActorDefProfiles.NameOf(TActorDefGame.Strife));
end;

procedure TTestActorDefUnits.TestASoundWithAnAliasGivesTheLump;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  LAliases.Add('IMP/SIGHT', 'DSBGSIT1');
  LAliases.Add('CHAIN/ONE', 'CHAIN/TWO');
  LAliases.Add('CHAIN/TWO', 'DSCHAIN');
  Assert.AreEqual('DSBGSIT1', LAliases.Resolve('imp\sight'));
  Assert.AreEqual('DSCHAIN', LAliases.Resolve('chain/one'), 'an alias of an alias');
  Assert.AreEqual('dsplasma', LAliases.Resolve('dsplasma'), 'a lump name that is not an alias stays as written');
  Assert.AreEqual('0', LAliases.Resolve(''));
end;

procedure TTestActorDefUnits.TestASoundThatIsTooLongOrHasNoAliasGivesZero;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  LAliases.Add('LONG', 'DSTOOLONGNAME');
  Assert.AreEqual('0', LAliases.Resolve('some/sound'));
  Assert.AreEqual('0', LAliases.Resolve('abcdefghij'));
  Assert.AreEqual('0', LAliases.Resolve('long'));
  Assert.IsTrue(FRecorder.TextOf(TLogChannel.Output).Contains('does not have a corresponding alias'));
  Assert.IsTrue(FRecorder.TextOf(TLogChannel.Output).Contains('has length 10 > 8'));
  Assert.IsTrue(FRecorder.TextOf(TLogChannel.Output).Contains('has length 13 > 8'));
end;

procedure TTestActorDefUnits.TestRandomTakesTheSecondWord;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  LAliases.Add('PAIN', 'DSPAIN');
  Assert.AreEqual('DSPAIN', LAliases.Resolve('$random pain'));
  Assert.AreEqual('$random', LAliases.Resolve('$random'), 'no second word: the name as it is');
end;

procedure TTestActorDefUnits.TestSndinfoHasOneAliasForEachLine;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  TActorDefFactory.ParseSoundInfo(TActorDefProfiles.ForGame(TActorDefGame.Doom),
    'imp/sight dsimp'#13#10'imp/death dsimpd'#13#10'"quoted/name" dsq'#13#10, LAliases, nil);
  Assert.AreEqual<Integer>(3, Length(LAliases.Lines));
  Assert.AreEqual('IMP/SIGHT=DSIMP', LAliases.Lines[0]);
  Assert.AreEqual('IMP/DEATH=DSIMPD', LAliases.Lines[1]);
  Assert.AreEqual('QUOTED/NAME=DSQ', LAliases.Lines[2]);
end;

procedure TTestActorDefUnits.TestAnEqualsSignBetweenTheWordsIsKept;
var
  LAliases: IActorDefSoundAliasTable;
begin
  // the old splitter takes the first separator only: = and the space that follows make the value
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  TActorDefFactory.ParseSoundInfo(TActorDefProfiles.ForGame(TActorDefGame.Doom),
    'a/b = dsab'#13#10, LAliases, nil);
  Assert.AreEqual('A/B== DSAB', LAliases.Lines[0]);
end;

procedure TTestActorDefUnits.TestSndinfoDropsTheCommentsAndTheLinesWithoutValue;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  TActorDefFactory.ParseSoundInfo(TActorDefProfiles.ForGame(TActorDefGame.Doom),
    '// a comment'#13#10'alone'#13#10'a b ; trailing'#13#10'c d // trailing'#13#10#13#10, LAliases, nil);
  Assert.AreEqual<Integer>(2, Length(LAliases.Lines));
  Assert.AreEqual('A=B', LAliases.Lines[0]);
  Assert.AreEqual('C=D', LAliases.Lines[1]);
end;

procedure TTestActorDefUnits.TestHexenSndinfoGivesTheSongsAndTheNamesToTheListener;
var
  LAliases: IActorDefSoundAliasTable;
  LListener: TRecordingListener;
  LListenerRef: IActorDefSoundInfoListener;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  LListener := TRecordingListener.Create;
  LListenerRef := LListener;
  TActorDefFactory.ParseSoundInfo(TActorDefProfiles.ForGame(TActorDefGame.Hexen),
    '$map 1 song01'#13#10'$map 0 zero'#13#10'$map x bad'#13#10'$map 7'#13#10'tag1 lump1'#13#10, LAliases,
    LListenerRef);
  Assert.AreEqual(2, LListener.Songs.Count);
  Assert.AreEqual('1=SONG01', LListener.Songs[0]);
  Assert.AreEqual('7=', LListener.Songs[1], 'a map without a name gets an empty name, as in the old code');
  Assert.AreEqual(1, LListener.Names.Count);
  Assert.AreEqual('TAG1=LUMP1', LListener.Names[0]);
  Assert.AreEqual<Integer>(1, Length(LAliases.Lines), '$MAP lines are not aliases in Hexen');
end;

procedure TTestActorDefUnits.TestOtherGamesReadMapAsAnAlias;
var
  LAliases: IActorDefSoundAliasTable;
begin
  LAliases := TActorDefFactory.CreateSoundAliases(FLog);
  TActorDefFactory.ParseSoundInfo(TActorDefProfiles.ForGame(TActorDefGame.Doom),
    '$map 1 song01'#13#10, LAliases, nil);
  Assert.AreEqual<Integer>(1, Length(LAliases.Lines));
  Assert.AreEqual('$MAP=1 SONG01', LAliases.Lines[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefUnits);

end.
