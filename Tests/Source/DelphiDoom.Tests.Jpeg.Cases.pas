{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - the streams of the parity tests     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Cases;

// The streams on which the decoder is compared with the answers of the old
// one (Tests\Data\Jpeg\jpeg_golden.txt): valid streams of every kind (see
// TJpegSynthesizer), then those same streams cut at several points, with some
// bytes changed, and with the fields of the headers set to values that a
// decoder must refuse. The list is built by code, with fixed seeds, so it is
// the same on every run and the names are the keys of the file.

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults;

type
  /// <summary>
  ///   A named stream
  /// </summary>
  TJpegCase = record
    Name: string;
    Data: TBytes;
  end;

  /// <summary>
  ///   Builds the streams of the parity tests
  /// </summary>
  TJpegCases = class
  private
    FCases: TList<TJpegCase>;
    FMutable: TList<Integer>;
    procedure Add(const AName: string; const AData: TBytes; AMutable: Boolean = False);
    procedure AddGray;
    procedure AddColor;
    procedure AddSampling;
    procedure AddRestart;
    procedure AddColorSpaces;
    procedure AddTables;
    procedure AddMultiScan;
    procedure AddProgressive;
    procedure AddRaw;
    procedure AddFiles;
    procedure AddMutations;
    procedure AddPatches;
    class function Truncate(const AData: TBytes; ALength: Integer): TBytes; static;
    class function Flip(const AData: TBytes; ASeed: Cardinal; ACount: Integer): TBytes; static;
    class function SegmentStart(const AData: TBytes; AMarker: Byte): Integer; static;
    class function Patched(const AData: TBytes; AMarker: Byte; AOffset: Integer;
      const AValues: array of Byte): TBytes; static;
    class function HexToBytes(const AHex: string): TBytes; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>All the cases, in a fixed order</summary>
    class function All: TArray<TJpegCase>; static;
  end;

implementation

uses
  DelphiDoom.Tests.Jpeg.Random, DelphiDoom.Tests.Jpeg.Synthesizer;

const
  // 16x16 solid red image, 4:2:0, made with an encoder other than ours
  RED_IMAGE_HEX =
    'FFD8FFE000104A46494600010100000100010000FFDB00430003020203020203' +
    '03030304030304050805050404050A070706080C0A0C0C0B0A0B0B0D0E12100D' +
    '0E110E0B0B1016101113141515150C0F171816141812141514FFDB0043010304' +
    '0405040509050509140D0B0D1414141414141414141414141414141414141414' +
    '141414141414141414141414141414141414141414141414141414141414FFC0' +
    '0011080010001003012200021101031101FFC4001F0000010501010101010100' +
    '000000000000000102030405060708090A0BFFC400B510000201030302040305' +
    '0504040000017D01020300041105122131410613516107227114328191A10823' +
    '42B1C11552D1F02433627282090A161718191A25262728292A3435363738393A' +
    '434445464748494A535455565758595A636465666768696A737475767778797A' +
    '838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7' +
    'B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1' +
    'F2F3F4F5F6F7F8F9FAFFC4001F01000301010101010101010100000000000001' +
    '02030405060708090A0BFFC400B5110002010204040304070504040001027700' +
    '0102031104052131061241510761711322328108144291A1B1C109233352F015' +
    '6272D10A162434E125F11718191A262728292A35363738393A43444546474849' +
    '4A535455565758595A636465666768696A737475767778797A82838485868788' +
    '898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4' +
    'C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9' +
    'FAFFDA000C03010002110311003F00F9D28A28AFC30FF54CFFD9';

  // 8x8 solid gray image (value 200), made with an encoder other than ours
  GRAY_IMAGE_HEX =
    'FFD8FFE000104A46494600010100000100010000FFDB00430003020203020203' +
    '03030304030304050805050404050A070706080C0A0C0C0B0A0B0B0D0E12100D' +
    '0E110E0B0B1016101113141515150C0F171816141812141514FFC0000B080008' +
    '000801011100FFC4001F00000105010101010101000000000000000001020304' +
    '05060708090A0BFFC400B5100002010303020403050504040000017D01020300' +
    '041105122131410613516107227114328191A1082342B1C11552D1F024336272' +
    '82090A161718191A25262728292A3435363738393A434445464748494A535455' +
    '565758595A636465666768696A737475767778797A838485868788898A929394' +
    '95969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9' +
    'CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FAFFDA' +
    '0008010100003F00FB02BFFFD9';

{ TJpegCases }

constructor TJpegCases.Create;
begin
  inherited Create;
  FCases := TList<TJpegCase>.Create;
  FMutable := TList<Integer>.Create;
end;

destructor TJpegCases.Destroy;
begin
  FMutable.Free;
  FCases.Free;
  inherited Destroy;
end;

class function TJpegCases.All: TArray<TJpegCase>;
var
  LBuilder: TJpegCases;
begin
  LBuilder := TJpegCases.Create;
  try
    LBuilder.AddGray;
    LBuilder.AddColor;
    LBuilder.AddSampling;
    LBuilder.AddRestart;
    LBuilder.AddColorSpaces;
    LBuilder.AddTables;
    LBuilder.AddMultiScan;
    LBuilder.AddProgressive;
    LBuilder.AddRaw;
    LBuilder.AddFiles;
    LBuilder.AddPatches;
    LBuilder.AddMutations;
    Result := LBuilder.FCases.ToArray;
  finally
    LBuilder.Free;
  end;
end;

procedure TJpegCases.Add(const AName: string; const AData: TBytes;
  AMutable: Boolean);
var
  LCase: TJpegCase;
begin
  LCase.Name := AName;
  LCase.Data := AData;
  FCases.Add(LCase);
  if AMutable then
    FMutable.Add(FCases.Count - 1);
end;

class function TJpegCases.HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2)));
end;

class function TJpegCases.Truncate(const AData: TBytes; ALength: Integer): TBytes;
begin
  Result := Copy(AData, 0, ALength);
end;

class function TJpegCases.Flip(const AData: TBytes; ASeed: Cardinal;
  ACount: Integer): TBytes;
var
  LRandom: TJpegRandom;
  LIndex: Integer;
  LPosition: Integer;
begin
  Result := Copy(AData);
  LRandom := TJpegRandom.Create(ASeed);
  for LIndex := 1 to ACount do
  begin
    LPosition := LRandom.Next(Length(Result));
    Result[LPosition] := Result[LPosition] xor Byte(LRandom.Between(1, 255));
  end;
end;

class function TJpegCases.SegmentStart(const AData: TBytes; AMarker: Byte): Integer;
var
  LPosition: Integer;
  LCode: Byte;
begin
  // Walks the segments of the headers; the result is the position of the
  // first byte after the marker code, or -1
  Result := -1;
  LPosition := 2;
  while LPosition + 4 <= Length(AData) do
  begin
    if AData[LPosition] <> $FF then
      Exit;
    LCode := AData[LPosition + 1];
    if LCode = AMarker then
      Exit(LPosition + 2);
    if LCode = $DA then
      Exit;
    LPosition := LPosition + 2 + (Integer(AData[LPosition + 2]) shl 8) + AData[LPosition + 3];
  end;
end;

class function TJpegCases.Patched(const AData: TBytes; AMarker: Byte;
  AOffset: Integer; const AValues: array of Byte): TBytes;
var
  LStart: Integer;
  LIndex: Integer;
begin
  Result := Copy(AData);
  LStart := SegmentStart(AData, AMarker);
  if LStart < 0 then
    raise Exception.CreateFmt('Segment %x not found', [AMarker]);
  for LIndex := 0 to High(AValues) do
    Result[LStart + AOffset + LIndex] := AValues[LIndex];
end;

procedure TJpegCases.AddGray;
const
  SIZES: array[0..7, 0..1] of Integer = (
    (1, 1), (8, 8), (9, 7), (16, 16), (17, 33), (64, 8), (100, 50), (3, 70));
var
  LIndex: Integer;
  LSpec: TJpegSpec;
begin
  for LIndex := 0 to High(SIZES) do
  begin
    LSpec := TJpegSpec.Make(SIZES[LIndex, 0], SIZES[LIndex, 1], 1, 100 + LIndex);
    Add(Format('gray-%dx%d', [SIZES[LIndex, 0], SIZES[LIndex, 1]]),
      TJpegSynthesizer.Build(LSpec), LIndex in [2, 4, 6]);
  end;

  // Sampling factors on a single component do not change the image
  LSpec := TJpegSpec.Make(33, 20, 1, 130);
  LSpec.SetSampling(0, 2, 2);
  Add('gray-sampling-2x2', TJpegSynthesizer.Build(LSpec));
  LSpec := TJpegSpec.Make(25, 20, 1, 131);
  LSpec.SetSampling(0, 4, 1);
  Add('gray-sampling-4x1', TJpegSynthesizer.Build(LSpec));
  LSpec := TJpegSpec.Make(40, 40, 1, 132);
  LSpec.Density := 100;
  LSpec.QuantizationScale := 400;
  Add('gray-heavy', TJpegSynthesizer.Build(LSpec));
  LSpec := TJpegSpec.Make(40, 40, 1, 133);
  LSpec.Density := 4;
  Add('gray-sparse', TJpegSynthesizer.Build(LSpec));
end;

procedure TJpegCases.AddColor;
const
  SIZES: array[0..8, 0..1] of Integer = (
    (1, 1), (8, 8), (15, 9), (16, 16), (33, 17), (64, 48), (101, 67), (2, 5), (130, 3));
var
  LIndex: Integer;
  LSpec: TJpegSpec;
begin
  for LIndex := 0 to High(SIZES) do
  begin
    LSpec := TJpegSpec.Make(SIZES[LIndex, 0], SIZES[LIndex, 1], 3, 200 + LIndex);
    Add(Format('color-444-%dx%d', [SIZES[LIndex, 0], SIZES[LIndex, 1]]),
      TJpegSynthesizer.Build(LSpec), LIndex in [2, 5]);
  end;
end;

procedure TJpegCases.AddSampling;
type
  TSampling = record
    Name: string;
    H: array[0..2] of Integer;
    V: array[0..2] of Integer;
  end;
const
  SAMPLINGS: array[0..12] of TSampling = (
    (Name: 'h2v1'; H: (2, 1, 1); V: (1, 1, 1)),
    (Name: 'h2v2'; H: (2, 1, 1); V: (2, 1, 1)),
    (Name: 'h1v2'; H: (1, 1, 1); V: (2, 1, 1)),
    (Name: 'h4v1'; H: (4, 1, 1); V: (1, 1, 1)),
    (Name: 'h4v2'; H: (4, 1, 1); V: (2, 1, 1)),
    (Name: 'h2v2-c2v1'; H: (2, 2, 1); V: (2, 1, 1)),
    (Name: 'h3v1'; H: (3, 1, 1); V: (1, 1, 1)),
    (Name: 'h2v2-c1-full'; H: (2, 1, 2); V: (2, 1, 2)),
    (Name: 'y1-c2'; H: (1, 2, 2); V: (1, 2, 2)),
    (Name: 'h4v2-c2v1'; H: (4, 2, 1); V: (2, 1, 1)),
    (Name: 'h1v4'; H: (1, 1, 1); V: (4, 1, 1)),
    (Name: 'fraction'; H: (3, 2, 1); V: (1, 1, 1)),
    (Name: 'fraction-v'; H: (1, 1, 1); V: (3, 2, 1))
  );
  SIZES: array[0..4, 0..1] of Integer = ((50, 37), (7, 5), (16, 16), (2, 2), (5, 9));
var
  LSampling: Integer;
  LSize: Integer;
  LComponent: Integer;
  LSpec: TJpegSpec;
begin
  for LSampling := 0 to High(SAMPLINGS) do
    for LSize := 0 to High(SIZES) do
    begin
      LSpec := TJpegSpec.Make(SIZES[LSize, 0], SIZES[LSize, 1], 3,
        300 + LSampling * 10 + LSize);
      for LComponent := 0 to 2 do
        LSpec.SetSampling(LComponent, SAMPLINGS[LSampling].H[LComponent],
          SAMPLINGS[LSampling].V[LComponent]);
      Add(Format('sampling-%s-%dx%d', [SAMPLINGS[LSampling].Name,
        SIZES[LSize, 0], SIZES[LSize, 1]]), TJpegSynthesizer.Build(LSpec),
        (LSize = 0) and (LSampling in [0, 1, 4]));
    end;

  // Four samples across and a width that is not a multiple of any of them
  LSpec := TJpegSpec.Make(61, 29, 3, 390);
  LSpec.SetSampling(0, 2, 2);
  Add('sampling-h2v2-61x29', TJpegSynthesizer.Build(LSpec), True);
end;

procedure TJpegCases.AddRestart;
const
  INTERVALS: array[0..4] of Integer = (1, 2, 5, 17, 1000);
var
  LIndex: Integer;
  LSpec: TJpegSpec;
begin
  for LIndex := 0 to High(INTERVALS) do
  begin
    LSpec := TJpegSpec.Make(33, 40, 3, 400 + LIndex);
    LSpec.SetSampling(0, 2, 2);
    LSpec.RestartInterval := INTERVALS[LIndex];
    Add(Format('restart-h2v2-%d', [INTERVALS[LIndex]]),
      TJpegSynthesizer.Build(LSpec), LIndex in [0, 2]);

    LSpec := TJpegSpec.Make(41, 19, 1, 410 + LIndex);
    LSpec.RestartInterval := INTERVALS[LIndex];
    Add(Format('restart-gray-%d', [INTERVALS[LIndex]]),
      TJpegSynthesizer.Build(LSpec), LIndex = 1);
  end;

  LSpec := TJpegSpec.Make(48, 48, 3, 420);
  LSpec.RestartInterval := 4;
  LSpec.ExtraMarkers := True;
  Add('restart-extra-markers', TJpegSynthesizer.Build(LSpec), True);
end;

procedure TJpegCases.AddColorSpaces;
var
  LSpec: TJpegSpec;

  procedure Build(const AName: string; ACount: Integer; AMarker: TJpegColorMarker;
    AFirst, ASecond, AThird: Integer; ASeed: Cardinal);
  begin
    LSpec := TJpegSpec.Make(24, 24, ACount, ASeed);
    LSpec.Marker := AMarker;
    LSpec.SetSampling(0, 2, 2);
    LSpec.ComponentIds[0] := AFirst;
    LSpec.ComponentIds[1] := ASecond;
    LSpec.ComponentIds[2] := AThird;
    Add(AName, TJpegSynthesizer.Build(LSpec), True);
  end;

begin
  Build('space-none-123', 3, jcmNone, 1, 2, 3, 500);
  Build('space-none-rgb', 3, jcmNone, 82, 71, 66, 501);
  Build('space-none-other', 3, jcmNone, 7, 8, 9, 502);
  Build('space-jfif', 3, jcmJfif, 82, 71, 66, 503);
  Build('space-adobe-0', 3, jcmAdobeTransform0, 1, 2, 3, 504);
  Build('space-adobe-1', 3, jcmAdobeTransform1, 1, 2, 3, 505);
  Build('space-adobe-2', 3, jcmAdobeTransform2, 1, 2, 3, 506);

  // Not 1 or 3 components: no conversion to RGB
  Build('space-four-cmyk', 4, jcmNone, 1, 2, 3, 510);
  Build('space-four-adobe-0', 4, jcmAdobeTransform0, 1, 2, 3, 511);
  Build('space-four-adobe-2', 4, jcmAdobeTransform2, 1, 2, 3, 512);
  Build('space-two', 2, jcmNone, 1, 2, 3, 513);
end;

procedure TJpegCases.AddTables;
var
  LSpec: TJpegSpec;
begin
  LSpec := TJpegSpec.Make(40, 30, 3, 600);
  LSpec.CustomTables := True;
  LSpec.SetSampling(0, 2, 1);
  Add('tables-custom', TJpegSynthesizer.Build(LSpec), True);

  LSpec := TJpegSpec.Make(40, 30, 3, 601);
  LSpec.WideQuantization := True;
  Add('tables-wide-quantization', TJpegSynthesizer.Build(LSpec), True);

  LSpec := TJpegSpec.Make(40, 30, 3, 602);
  LSpec.QuantizationScale := 20;
  LSpec.Density := 100;
  Add('tables-fine-quantization', TJpegSynthesizer.Build(LSpec));

  LSpec := TJpegSpec.Make(40, 30, 3, 603);
  LSpec.QuantizationScale := 500;
  LSpec.Density := 90;
  LSpec.SetSampling(0, 2, 2);
  Add('tables-coarse-quantization', TJpegSynthesizer.Build(LSpec));

  LSpec := TJpegSpec.Make(40, 30, 3, 604);
  LSpec.FrameKind := jfkExtended;
  Add('tables-extended-frame', TJpegSynthesizer.Build(LSpec));

  LSpec := TJpegSpec.Make(40, 30, 3, 605);
  LSpec.ExtraMarkers := True;
  LSpec.SetSampling(0, 2, 2);
  Add('tables-extra-markers', TJpegSynthesizer.Build(LSpec), True);

  LSpec := TJpegSpec.Make(32, 32, 3, 606);
  LSpec.Density := 100;
  LSpec.QuantizationScale := 300;
  LSpec.WideQuantization := True;
  Add('tables-overflow', TJpegSynthesizer.Build(LSpec));
end;

procedure TJpegCases.AddMultiScan;
var
  LSpec: TJpegSpec;
  LShapes: array[0..4] of TArray<TJpegScanSpec>;
  LNames: array[0..4] of string;
  LIndex: Integer;
begin
  SetLength(LShapes[0], 3);
  LShapes[0][0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LShapes[0][1] := TJpegScanSpec.Make([1], 0, 63, 0, 0);
  LShapes[0][2] := TJpegScanSpec.Make([2], 0, 63, 0, 0);
  LNames[0] := 'each';
  SetLength(LShapes[1], 2);
  LShapes[1][0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LShapes[1][1] := TJpegScanSpec.Make([1, 2], 0, 63, 0, 0);
  LNames[1] := 'y-then-chroma';
  SetLength(LShapes[2], 2);
  LShapes[2][0] := TJpegScanSpec.Make([0, 1], 0, 63, 0, 0);
  LShapes[2][1] := TJpegScanSpec.Make([2], 0, 63, 0, 0);
  LNames[2] := 'yc-then-c';
  SetLength(LShapes[3], 3);
  LShapes[3][0] := TJpegScanSpec.Make([2], 0, 63, 0, 0);
  LShapes[3][1] := TJpegScanSpec.Make([1], 0, 63, 0, 0);
  LShapes[3][2] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LNames[3] := 'reverse';
  // The last component is never sent
  SetLength(LShapes[4], 2);
  LShapes[4][0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LShapes[4][1] := TJpegScanSpec.Make([1], 0, 63, 0, 0);
  LNames[4] := 'last-missing';

  for LIndex := 0 to High(LShapes) do
  begin
    LSpec := TJpegSpec.Make(37, 26, 3, 700 + LIndex);
    LSpec.SetSampling(0, 2, 2);
    LSpec.Scans := LShapes[LIndex];
    Add('multiscan-h2v2-' + LNames[LIndex], TJpegSynthesizer.Build(LSpec), LIndex in [0, 1]);

    LSpec := TJpegSpec.Make(24, 40, 3, 710 + LIndex);
    LSpec.Scans := LShapes[LIndex];
    LSpec.RestartInterval := 3;
    Add('multiscan-444-restart-' + LNames[LIndex], TJpegSynthesizer.Build(LSpec));
  end;

  // A gray image whose component has a sampling factor: the iMCU row has
  // more than one row of blocks
  LSpec := TJpegSpec.Make(33, 40, 1, 720);
  LSpec.SetSampling(0, 2, 2);
  SetLength(LSpec.Scans, 1);
  LSpec.Scans[0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  Add('multiscan-gray-2x2', TJpegSynthesizer.Build(LSpec));
end;

procedure TJpegCases.AddProgressive;
type
  TShape = record
    Name: string;
    Count: Integer;
    H: Integer;
    V: Integer;
  end;
const
  SHAPES: array[0..5] of TShape = (
    (Name: 'gray'; Count: 1; H: 1; V: 1),
    (Name: '444'; Count: 3; H: 1; V: 1),
    (Name: '420'; Count: 3; H: 2; V: 2),
    (Name: '422'; Count: 3; H: 2; V: 1),
    (Name: '440'; Count: 3; H: 1; V: 2),
    (Name: 'gray-2x2'; Count: 1; H: 2; V: 2)
  );
  SIZES: array[0..3, 0..1] of Integer = ((16, 16), (33, 17), (64, 40), (5, 3));
var
  LShape: Integer;
  LSize: Integer;
  LSpec: TJpegSpec;
  LScans: TArray<TJpegScanSpec>;
  LKeep: Integer;
begin
  for LShape := 0 to High(SHAPES) do
  begin
    for LSize := 0 to High(SIZES) do
    begin
      LSpec := TJpegSpec.Make(SIZES[LSize, 0], SIZES[LSize, 1], SHAPES[LShape].Count,
        800 + LShape * 10 + LSize);
      LSpec.FrameKind := jfkProgressive;
      LSpec.SetSampling(0, SHAPES[LShape].H, SHAPES[LShape].V);
      LSpec.Scans := TJpegSynthesizer.StandardProgression(SHAPES[LShape].Count);
      Add(Format('progressive-%s-%dx%d', [SHAPES[LShape].Name, SIZES[LSize, 0],
        SIZES[LSize, 1]]), TJpegSynthesizer.Build(LSpec),
        (LSize = 1) and (LShape in [0, 2]));
    end;

    // Spectral selection only
    LSpec := TJpegSpec.Make(33, 17, SHAPES[LShape].Count, 850 + LShape);
    LSpec.FrameKind := jfkProgressive;
    LSpec.SetSampling(0, SHAPES[LShape].H, SHAPES[LShape].V);
    LSpec.Scans := TJpegSynthesizer.SpectralProgression(SHAPES[LShape].Count);
    Add('progressive-spectral-' + SHAPES[LShape].Name, TJpegSynthesizer.Build(LSpec));

    // The file ends before the last scans: the missing refinement is smoothed
    LScans := TJpegSynthesizer.StandardProgression(SHAPES[LShape].Count);
    for LKeep := 1 to Length(LScans) - 1 do
    begin
      LSpec := TJpegSpec.Make(40, 33, SHAPES[LShape].Count, 860 + LShape * 20 + LKeep);
      LSpec.FrameKind := jfkProgressive;
      LSpec.SetSampling(0, SHAPES[LShape].H, SHAPES[LShape].V);
      LSpec.Scans := Copy(LScans, 0, LKeep);
      Add(Format('progressive-partial-%s-%d', [SHAPES[LShape].Name, LKeep]),
        TJpegSynthesizer.Build(LSpec), (LShape = 2) and (LKeep in [3, 6]));
    end;
  end;

  LSpec := TJpegSpec.Make(48, 40, 3, 990);
  LSpec.FrameKind := jfkProgressive;
  LSpec.SetSampling(0, 2, 2);
  LSpec.RestartInterval := 3;
  LSpec.ExtraMarkers := True;
  LSpec.Scans := TJpegSynthesizer.StandardProgression(3);
  Add('progressive-restart-extra', TJpegSynthesizer.Build(LSpec), True);

  LSpec := TJpegSpec.Make(48, 40, 3, 991);
  LSpec.FrameKind := jfkProgressive;
  LSpec.Density := 100;
  LSpec.QuantizationScale := 200;
  LSpec.Scans := TJpegSynthesizer.StandardProgression(3);
  Add('progressive-dense', TJpegSynthesizer.Build(LSpec), True);

  LSpec := TJpegSpec.Make(100, 100, 3, 992);
  LSpec.FrameKind := jfkProgressive;
  LSpec.Density := 8;
  LSpec.SetSampling(0, 2, 2);
  LSpec.RestartInterval := 7;
  LSpec.Scans := TJpegSynthesizer.StandardProgression(3);
  Add('progressive-sparse-restart', TJpegSynthesizer.Build(LSpec));
end;

procedure TJpegCases.AddFiles;
var
  LFiles: TArray<string>;
  LFile: string;
  LIndex: Integer;
begin
  // Images written by the encoder of the library (gradients and noise, 4:4:4)
  // and kept as files, so that the answer does not depend on how the encoder
  // rounds
  LFiles := TDirectory.GetFiles(TPath.GetFullPath(TPath.Combine(
    TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Jpeg')), '*.jpg');
  TArray.Sort<string>(LFiles);
  LIndex := 0;
  for LFile in LFiles do
  begin
    Add('file-' + TPath.GetFileNameWithoutExtension(LFile), TFile.ReadAllBytes(LFile),
      LIndex in [0, 4]);
    Inc(LIndex);
  end;
end;

procedure TJpegCases.AddRaw;
var
  LValid: TBytes;
begin
  Add('raw-empty', nil);
  Add('raw-one-byte', TBytes.Create($FF));
  Add('raw-soi-only', TBytes.Create($FF, $D8));
  Add('raw-soi-eoi', TBytes.Create($FF, $D8, $FF, $D9));
  Add('raw-soi-soi', TBytes.Create($FF, $D8, $FF, $D8, $FF, $D9));
  Add('raw-text', TEncoding.ASCII.GetBytes('This is not a JPEG image at all'));
  Add('raw-zeros', Copy(TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)));
  Add('raw-soi-then-garbage', TBytes.Create($FF, $D8, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  Add('raw-red-image', HexToBytes(RED_IMAGE_HEX), True);
  Add('raw-gray-image', HexToBytes(GRAY_IMAGE_HEX), True);

  LValid := HexToBytes(RED_IMAGE_HEX);
  Add('raw-red-with-trailing-bytes', Concat(LValid, TBytes.Create(1, 2, 3, 4, $FF, $D8, $FF)));
  Add('raw-red-with-leading-bytes', Concat(TBytes.Create(0, 0), LValid));
  Add('raw-red-twice', Concat(LValid, LValid));
end;

procedure TJpegCases.AddPatches;
const
  FRAME_MARKERS: array[0..12] of Byte = (
    $C3, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CD, $CE, $CF, $C1, $C2);
var
  LBase: TBytes;
  LProgressive: TBytes;
  LSpec: TJpegSpec;
  LIndex: Integer;
  LFrame: Integer;
  LFrameLength: Integer;
begin
  LSpec := TJpegSpec.Make(24, 24, 3, 1000);
  LSpec.SetSampling(0, 2, 2);
  LBase := TJpegSynthesizer.Build(LSpec);

  // Fields of the frame header: length, precision, height, width, components
  Add('patch-sof-height-0', Patched(LBase, $C0, 3, [0, 0]));
  Add('patch-sof-width-0', Patched(LBase, $C0, 5, [0, 0]));
  Add('patch-sof-height-65500', Patched(LBase, $C0, 3, [$FF, $DC]));
  Add('patch-sof-height-65501', Patched(LBase, $C0, 3, [$FF, $DD]));
  Add('patch-sof-width-65501', Patched(LBase, $C0, 5, [$FF, $DD]));
  Add('patch-sof-precision-12', Patched(LBase, $C0, 2, [12]));
  Add('patch-sof-precision-0', Patched(LBase, $C0, 2, [0]));
  Add('patch-sof-components-0', Patched(LBase, $C0, 7, [0]));
  Add('patch-sof-components-4', Patched(LBase, $C0, 7, [4]));
  Add('patch-sof-length-short', Patched(LBase, $C0, 0, [0, 10]));
  Add('patch-sof-sampling-0', Patched(LBase, $C0, 9, [$01]));
  Add('patch-sof-sampling-5', Patched(LBase, $C0, 9, [$51]));
  Add('patch-sof-sampling-v5', Patched(LBase, $C0, 9, [$25]));
  Add('patch-sof-table-4', Patched(LBase, $C0, 10, [4]));
  Add('patch-sof-table-3', Patched(LBase, $C0, 10, [3]));
  Add('patch-sof-same-ids', Patched(LBase, $C0, 11, [1, $11, 1]));

  for LIndex := 0 to High(FRAME_MARKERS) do
    Add(Format('patch-sof-marker-%x', [FRAME_MARKERS[LIndex]]),
      Concat(Copy(LBase, 0, SegmentStart(LBase, $C0) - 1),
        TBytes.Create(FRAME_MARKERS[LIndex]),
        Copy(LBase, SegmentStart(LBase, $C0), Length(LBase))));

  // Scan header: length, components, tables, spectral selection
  Add('patch-sos-component-id', Patched(LBase, $DA, 3, [9]));
  Add('patch-sos-huffman-table-4', Patched(LBase, $DA, 4, [$44]));
  Add('patch-sos-huffman-table-15', Patched(LBase, $DA, 4, [$FF]));
  Add('patch-sos-count-0', Patched(LBase, $DA, 2, [0]));
  Add('patch-sos-count-5', Patched(LBase, $DA, 2, [5]));
  Add('patch-sos-count-2', Patched(LBase, $DA, 2, [2]));
  Add('patch-sos-spectral', Patched(LBase, $DA, 9, [5, 10, $11]));

  // Tables
  Add('patch-dqt-index-4', Patched(LBase, $DB, 2, [4]));
  Add('patch-dqt-precision', Patched(LBase, $DB, 2, [$10]));
  Add('patch-dht-index-4', Patched(LBase, $C4, 2, [4]));
  Add('patch-dht-index-ac-4', Patched(LBase, $C4, 2, [$14]));
  Add('patch-dht-count-too-many', Patched(LBase, $C4, 3, [255, 255]));
  Add('patch-dht-length', Patched(LBase, $C4, 0, [0, 9]));
  Add('patch-dri-length', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $DD, 0, 5, 0, 3, 0),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-dri-restart-5', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $DD, 0, 4, 0, 5),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-dri-restart-65535', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $DD, 0, 4, $FF, $FF),
    Copy(LBase, 2, Length(LBase))));

  // Tables of the Huffman code that are not valid
  Add('patch-dht-no-codes', Patched(LBase, $C4, 3,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
  Add('patch-dht-oversubscribed', Patched(LBase, $C4, 3,
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));

  // Markers where they do not belong
  LFrame := SegmentStart(LBase, $C0) - 2;
  LFrameLength := (Integer(LBase[LFrame + 2]) shl 8) + LBase[LFrame + 3] + 2;
  Add('patch-extra-sof', Concat(Copy(LBase, 0, LFrame + LFrameLength),
    Copy(LBase, LFrame, Length(LBase))));
  Add('patch-sos-before-sof', Concat(TBytes.Create($FF, $D8, $FF, $DA, 0, 8, 1, 1, 0, 0, 63, 0),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-eoi-before-sos', Concat(TBytes.Create($FF, $D8, $FF, $D9), Copy(LBase, 2, Length(LBase))));
  Add('patch-unknown-marker', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $02, 0, 2),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-dnl-marker', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $DC, 0, 4, 0, 24),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-dac-marker', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $CC, 0, 4, 0, 24),
    Copy(LBase, 2, Length(LBase))));
  Add('patch-rst-in-header', Concat(Copy(LBase, 0, 2), TBytes.Create($FF, $D3, $FF, $01),
    Copy(LBase, 2, Length(LBase))));

  // The scan of a progressive stream
  LSpec := TJpegSpec.Make(24, 24, 3, 1001);
  LSpec.FrameKind := jfkProgressive;
  LSpec.SetSampling(0, 2, 2);
  LSpec.Scans := TJpegSynthesizer.StandardProgression(3);
  LProgressive := TJpegSynthesizer.Build(LSpec);
  // The first scan has the three components: Ss, Se and Ah/Al follow them
  Add('patch-progressive-ss-gt-se', Patched(LProgressive, $DA, 9, [9, 3, 0]));
  Add('patch-progressive-se-64', Patched(LProgressive, $DA, 9, [1, 64, 0]));
  Add('patch-progressive-dc-with-se', Patched(LProgressive, $DA, 9, [0, 5, 0]));
  Add('patch-progressive-ac-three-components', Patched(LProgressive, $DA, 9, [1, 5, $01]));
  Add('patch-progressive-al-14', Patched(LProgressive, $DA, 11, [$0E]));
  Add('patch-progressive-ah-al', Patched(LProgressive, $DA, 11, [$31]));
end;

procedure TJpegCases.AddMutations;
const
  PIECES = 8;
var
  LBases: TArray<TJpegCase>;
  LMutable: Integer;
  LBase: TJpegCase;
  LIndex: Integer;
begin
  LBases := FCases.ToArray;
  for LMutable in FMutable.ToArray do
  begin
    LBase := LBases[LMutable];

    // Cut at several points
    for LIndex := 1 to PIECES - 1 do
      Add(Format('%s~cut%d', [LBase.Name, LIndex]),
        Truncate(LBase.Data, Length(LBase.Data) * LIndex div PIECES));
    Add(Format('%s~cut-last', [LBase.Name]), Truncate(LBase.Data, Length(LBase.Data) - 1));
    Add(Format('%s~cut-eoi', [LBase.Name]), Truncate(LBase.Data, Length(LBase.Data) - 2));

    // Some bytes changed
    for LIndex := 1 to 4 do
      Add(Format('%s~flip1-%d', [LBase.Name, LIndex]),
        Flip(LBase.Data, Cardinal(LMutable * 31 + LIndex), 1));
    for LIndex := 5 to 8 do
      Add(Format('%s~flip3-%d', [LBase.Name, LIndex]),
        Flip(LBase.Data, Cardinal(LMutable * 31 + LIndex), 3));
  end;
end;

end.
