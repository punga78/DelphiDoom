{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptEventQueue   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.EventQueue;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Support, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.ClassRegistry, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.Entities, DelphiDoom.DoomScript.SaveStream,
  DelphiDoom.DoomScript.EventQueue;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptEventQueue = class
  private
    FHost: TDoomScriptFakeHost;
    FHostIntf: IDoomScriptHost;
    FEvents: TDoomScriptEventRegistry;
    FClasses: TDoomScriptClassRegistry;
    FProgram: TDoomScriptProgram;
    FEntities: TDoomScriptEntityTable;
    FQueue: TDoomScriptEventQueue;
    FClass: TDoomScriptClassInfo;
    FDeafClass: TDoomScriptClassInfo;
    FTarget: TDoomScriptEventTarget;
    FOther: TDoomScriptEventTarget;
    FDeaf: TDoomScriptEventTarget;
    FCalls: TStringList;
    FStream: TMemoryStream;
    FEvInt: TDoomScriptEventDef;
    FEvNone: TDoomScriptEventDef;
    FEvEntity: TDoomScriptEventDef;
    FEvEntityNull: TDoomScriptEventDef;
    FEvString: TDoomScriptEventDef;
    FEvMixed: TDoomScriptEventDef;
    FEvTrace: TDoomScriptEventDef;
    FEvChain: TDoomScriptEventDef;
    FEvLoop: TDoomScriptEventDef;
    FEvUnhandled: TDoomScriptEventDef;
    function Recorder: TDoomScriptEventHandler;
    function Writer: TDoomScriptWriteObject;
    function Reader: TDoomScriptReadObject;
    procedure PostInt(const ATime, AValue: Integer);
    procedure WriteEventHeader(const ATime: Integer; const AEvent, AClass: AnsiString; const AObject,
      AArgSize: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeOrdinarePerTempoEPoiPerArrivo;
    [Test]
    procedure DovrebbeNonAccodareSeIlTargetNonRisponde;
    [Test]
    procedure DovrebbeRifiutareIlNumeroDiArgomentiSbagliato;
    [Test]
    procedure DovrebbeRifiutareIlTipoDiArgomentoSbagliato;
    [Test]
    procedure DovrebbeAccettareLoZeroInteroPerUnEntitaOUnaTraccia;
    [Test]
    procedure DovrebbeTroncareLaStringaA127Caratteri;
    [Test]
    procedure DovrebbeAnnullareGliEventiDiUnaDefinizione;
    [Test]
    procedure DovrebbeAnnullareTuttiGliEventiDiUnTarget;
    [Test]
    procedure DovrebbeConsegnareSoloGliEventiScaduti;
    [Test]
    procedure DovrebbeConsegnareNelloStessoGiroGliEventiAccodatiDaUnGestore;
    [Test]
    procedure DovrebbeFermareUnCicloInfinitoDiEventi;
    [Test]
    procedure DovrebbeRifiutareUnEventoSeLaCodaEPiena;
    [Test]
    procedure DovrebbeConsegnareLEntitaAncoraPresente;
    [Test]
    procedure DovrebbeConsegnareNessunaEntitaSeEStataRimossa;
    [Test]
    procedure DovrebbeConsegnareNessunaEntitaSeIlNumeroEDiUnAltra;
    [Test]
    procedure DovrebbeSopportareUnTargetCheSiLiberaNelGestore;
    [Test]
    procedure DovrebbeAccodareInSecondi;
    [Test]
    procedure DovrebbeSvuotareLaCoda;
    [Test]
    procedure DovrebbeSalvareERipristinareLaCoda;
    [Test]
    procedure DovrebbeNonSalvareLeStringhe;
    [Test]
    procedure DovrebbeRifiutareUnEventoSalvatoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnaClasseSalvataSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneDegliArgomentiDiversa;
    [Test]
    procedure DovrebbeRifiutareUnOggettoSalvatoNonValido;
    [Test]
    procedure DovrebbeRifiutareIlRipristinoSeLaCodaEPiena;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriIntervallo;
  end;

implementation

procedure TTestDoomScriptEventQueue.Setup;
begin
  FHost := TDoomScriptFakeHost.Create;
  FHostIntf := FHost;
  FCalls := TStringList.Create;
  FStream := TMemoryStream.Create;
  FEvents := TDoomScriptEventRegistry.Create;
  FClasses := TDoomScriptClassRegistry.Create;
  FProgram := TDoomScriptProgram.Create(FHostIntf, nil, nil);
  FEntities := TDoomScriptEntityTable.Create(FProgram);
  FQueue := TDoomScriptEventQueue.Create(FHostIntf, FEvents, FClasses, FEntities);
  FEvInt := FEvents.Define('int', 'd');
  FEvNone := FEvents.Define('none');
  FEvEntity := FEvents.Define('entity', 'e');
  FEvEntityNull := FEvents.Define('entitynull', 'E');
  FEvString := FEvents.Define('string', 's');
  FEvMixed := FEvents.Define('mixed', 'dfvsE');
  FEvTrace := FEvents.Define('trace', 't');
  FEvChain := FEvents.Define('chain');
  FEvLoop := FEvents.Define('loop');
  FEvUnhandled := FEvents.Define('unhandled');
  FClass := FClasses.Declare('listener');
  FDeafClass := FClasses.Declare('deaf');
  FClass.AddEvent(FEvInt, Recorder());
  FClass.AddEvent(FEvNone, Recorder());
  FClass.AddEvent(FEvEntity, Recorder());
  FClass.AddEvent(FEvEntityNull, Recorder());
  FClass.AddEvent(FEvString, Recorder());
  FClass.AddEvent(FEvMixed, Recorder());
  FClass.AddEvent(FEvTrace, Recorder());
  FClass.AddEvent(FEvChain,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      FCalls.Add('chain');
      // one that is due now and one for later
      FQueue.PostEventMS(TDoomScriptEventTarget(ATarget), FEvInt, 0, [TDoomScriptConvert.IntArg(100)]);
      FQueue.PostEventMS(TDoomScriptEventTarget(ATarget), FEvInt, 1, [TDoomScriptConvert.IntArg(200)]);
    end);
  FClass.AddEvent(FEvLoop,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      FCalls.Add('loop');
      FQueue.PostEventMS(TDoomScriptEventTarget(ATarget), FEvLoop, 0);
    end);
  FTarget := TDoomScriptEventTarget.Create(FClass);
  FOther := TDoomScriptEventTarget.Create(FClass);
  FDeaf := TDoomScriptEventTarget.Create(FDeafClass);
end;

procedure TTestDoomScriptEventQueue.TearDown;
begin
  FQueue.Free;
  FDeaf.Free;
  FOther.Free;
  FTarget.Free;
  FEntities.Free;
  FProgram.Free;
  FClasses.Free;
  FEvents.Free;
  FStream.Free;
  FCalls.Free;
  FHostIntf := nil;
end;

function TTestDoomScriptEventQueue.Recorder: TDoomScriptEventHandler;
begin
  Result :=
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LText: string;
      LIndex: Integer;
    begin
      LText := string(AEvent.Name);
      if ATarget = FOther then
        LText := 'other.' + LText;
      for LIndex := 0 to AEvent.GetNumArgs - 1 do
        case AArgs[LIndex].Kind of
          DS_EVENT_STRING:
            LText := LText + ' "' + string(AArgs[LIndex].StringValue) + '"';
          DS_EVENT_FLOAT:
            LText := LText + ' ' + IntToHex(PCardinal(@AArgs[LIndex].FloatValue)^, 8);
          DS_EVENT_VECTOR:
            LText := LText + Format(' (%d,%d,%d)', [Round(AArgs[LIndex].VectorValue.X),
              Round(AArgs[LIndex].VectorValue.Y), Round(AArgs[LIndex].VectorValue.Z)]);
        else
          LText := LText + ' ' + IntToStr(AArgs[LIndex].IntValue);
        end;
      FCalls.Add(LText);
    end;
end;

function TTestDoomScriptEventQueue.Writer: TDoomScriptWriteObject;
begin
  Result :=
    procedure(const AStream: TStream; const AObject: TObject)
    begin
      if AObject = FTarget then
        TDoomScriptSaveStream.WriteInt(AStream, 1)
      else if AObject = FOther then
        TDoomScriptSaveStream.WriteInt(AStream, 2)
      else
        TDoomScriptSaveStream.WriteInt(AStream, -1);
    end;
end;

function TTestDoomScriptEventQueue.Reader: TDoomScriptReadObject;
begin
  Result :=
    function(const AStream: TStream): TObject
    begin
      case TDoomScriptSaveStream.ReadInt(AStream) of
        1: Result := FTarget;
        2: Result := FOther;
        // not an event target
        3: Result := FCalls;
      else
        Result := nil;
      end;
    end;
end;

procedure TTestDoomScriptEventQueue.PostInt(const ATime, AValue: Integer);
begin
  Assert.IsTrue(FQueue.PostEventMS(FTarget, FEvInt, ATime, [TDoomScriptConvert.IntArg(AValue)]));
end;

procedure TTestDoomScriptEventQueue.WriteEventHeader(const ATime: Integer; const AEvent, AClass: AnsiString;
  const AObject, AArgSize: Integer);
begin
  FStream.Clear;
  TDoomScriptSaveStream.WriteInt(FStream, 1);
  TDoomScriptSaveStream.WriteInt(FStream, ATime);
  TDoomScriptSaveStream.WriteString(FStream, AEvent);
  TDoomScriptSaveStream.WriteString(FStream, AClass);
  TDoomScriptSaveStream.WriteInt(FStream, AObject);
  TDoomScriptSaveStream.WriteInt(FStream, AArgSize);
  TDoomScriptSaveStream.WriteInt(FStream, 77);
  FStream.Position := 0;
end;

procedure TTestDoomScriptEventQueue.DovrebbeOrdinarePerTempoEPoiPerArrivo;
begin
  FHost.Time := 1000;
  PostInt(10, 1);
  PostInt(5, 2);
  PostInt(10, 3);
  PostInt(5, 4);
  PostInt(0, 5);
  Assert.AreEqual(5, FQueue.Count);
  Assert.AreEqual(5, FQueue.GetEvent(0).Args[0].IntValue);
  Assert.AreEqual(2, FQueue.GetEvent(1).Args[0].IntValue);
  Assert.AreEqual(4, FQueue.GetEvent(2).Args[0].IntValue);
  Assert.AreEqual(1, FQueue.GetEvent(3).Args[0].IntValue);
  Assert.AreEqual(3, FQueue.GetEvent(4).Args[0].IntValue);
  // the time is the one of the host plus the delay
  Assert.AreEqual(1000, FQueue.GetEvent(0).Time);
  Assert.AreEqual(1010, FQueue.GetEvent(4).Time);
  Assert.AreSame(FTarget, FQueue.GetEvent(0).Target);
  Assert.AreSame(FClass, FQueue.GetEvent(0).TargetClass);
  Assert.AreSame(FEvInt, FQueue.GetEvent(0).EventDef);
  FHost.Time := 1010;
  FQueue.ServiceEvents;
  Assert.AreEqual('int 5,int 2,int 4,int 1,int 3', FCalls.CommaText.Replace('"', ''));
end;

procedure TTestDoomScriptEventQueue.DovrebbeNonAccodareSeIlTargetNonRisponde;
begin
  Assert.IsFalse(FQueue.PostEventMS(FDeaf, FEvNone, 0));
  Assert.IsFalse(FQueue.PostEventMS(FTarget, FEvUnhandled, 0));
  // the arguments are not even looked at
  Assert.IsFalse(FQueue.PostEventMS(FDeaf, FEvInt, 0, []));
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareIlNumeroDiArgomentiSbagliato;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvInt, 0);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong number of args for ''int'' event.');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvNone, 0, [TDoomScriptConvert.IntArg(1)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong number of args for ''none'' event.');
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareIlTipoDiArgomentoSbagliato;
var
  LFloat: Single;
begin
  LFloat := 1;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvInt, 0, [TDoomScriptConvert.FloatArg(LFloat)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong type passed in for arg # 0 on ''int'' event.');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvMixed, 0, [TDoomScriptConvert.IntArg(1), TDoomScriptConvert.FloatArg(LFloat),
        TDoomScriptConvert.IntArg(3), TDoomScriptConvert.StringArg('s'), TDoomScriptConvert.EntityArg(0)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong type passed in for arg # 2 on ''mixed'' event.');
  // an integer that is not zero is not "no entity"
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.IntArg(5)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong type passed in for arg # 0 on ''entity'' event.');
  // as in the original the exception is not made for 'E'
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvEntityNull, 0, [TDoomScriptConvert.IntArg(0)]);
    end, EDoomScriptError, 'idEvent::Alloc : Wrong type passed in for arg # 0 on ''entitynull'' event.');
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeAccettareLoZeroInteroPerUnEntitaOUnaTraccia;
begin
  Assert.IsTrue(FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.IntArg(0)]));
  Assert.IsTrue(FQueue.PostEventMS(FTarget, FEvTrace, 0, [TDoomScriptConvert.IntArg(0)]));
  Assert.AreEqual(2, FQueue.Count);
  // NULL: no entity, not the entity number zero
  Assert.AreEqual(-1, FQueue.GetEvent(0).Args[0].IntValue);
  Assert.IsTrue(FQueue.GetEvent(0).Args[0].Kind = DS_EVENT_ENTITY);
  Assert.IsTrue(FQueue.GetEvent(1).Args[0].Kind = DS_EVENT_TRACE);
  FQueue.ServiceEvents;
  Assert.AreEqual('entity -1', FCalls[0]);
  Assert.AreEqual('trace 0', FCalls[1]);
end;

procedure TTestDoomScriptEventQueue.DovrebbeTroncareLaStringaA127Caratteri;
var
  LText: AnsiString;
begin
  LText := StringOfChar(AnsiChar('x'), 300);
  FQueue.PostEventMS(FTarget, FEvString, 0, [TDoomScriptConvert.StringArg(LText)]);
  Assert.AreEqual<Integer>(DS_MAX_STRING_LEN - 1, Length(FQueue.GetEvent(0).Args[0].StringValue));
  FQueue.PostEventMS(FTarget, FEvString, 0, [TDoomScriptConvert.StringArg('short')]);
  Assert.AreEqual('short', string(FQueue.GetEvent(1).Args[0].StringValue));
end;

procedure TTestDoomScriptEventQueue.DovrebbeAnnullareGliEventiDiUnaDefinizione;
begin
  PostInt(0, 1);
  FQueue.PostEventMS(FTarget, FEvNone, 0);
  PostInt(5, 2);
  FQueue.PostEventMS(FOther, FEvInt, 0, [TDoomScriptConvert.IntArg(3)]);
  FQueue.CancelEvents(FTarget, FEvInt);
  Assert.AreEqual(2, FQueue.Count);
  Assert.AreSame(FEvNone, FQueue.GetEvent(0).EventDef);
  Assert.AreSame(FOther, FQueue.GetEvent(1).Target);
  // nothing to cancel is not an error
  FQueue.CancelEvents(FDeaf, FEvInt);
  Assert.AreEqual(2, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeAnnullareTuttiGliEventiDiUnTarget;
begin
  PostInt(0, 1);
  FQueue.PostEventMS(FTarget, FEvNone, 0);
  FQueue.PostEventMS(FOther, FEvInt, 0, [TDoomScriptConvert.IntArg(3)]);
  FQueue.CancelEvents(FTarget);
  Assert.AreEqual(1, FQueue.Count);
  Assert.AreSame(FOther, FQueue.GetEvent(0).Target);
  FQueue.ServiceEvents;
  Assert.AreEqual('other.int 3', FCalls.Text.Trim);
end;

procedure TTestDoomScriptEventQueue.DovrebbeConsegnareSoloGliEventiScaduti;
begin
  FHost.Time := 100;
  PostInt(0, 1);
  PostInt(16, 2);
  PostInt(32, 3);
  FQueue.ServiceEvents;
  Assert.AreEqual(1, FCalls.Count);
  Assert.AreEqual(2, FQueue.Count);
  FHost.Time := 115;
  FQueue.ServiceEvents;
  Assert.AreEqual(1, FCalls.Count);
  FHost.Time := 116;
  FQueue.ServiceEvents;
  Assert.AreEqual(2, FCalls.Count);
  Assert.AreEqual('int 2', FCalls[1]);
  FHost.Time := 1000;
  FQueue.ServiceEvents;
  Assert.AreEqual(3, FCalls.Count);
  Assert.AreEqual(0, FQueue.Count);
  // an empty queue is fine
  FQueue.ServiceEvents;
  Assert.AreEqual(3, FCalls.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeConsegnareNelloStessoGiroGliEventiAccodatiDaUnGestore;
begin
  FQueue.PostEventMS(FTarget, FEvChain, 0);
  PostInt(0, 1);
  FQueue.ServiceEvents;
  // the one for later stays; the one for now goes after what was already waiting
  Assert.AreEqual(3, FCalls.Count);
  Assert.AreEqual('chain', FCalls[0]);
  Assert.AreEqual('int 1', FCalls[1]);
  Assert.AreEqual('int 100', FCalls[2]);
  Assert.AreEqual(1, FQueue.Count);
  Assert.AreEqual(200, FQueue.GetEvent(0).Args[0].IntValue);
end;

procedure TTestDoomScriptEventQueue.DovrebbeFermareUnCicloInfinitoDiEventi;
begin
  FQueue.PostEventMS(FTarget, FEvLoop, 0);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.ServiceEvents;
    end, EDoomScriptError, 'Event overflow.  Possible infinite loop in script.');
  Assert.AreEqual(DS_MAX_EVENTSPERFRAME + 1, FCalls.Count);
  // the event the last handler posted is still waiting
  Assert.AreEqual(1, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnEventoSeLaCodaEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 1 to DS_MAX_EVENTS do
    FQueue.PostEventMS(FTarget, FEvNone, 0);
  Assert.AreEqual(DS_MAX_EVENTS, FQueue.Count);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.PostEventMS(FTarget, FEvNone, 0);
    end, EDoomScriptError, 'idEvent::Alloc : No more free events');
  Assert.AreEqual(DS_MAX_EVENTS, FQueue.Count);
  // exactly the limit of a frame is delivered without an error
  FQueue.ServiceEvents;
  Assert.AreEqual(DS_MAX_EVENTS, FCalls.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeConsegnareLEntitaAncoraPresente;
begin
  FEntities.Add(3, FOther, 'three');
  FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.EntityArg(3)]);
  FQueue.ServiceEvents;
  Assert.AreEqual('entity 3', FCalls.Text.Trim);
end;

procedure TTestDoomScriptEventQueue.DovrebbeConsegnareNessunaEntitaSeEStataRimossa;
var
  LArg: TDoomScriptEventArg;
begin
  FEntities.Add(3, FOther, 'three');
  FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.EntityArg(3)]);
  LArg := TDoomScriptConvert.EntityArg(3);
  LArg.Kind := DS_EVENT_ENTITY_NULL;
  FQueue.PostEventMS(FTarget, FEvEntityNull, 0, [LArg]);
  // an entity that never existed
  FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.EntityArg(9)]);
  FEntities.Remove(3);
  FQueue.ServiceEvents;
  Assert.AreEqual('entity -1', FCalls[0]);
  Assert.AreEqual('entitynull -1', FCalls[1]);
  Assert.AreEqual('entity -1', FCalls[2]);
end;

procedure TTestDoomScriptEventQueue.DovrebbeConsegnareNessunaEntitaSeIlNumeroEDiUnAltra;
begin
  FEntities.Add(3, FOther, 'three');
  FQueue.PostEventMS(FTarget, FEvEntity, 0, [TDoomScriptConvert.EntityArg(3)]);
  // the number is reused by another entity before the event is delivered
  FEntities.Remove(3);
  FEntities.Add(3, FDeaf, 'another');
  FQueue.ServiceEvents;
  Assert.AreEqual('entity -1', FCalls.Text.Trim);
end;

procedure TTestDoomScriptEventQueue.DovrebbeSopportareUnTargetCheSiLiberaNelGestore;
var
  LClass: TDoomScriptClassInfo;
  LTarget: TDoomScriptEventTarget;
begin
  LClass := FClasses.Declare('mortal');
  LClass.AddEvent(FEvNone,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      FCalls.Add('dying');
      // idClass::~idClass cancels its events, then the object goes
      FQueue.CancelEvents(TDoomScriptEventTarget(ATarget));
      ATarget.Free;
    end);
  LTarget := TDoomScriptEventTarget.Create(LClass);
  FQueue.PostEventMS(LTarget, FEvNone, 0);
  FQueue.PostEventMS(LTarget, FEvNone, 0);
  PostInt(0, 1);
  FQueue.ServiceEvents;
  Assert.AreEqual('dying,int 1', FCalls.CommaText.Replace('"', ''));
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeAccodareInSecondi;
var
  LSeconds: Single;
begin
  FHost.Time := 1000;
  LSeconds := 0.0625;
  Assert.IsTrue(FQueue.PostEventSec(FTarget, FEvInt, LSeconds, [TDoomScriptConvert.IntArg(1)]));
  Assert.AreEqual(1062, FQueue.GetEvent(0).Time);
  Assert.IsFalse(FQueue.PostEventSec(FDeaf, FEvInt, LSeconds, [TDoomScriptConvert.IntArg(1)]));
end;

procedure TTestDoomScriptEventQueue.DovrebbeSvuotareLaCoda;
begin
  PostInt(0, 1);
  PostInt(5, 2);
  FQueue.Clear;
  Assert.AreEqual(0, FQueue.Count);
  FQueue.ServiceEvents;
  Assert.AreEqual(0, FCalls.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeSalvareERipristinareLaCoda;
var
  LFloat: Single;
  LEntity: TDoomScriptEventArg;
begin
  LFloat := 2.5;
  FHost.Time := 500;
  FEntities.Add(7, FOther, 'seven');
  LEntity := TDoomScriptConvert.EntityArg(7);
  LEntity.Kind := DS_EVENT_ENTITY_NULL;
  FQueue.PostEventMS(FTarget, FEvMixed, 20, [TDoomScriptConvert.IntArg(-9), TDoomScriptConvert.FloatArg(LFloat),
    TDoomScriptConvert.VectorArg(TIdVec3.Create(1, 2, 3)), TDoomScriptConvert.StringArg('lost'), LEntity]);
  FQueue.PostEventMS(FOther, FEvNone, 10);
  FQueue.PostEventMS(FTarget, FEvEntity, 30, [TDoomScriptConvert.IntArg(0)]);
  FQueue.Save(FStream, Writer());
  FQueue.Clear;
  FStream.Position := 0;
  FQueue.Restore(FStream, Reader());
  Assert.AreEqual<Int64>(FStream.Size, FStream.Position);
  Assert.AreEqual(3, FQueue.Count);
  Assert.AreEqual(510, FQueue.GetEvent(0).Time);
  Assert.AreSame(FOther, FQueue.GetEvent(0).Target);
  Assert.AreSame(FEvNone, FQueue.GetEvent(0).EventDef);
  Assert.AreSame(FClass, FQueue.GetEvent(0).TargetClass);
  Assert.AreEqual(520, FQueue.GetEvent(1).Time);
  Assert.AreSame(FTarget, FQueue.GetEvent(1).Target);
  Assert.AreEqual(530, FQueue.GetEvent(2).Time);
  FHost.Time := 600;
  FQueue.ServiceEvents;
  Assert.AreEqual('other.none', FCalls[0]);
  // the string did not survive (see DovrebbeNonSalvareLeStringhe)
  Assert.AreEqual('mixed -9 40200000 (1,2,3) "" 7', FCalls[1]);
  Assert.AreEqual('entity -1', FCalls[2]);
end;

procedure TTestDoomScriptEventQueue.DovrebbeNonSalvareLeStringhe;
begin
  // a defect of idEvent::Save that is kept: a string argument is not written, though it counts in the
  // argument size that is written and checked
  FQueue.PostEventMS(FTarget, FEvString, 0, [TDoomScriptConvert.StringArg('hello')]);
  FQueue.Save(FStream, Writer());
  // count, time, "string", "listener", object, argsize: nothing else
  Assert.AreEqual<Int64>(4 + 4 + (4 + 6) + (4 + 8) + 4 + 4, FStream.Size);
  FQueue.Clear;
  FStream.Position := 0;
  FQueue.Restore(FStream, Reader());
  Assert.AreEqual(1, FQueue.Count);
  Assert.AreEqual('', string(FQueue.GetEvent(0).Args[0].StringValue));
  Assert.IsTrue(FQueue.GetEvent(0).Args[0].Kind = DS_EVENT_STRING);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnEventoSalvatoSconosciuto;
begin
  WriteEventHeader(0, 'zzz', 'listener', 1, 4);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore: unknown event ''zzz''');
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnaClasseSalvataSconosciuta;
begin
  WriteEventHeader(0, 'int', 'nope', 1, 4);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore: unknown class ''nope'' on event ''int''');
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnaDimensioneDegliArgomentiDiversa;
begin
  WriteEventHeader(0, 'int', 'listener', 1, 99);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore: arg size (4) doesn''t match saved arg size(99) on event ''int''');
  Assert.AreEqual(0, FQueue.Count);
  // the same record with the right size is read
  WriteEventHeader(40, 'int', 'listener', 2, 4);
  FQueue.Restore(FStream, Reader());
  Assert.AreEqual(1, FQueue.Count);
  Assert.AreEqual(77, FQueue.GetEvent(0).Args[0].IntValue);
  Assert.AreEqual(40, FQueue.GetEvent(0).Time);
  Assert.AreSame(FOther, FQueue.GetEvent(0).Target);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnOggettoSalvatoNonValido;
begin
  // no object
  WriteEventHeader(0, 'int', 'listener', -1, 4);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore: event ''int'' has no object that receives events');
  // an object that is not an event target
  WriteEventHeader(0, 'int', 'listener', 3, 4);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore: event ''int'' has no object that receives events');
  Assert.AreEqual(0, FQueue.Count);
  // a stream that ends early
  FStream.Clear;
  TDoomScriptSaveStream.WriteInt(FStream, 2);
  FStream.Position := 0;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idRestoreGame: read past the end of the save data');
  Assert.AreEqual(0, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareIlRipristinoSeLaCodaEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 1 to DS_MAX_EVENTS do
    FQueue.PostEventMS(FTarget, FEvNone, 0);
  WriteEventHeader(0, 'int', 'listener', 1, 4);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.Restore(FStream, Reader());
    end, EDoomScriptError, 'idEvent::Restore : No more free events');
  Assert.AreEqual(DS_MAX_EVENTS, FQueue.Count);
end;

procedure TTestDoomScriptEventQueue.DovrebbeRifiutareUnIndiceFuoriIntervallo;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.GetEvent(0);
    end, EDoomScriptMemoryError, 'idEvent: event 0 out of range');
  PostInt(0, 1);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.GetEvent(-1);
    end, EDoomScriptMemoryError, 'idEvent: event -1 out of range');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FQueue.GetEvent(1);
    end, EDoomScriptMemoryError, 'idEvent: event 1 out of range');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptEventQueue);

end.
