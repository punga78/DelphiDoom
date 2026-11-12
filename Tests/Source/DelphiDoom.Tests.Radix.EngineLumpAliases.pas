{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineRadixLumpAliases (the names of RADIX.DAT over   }
{  the lumps of the engine), with a fake directory of lumps                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.EngineLumpAliases;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Radix.Intf, DelphiDoom.Engine.Wad.Lumps.Intf, DelphiDoom.Engine.Wad.Aliases.Intf;

type
  /// <summary>A directory of lumps held in memory: a name and a text for every lump</summary>
  TFakeEngineLumps = class(TInterfacedObject, IEngineLumps)
  strict private
    FNames: TList<string>;
    FTexts: TList<string>;
    FTextReads: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName, AText: string);
    function Count: Integer;
    function CheckNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    function GetNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    function NameOf(ALump: Integer): string;
    function LengthOf(ALump: Integer): Integer;
    function Crc32Of(ALump: Integer): string;
    function TextOf(ALump: Integer): string;
    procedure Read(ALump: Integer; ADestination: Pointer);
    function Cache(ALump: Integer; ATag: Integer): Pointer;
    procedure RuntimeLoadFile(const AFileName: string);
    procedure Reload;
    /// <summary>How many times the text of a lump was asked</summary>
    property TextReads: Integer read FTextReads;
  end;

  [TestFixture]
  [Category('radix')]
  TTestRadixEngineLumpAliases = class(TObject)
  strict private
    FLumpsObject: TFakeEngineLumps;
    FLumps: IEngineLumps;
    FAliases: IEngineLumpAliases;
    function Resolve(const AName: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNulle;
    [Test]
    procedure DovrebbeLeggereRadixinfSoloAllaPrimaDomanda;
    [Test]
    procedure DovrebbeDareIlLumpDiUnNomeDiRadix;
    [Test]
    procedure DovrebbeDareFalsoSeRadixinfNonCe;
    [Test]
    procedure DovrebbeScartareGliAliasDeiLumpCheNonCiSono;
    [Test]
    procedure DovrebbeUnireTuttiILumpRadixinfEIlPrimoVince;
    [Test]
    procedure DovrebbeRileggereDopoReset;
  end;

implementation

uses
  DelphiDoom.Radix.Factory, DelphiDoom.Engine.Radix.LumpAliases;

{ TFakeEngineLumps }

constructor TFakeEngineLumps.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
  FTexts := TList<string>.Create;
end;

destructor TFakeEngineLumps.Destroy;
begin
  FTexts.Free;
  FNames.Free;
  inherited Destroy;
end;

procedure TFakeEngineLumps.Add(const AName, AText: string);
begin
  FNames.Add(AName);
  FTexts.Add(AText);
end;

function TFakeEngineLumps.Count: Integer;
begin
  Result := FNames.Count;
end;

function TFakeEngineLumps.CheckNumForName(const AName: string; AFlags: LongWord): Integer;
var
  LIndex: Integer;
begin
  // the last lump with the name, as the engine does
  for LIndex := FNames.Count - 1 downto 0 do
    if SameText(FNames[LIndex], AName) then
      Exit(LIndex);
  Result := -1;
end;

function TFakeEngineLumps.GetNumForName(const AName: string; AFlags: LongWord): Integer;
begin
  Result := CheckNumForName(AName, AFlags);
  if Result < 0 then
    raise Exception.Create('lump not found: ' + AName);
end;

function TFakeEngineLumps.NameOf(ALump: Integer): string;
begin
  Result := FNames[ALump];
end;

function TFakeEngineLumps.LengthOf(ALump: Integer): Integer;
begin
  Result := Length(FTexts[ALump]);
end;

function TFakeEngineLumps.Crc32Of(ALump: Integer): string;
begin
  Result := '';
end;

function TFakeEngineLumps.TextOf(ALump: Integer): string;
begin
  Inc(FTextReads);
  Result := FTexts[ALump];
end;

procedure TFakeEngineLumps.Read(ALump: Integer; ADestination: Pointer);
begin
  raise ENotSupportedException.Create('Read');
end;

function TFakeEngineLumps.Cache(ALump: Integer; ATag: Integer): Pointer;
begin
  raise ENotSupportedException.Create('Cache');
end;

procedure TFakeEngineLumps.RuntimeLoadFile(const AFileName: string);
begin
  raise ENotSupportedException.Create('RuntimeLoadFile');
end;

procedure TFakeEngineLumps.Reload;
begin
  raise ENotSupportedException.Create('Reload');
end;

{ TTestRadixEngineLumpAliases }

procedure TTestRadixEngineLumpAliases.Setup;
begin
  FLumpsObject := TFakeEngineLumps.Create;
  FLumps := FLumpsObject;
  FAliases := TEngineRadixLumpAliases.Create(FLumps,
    function: IRadixLumpAliases
    begin
      Result := TRadixFactory.CreateLumpAliases;
    end);
end;

procedure TTestRadixEngineLumpAliases.TearDown;
begin
  FAliases := nil;
  FLumps := nil;
  FLumpsObject := nil;
end;

function TTestRadixEngineLumpAliases.Resolve(const AName: string): string;
begin
  if not FAliases.TryResolve(AName, Result) then
    Result := '<none>';
end;

procedure TTestRadixEngineLumpAliases.DovrebbeRifiutareLeDipendenzeNulle;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineRadixLumpAliases.Create(nil,
        function: IRadixLumpAliases
        begin
          Result := TRadixFactory.CreateLumpAliases;
        end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TEngineRadixLumpAliases.Create(FLumps, nil);
    end, EArgumentNilException);
end;

procedure TTestRadixEngineLumpAliases.DovrebbeLeggereRadixinfSoloAllaPrimaDomanda;
begin
  FLumpsObject.Add('RADIX025', '');
  FLumpsObject.Add('RADIXINF', 'RADIX025=MainMenu');
  Assert.AreEqual(0, FLumpsObject.TextReads);
  Resolve('MainMenu');
  Resolve('MainMenu');
  Resolve('Other');
  Assert.AreEqual(1, FLumpsObject.TextReads);
end;

procedure TTestRadixEngineLumpAliases.DovrebbeDareIlLumpDiUnNomeDiRadix;
begin
  FLumpsObject.Add('RADIX025', '');
  FLumpsObject.Add('RADIXINF', 'RADIX025=MainMenu');
  Assert.AreEqual('RADIX025', Resolve('MainMenu'));
  Assert.AreEqual('RADIX025', Resolve('MAINMENU'));
end;

procedure TTestRadixEngineLumpAliases.DovrebbeDareFalsoSeRadixinfNonCe;
begin
  FLumpsObject.Add('PLAYPAL', '');
  Assert.AreEqual('<none>', Resolve('MainMenu'));
end;

procedure TTestRadixEngineLumpAliases.DovrebbeScartareGliAliasDeiLumpCheNonCiSono;
begin
  FLumpsObject.Add('RADIX025', '');
  FLumpsObject.Add('RADIXINF', 'RADIX025=MainMenu'#13#10'RADIX099=Missing');
  Assert.AreEqual('RADIX025', Resolve('MainMenu'));
  Assert.AreEqual('<none>', Resolve('Missing'));
end;

procedure TTestRadixEngineLumpAliases.DovrebbeUnireTuttiILumpRadixinfEIlPrimoVince;
begin
  FLumpsObject.Add('RADIX001', '');
  FLumpsObject.Add('RADIX002', '');
  FLumpsObject.Add('RADIX003', '');
  FLumpsObject.Add('RADIXINF', 'RADIX001=Arrow');
  FLumpsObject.Add('RADIXINF', 'RADIX002=Arrow'#13#10'RADIX003=Other');
  Assert.AreEqual('RADIX001', Resolve('Arrow'));
  Assert.AreEqual('RADIX003', Resolve('Other'));
end;

procedure TTestRadixEngineLumpAliases.DovrebbeRileggereDopoReset;
begin
  FLumpsObject.Add('RADIX025', '');
  FLumpsObject.Add('RADIXINF', 'RADIX025=MainMenu');
  Assert.AreEqual('<none>', Resolve('Later'));
  // a file is added while the game runs: w_wad.pas tells the table
  FLumpsObject.Add('RADIX026', '');
  FLumpsObject.Add('RADIXINF', 'RADIX026=Later');
  Assert.AreEqual('<none>', Resolve('Later'));
  FAliases.Reset;
  Assert.AreEqual('RADIX026', Resolve('Later'));
  Assert.AreEqual(3, FLumpsObject.TextReads);
end;

end.
