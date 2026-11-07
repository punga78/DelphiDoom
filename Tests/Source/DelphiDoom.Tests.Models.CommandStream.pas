{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the commands of a model        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.CommandStream;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Models.Types,
  DelphiDoom.Models.Intf;

type
  /// <summary>A renderer that writes the calls as text, to read them in the tests</summary>
  TTextRenderer = class(TInterfacedObject, IModelRenderer)
  strict private
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Text: string;
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
  end;

  /// <summary>Parity with the old TDDModelLoader (golden file models.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('models')]
  TTestModelsCommandStream = class(TObject)
  strict private
    FStream: IModelCommandStream;
    function Play(const AFrame: Integer): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaStessaImprontaDelVecchioCodiceSuLeSerieDiComandi;
    [Test]
    procedure DovrebbeAggiungereIComandiAlFotogrammaCorrente;
    [Test]
    procedure DovrebbeTrovareITFotogrammiDeiComandiEDelleChiamate;
    [Test]
    procedure DovrebbeOrdinareIFotogrammiAncheSeVengonoInDisordine;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnFotogrammaCheNonEsiste;
    [Test]
    procedure DovrebbeGirareAlRenderizzatoreSoloIComandiDelFotogramma;
    [Test]
    procedure DovrebbeEseguireUnaChiamataDiFotogrammaNelPunto;
    [Test]
    procedure DovrebbeFermareUnaChiamataCheTornaSuUnFotogrammaInCorso;
    [Test]
    procedure DovrebbeFermarsiAllaProfonditaMassima;
    [Test]
    procedure DovrebbeNonFareNullaPerUnFotogrammaSenzaComandi;
    [Test]
    procedure DovrebbeScrivereEIlLeggereIlFileBinario;
    [Test]
    procedure DovrebbeScrivereLaVersioneEIlNumeroDeiComandiInTesta;
    [Test]
    procedure DovrebbeDareFalsoSeLaVersioneEDiversa;
    [Test]
    procedure DovrebbeDareFalsoSeIlNumeroDeiComandiENegativo;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileEPiuCortoDeiComandiDichiarati;
    [Test]
    procedure DovrebbeSostituireIComandiLeggendoUnFile;
    [Test]
    procedure DovrebbeSvuotareConClear;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlComandoNonEsiste;
  end;

implementation

uses
  System.Math, DelphiDoom.Models.Factory, DelphiDoom.Tests.Models.Golden,
  DelphiDoom.Tests.Models.Scenarios, DelphiDoom.Tests.Models.Subject;

{ TTextRenderer }

constructor TTextRenderer.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.Delimiter := ' ';
end;

destructor TTextRenderer.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TTextRenderer.Text: string;
begin
  Result := Trim(FLines.DelimitedText);
end;

procedure TTextRenderer.BeginPrimitive(const AMode: Integer);
begin
  FLines.Add('B' + IntToStr(AMode));
end;

procedure TTextRenderer.EndPrimitive;
begin
  FLines.Add('E');
end;

procedure TTextRenderer.TexCoord2f(const AU, AV: Single);
begin
  FLines.Add('T');
end;

procedure TTextRenderer.Vertex3f(const AX, AY, AZ: Single);
begin
  FLines.Add('V' + IntToStr(Round(AX)));
end;

procedure TTextRenderer.Color3f(const AR, AG, AB: Single);
begin
  FLines.Add('C3');
end;

procedure TTextRenderer.Color4f(const AR, AG, AB, AA: Single);
begin
  FLines.Add('C4');
end;

procedure TTextRenderer.Normal3f(const ANX, ANY, ANZ: Single);
begin
  FLines.Add('N');
end;

procedure TTextRenderer.MatrixMode(const AMode: Integer);
begin
  FLines.Add('M' + IntToStr(AMode));
end;

procedure TTextRenderer.PushMatrix;
begin
  FLines.Add('P');
end;

procedure TTextRenderer.PopMatrix;
begin
  FLines.Add('O');
end;

procedure TTextRenderer.Translatef(const AX, AY, AZ: Single);
begin
  FLines.Add('Tr');
end;

procedure TTextRenderer.Rotatef(const AAngle, AX, AY, AZ: Single);
begin
  FLines.Add('Ro');
end;

procedure TTextRenderer.LoadIdentity;
begin
  FLines.Add('I');
end;

procedure TTextRenderer.Scalef(const AX, AY, AZ: Single);
begin
  FLines.Add('S');
end;

{ TTestModelsCommandStream }

procedure TTestModelsCommandStream.Setup;
begin
  FStream := TModelsFactory.CreateCommandStream;
end;

function TTestModelsCommandStream.Play(const AFrame: Integer): string;
var
  LRenderer: TTextRenderer;
  LInterface: IModelRenderer;
begin
  LRenderer := TTextRenderer.Create;
  LInterface := LRenderer;
  FStream.Play(AFrame, LInterface);
  Result := LRenderer.Text;
end;

procedure TTestModelsCommandStream.DovrebbeDareLaStessaImprontaDelVecchioCodiceSuLeSerieDiComandi;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('models.golden.txt');
  try
    LGolden.Check('dmx.streams', TModelsScenarios.CommandStreams(TModelsSubject.Create));
  finally
    LGolden.Free;
  end;
end;

procedure TTestModelsCommandStream.DovrebbeAggiungereIComandiAlFotogrammaCorrente;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.CurrentFrame := 3;
  FStream.AddCommand(MODEL_CMD_VERTEX3F, 1, 2, 3);
  Assert.AreEqual(2, FStream.CommandCount);
  Assert.AreEqual(0, FStream.Commands[0].Frame);
  Assert.AreEqual(3, FStream.Commands[1].Frame);
  Assert.AreEqual(MODEL_CMD_VERTEX3F, FStream.Commands[1].Command);
  Assert.AreEqual(2.0, FStream.Commands[1].Params[1], 0.0);
  Assert.AreEqual(0.0, FStream.Commands[1].Params[3], 0.0);
end;

procedure TTestModelsCommandStream.DovrebbeTrovareITFotogrammiDeiComandiEDelleChiamate;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_CALLFRAME, 5);
  FStream.CurrentFrame := 1;
  FStream.AddCommand(MODEL_CMD_END);
  FStream.IdentifyFrames;
  Assert.AreEqual(3, FStream.FrameCount);
  Assert.AreEqual(0, FStream.Frames[0]);
  Assert.AreEqual(1, FStream.Frames[1]);
  Assert.AreEqual(5, FStream.Frames[2]);
  Assert.AreEqual(2, FStream.IndexOfFrame(5));
  Assert.AreEqual(1, FStream.IndexOfFrame(1));
end;

procedure TTestModelsCommandStream.DovrebbeOrdinareIFotogrammiAncheSeVengonoInDisordine;
begin
  // regression: the old list of frames kept the order of arrival when a frame came after a
  // bigger one (its sorted flag was checked one number late), so the frames were not sorted and
  // the interpolation between two frame indexes used the wrong frames
  FStream.CurrentFrame := 1;
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.CurrentFrame := 0;
  FStream.AddCommand(MODEL_CMD_END);
  FStream.IdentifyFrames;
  Assert.AreEqual(2, FStream.FrameCount);
  Assert.AreEqual(0, FStream.Frames[0]);
  Assert.AreEqual(1, FStream.Frames[1]);
  Assert.AreEqual(0, FStream.IndexOfFrame(0));
  Assert.AreEqual(1, FStream.IndexOfFrame(1));
end;

procedure TTestModelsCommandStream.DovrebbeDareMenoUnoPerUnFotogrammaCheNonEsiste;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.IdentifyFrames;
  Assert.AreEqual(-1, FStream.IndexOfFrame(7));
  Assert.AreEqual(-1, FStream.IndexOfFrame(-1));
end;

procedure TTestModelsCommandStream.DovrebbeGirareAlRenderizzatoreSoloIComandiDelFotogramma;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_VERTEX3F, 1, 0, 0);
  FStream.AddCommand(MODEL_CMD_END);
  FStream.CurrentFrame := 1;
  FStream.AddCommand(MODEL_CMD_VERTEX3F, 9, 0, 0);
  FStream.AddCommand(MODEL_CMD_SETFRAME, 1);
  Assert.AreEqual('B4 V1 E', Play(0));
  // the command that changes the frame is not drawn
  Assert.AreEqual('V9', Play(1));
end;

procedure TTestModelsCommandStream.DovrebbeEseguireUnaChiamataDiFotogrammaNelPunto;
begin
  FStream.AddCommand(MODEL_CMD_PUSHMATRIX);
  FStream.AddCommand(MODEL_CMD_CALLFRAME, 1);
  FStream.AddCommand(MODEL_CMD_POPMATRIX);
  FStream.CurrentFrame := 1;
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_END);
  Assert.AreEqual('P B4 E O', Play(0));
end;

procedure TTestModelsCommandStream.DovrebbeFermareUnaChiamataCheTornaSuUnFotogrammaInCorso;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_CALLFRAME, 1);
  FStream.CurrentFrame := 1;
  FStream.AddCommand(MODEL_CMD_PUSHMATRIX);
  FStream.AddCommand(MODEL_CMD_CALLFRAME, 0);
  FStream.AddCommand(MODEL_CMD_CALLFRAME, 1);
  FStream.AddCommand(MODEL_CMD_POPMATRIX);
  // 0 calls 1; 1 calls 0 and itself: both are being drawn, so each runs once
  Assert.AreEqual('B4 P O', Play(0));
end;

procedure TTestModelsCommandStream.DovrebbeFermarsiAllaProfonditaMassima;
var
  LFrame: Integer;
begin
  for LFrame := 0 to 9 do
  begin
    FStream.CurrentFrame := LFrame;
    FStream.AddCommand(MODEL_CMD_PUSHMATRIX);
    if LFrame < 9 then
      FStream.AddCommand(MODEL_CMD_CALLFRAME, LFrame + 1);
  end;
  Assert.AreEqual(20, FStream.MaxRecursionDepth);
  Assert.AreEqual('P P P P P P P P P P', Play(0));
  FStream.MaxRecursionDepth := 3;
  Assert.AreEqual('P P P', Play(0));
  FStream.MaxRecursionDepth := 0;
  Assert.AreEqual('', Play(0));
end;

procedure TTestModelsCommandStream.DovrebbeNonFareNullaPerUnFotogrammaSenzaComandi;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  Assert.AreEqual('', Play(5));
  Assert.AreEqual('', Play(-1));
end;

procedure TTestModelsCommandStream.DovrebbeScrivereEIlLeggereIlFileBinario;
var
  LBytes: TBytes;
  LOther: IModelCommandStream;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_VERTEX3F, 1.5, 2.5, 3.5);
  FStream.CurrentFrame := 2;
  FStream.AddCommand(MODEL_CMD_ROTATEF, 10, 0, 1, 0);
  LBytes := FStream.SaveToBytes;
  LOther := TModelsFactory.CreateCommandStream;
  Assert.IsTrue(LOther.LoadFromBytes(LBytes));
  Assert.AreEqual(3, LOther.CommandCount);
  Assert.AreEqual(1.5, LOther.Commands[1].Params[0], 0.0);
  Assert.AreEqual(MODEL_CMD_ROTATEF, LOther.Commands[2].Command);
  Assert.AreEqual(2, LOther.Commands[2].Frame);
  Assert.AreEqual(2, LOther.FrameCount);
  Assert.AreEqual(1, LOther.IndexOfFrame(2));
end;

procedure TTestModelsCommandStream.DovrebbeScrivereLaVersioneEIlNumeroDeiComandiInTesta;
var
  LBytes: TBytes;
  LValue: Integer;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_END);
  LBytes := FStream.SaveToBytes;
  Assert.AreEqual(8 + 2 * MODEL_COMMAND_SIZE, Length(LBytes));
  Move(LBytes[0], LValue, 4);
  Assert.AreEqual(DMX_MAGIC, LValue);
  Move(LBytes[4], LValue, 4);
  Assert.AreEqual(2, LValue);
end;

procedure TTestModelsCommandStream.DovrebbeDareFalsoSeLaVersioneEDiversa;
var
  LBytes: TBytes;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  LBytes := FStream.SaveToBytes;
  LBytes[0] := 2;
  Assert.IsFalse(TModelsFactory.CreateCommandStream.LoadFromBytes(LBytes));
end;

procedure TTestModelsCommandStream.DovrebbeDareFalsoSeIlNumeroDeiComandiENegativo;
var
  LBytes: TBytes;
  LValue: Integer;
  LOther: IModelCommandStream;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  LBytes := FStream.SaveToBytes;
  LValue := -1;
  Move(LValue, LBytes[4], 4);
  LOther := TModelsFactory.CreateCommandStream;
  Assert.IsFalse(LOther.LoadFromBytes(LBytes));
  Assert.AreEqual(0, LOther.CommandCount);
end;

procedure TTestModelsCommandStream.DovrebbeSollevareUnErroreSeIlFileEPiuCortoDeiComandiDichiarati;
var
  LBytes: TBytes;
begin
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.AddCommand(MODEL_CMD_END);
  LBytes := FStream.SaveToBytes;
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.WillRaise(
    procedure
    begin
      TModelsFactory.CreateCommandStream.LoadFromBytes(LBytes);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      TModelsFactory.CreateCommandStream.LoadFromBytes(nil);
    end, EModelsException);
end;

procedure TTestModelsCommandStream.DovrebbeSostituireIComandiLeggendoUnFile;
var
  LOther: IModelCommandStream;
begin
  // as the old AppendFromStream (a defect that is kept): the commands that were there are gone
  LOther := TModelsFactory.CreateCommandStream;
  LOther.AddCommand(MODEL_CMD_BEGIN, 4);
  LOther.AddCommand(MODEL_CMD_END);
  LOther.AddCommand(MODEL_CMD_PUSHMATRIX);
  FStream.AddCommand(MODEL_CMD_POPMATRIX);
  Assert.IsTrue(LOther.LoadFromBytes(FStream.SaveToBytes));
  Assert.AreEqual(1, LOther.CommandCount);
  Assert.AreEqual(MODEL_CMD_POPMATRIX, LOther.Commands[0].Command);
end;

procedure TTestModelsCommandStream.DovrebbeSvuotareConClear;
begin
  FStream.CurrentFrame := 4;
  FStream.AddCommand(MODEL_CMD_BEGIN, 4);
  FStream.IdentifyFrames;
  FStream.Clear;
  Assert.AreEqual(0, FStream.CommandCount);
  Assert.AreEqual(0, FStream.FrameCount);
  Assert.AreEqual(0, FStream.CurrentFrame);
end;

procedure TTestModelsCommandStream.DovrebbeSollevareUnErroreSeIlComandoNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FStream.GetCommand(0);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      FStream.GetFrame(0);
    end, EModelsException);
end;

end.
