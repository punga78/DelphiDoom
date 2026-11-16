{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - reads the markers of the stream                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.MarkerReader;

interface

uses
  DelphiDoom.Jpeg.ByteSource, DelphiDoom.Jpeg.Frame;

type
  /// <summary>
  ///   Where ReadMarkers stopped
  /// </summary>
  TJpegMarkerStop = (jmsStartOfScan, jmsEndOfImage);

  /// <summary>
  ///   Reads the marker segments of the stream into a TJpegFrame (size of the
  ///   image, components, tables, restart interval, color markers, scan
  ///   header) and finds the restart markers that the entropy decoder needs
  /// </summary>
  /// <remarks>
  ///   Port of jdmarker.c of libjpeg 6b. The source never runs out of data
  ///   (see TJpegByteSource), so the "suspension" of the original, which
  ///   needed all the saved state of the segment readers, does not exist and
  ///   every segment is read in one go. The warnings of the original (extra
  ///   bytes between markers, wrong version of JFIF, restart markers out of
  ///   order) are not reported: nobody reads them. Only the markers that
  ///   change the decoding are kept: the comments and the application markers
  ///   other than JFIF (APP0) and Adobe (APP14) are skipped
  /// </remarks>
  TJpegMarkerReader = class
  private
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FUnreadMarker: Integer;
    FSawStartOfImage: Boolean;
    FSawFrame: Boolean;
    FNextRestartNumber: Integer;
    function ReadLength: Integer;
    procedure ReadStartOfImage;
    procedure ReadFrameHeader(AProgressive, AArithmetic: Boolean);
    procedure ReadScanHeader;
    procedure ReadHuffmanTables;
    procedure ReadQuantizationTables;
    procedure ReadRestartInterval;
    procedure ReadApplicationMarker;
    procedure ExamineApp0(const AData: array of Byte; ACount: Integer);
    procedure ExamineApp14(const AData: array of Byte; ACount: Integer);
    procedure SkipSegment;
    procedure FindNextMarker;
    procedure FindFirstMarker;
  public
    constructor Create(ASource: TJpegByteSource; AFrame: TJpegFrame);

    /// <summary>
    ///   Reads markers until the header of a scan or the end of the image
    /// </summary>
    /// <exception cref="EJpegDecodeException">The stream is wrong or not supported</exception>
    function ReadMarkers: TJpegMarkerStop;

    /// <summary>
    ///   Reads the restart marker that the entropy decoder expects. When
    ///   another marker is found instead (data lost or added) it goes on
    ///   reading until it can tell what to do, as jpeg_resync_to_restart of
    ///   libjpeg does
    /// </summary>
    procedure ReadRestartMarker;

    /// <summary>
    ///   The marker that was found but not used yet, or 0. The entropy decoder
    ///   sets it when its data run into a marker
    /// </summary>
    property UnreadMarker: Integer read FUnreadMarker write FUnreadMarker;

    /// <summary>True once a frame header (SOFn) was read</summary>
    property SawFrame: Boolean read FSawFrame;
  end;

implementation

uses
  DelphiDoom.Jpeg.Types;

const
  M_SOF0 = $C0;
  M_SOF1 = $C1;
  M_SOF2 = $C2;
  M_SOF3 = $C3;
  M_DHT = $C4;
  M_SOF5 = $C5;
  M_SOF6 = $C6;
  M_SOF7 = $C7;
  M_JPG = $C8;
  M_SOF9 = $C9;
  M_SOF10 = $CA;
  M_SOF11 = $CB;
  M_DAC = $CC;
  M_SOF13 = $CD;
  M_SOF14 = $CE;
  M_SOF15 = $CF;
  M_RST0 = $D0;
  M_RST7 = $D7;
  M_SOI = $D8;
  M_EOI = $D9;
  M_SOS = $DA;
  M_DQT = $DB;
  M_DNL = $DC;
  M_DRI = $DD;
  M_APP0 = $E0;
  M_APP14 = $EE;
  M_APP15 = $EF;
  M_COM = $FE;
  M_TEM = $01;

  // The bytes that are read of a JFIF or Adobe marker
  APP0_DATA_LENGTH = 14;
  APP14_DATA_LENGTH = 12;
  APPN_DATA_LENGTH = 14;

{ TJpegMarkerReader }

constructor TJpegMarkerReader.Create(ASource: TJpegByteSource; AFrame: TJpegFrame);
begin
  inherited Create;
  FSource := ASource;
  FFrame := AFrame;
end;

function TJpegMarkerReader.ReadLength: Integer;
begin
  Result := FSource.ReadByte shl 8;
  Inc(Result, FSource.ReadByte);
end;

procedure TJpegMarkerReader.ReadStartOfImage;
begin
  if FSawStartOfImage then
    EJpegDecodeException.Fail(jdeDuplicateStartOfImage);
  FFrame.StartOfImage;
  FSawStartOfImage := True;
end;

procedure TJpegMarkerReader.ReadFrameHeader(AProgressive, AArithmetic: Boolean);
var
  LLength: Integer;
  LPrecision: Integer;
  LHeight: Integer;
  LWidth: Integer;
  LCount: Integer;
  LIndex: Integer;
  LValue: Integer;
  LComponent: PJpegComponentInfo;
begin
  LLength := ReadLength;
  LPrecision := FSource.ReadByte;
  LHeight := FSource.ReadByte shl 8;
  Inc(LHeight, FSource.ReadByte);
  LWidth := FSource.ReadByte shl 8;
  Inc(LWidth, FSource.ReadByte);
  LCount := FSource.ReadByte;
  Dec(LLength, 8);

  if FSawFrame then
    EJpegDecodeException.Fail(jdeDuplicateFrame);
  if (LHeight <= 0) or (LWidth <= 0) or (LCount <= 0) then
    EJpegDecodeException.Fail(jdeEmptyImage);
  if LLength <> LCount * 3 then
    EJpegDecodeException.Fail(jdeBadLength);

  FFrame.SetFrameHeader(LWidth, LHeight, LPrecision, LCount, AProgressive,
    AArithmetic);
  for LIndex := 0 to LCount - 1 do
  begin
    LComponent := FFrame.ComponentByIndex[LIndex];
    LComponent^.Id := FSource.ReadByte;
    LValue := FSource.ReadByte;
    LComponent^.Horizontal := (LValue shr 4) and 15;
    LComponent^.Vertical := LValue and 15;
    LComponent^.QuantizationNumber := FSource.ReadByte;
  end;
  FSawFrame := True;
end;

procedure TJpegMarkerReader.ReadScanHeader;
var
  LLength: Integer;
  LCount: Integer;
  LIndex: Integer;
  LComponentIndex: Integer;
  LId: Integer;
  LTables: Integer;
  LValue: Integer;
  LComponent: PJpegComponentInfo;
  LScan: PJpegScanInfo;
  LFound: Boolean;
begin
  if not FSawFrame then
    EJpegDecodeException.Fail(jdeScanBeforeFrame);

  LLength := ReadLength;
  LCount := FSource.ReadByte;
  if (LLength <> LCount * 2 + 6) or (LCount < 1) or
     (LCount > JPEG_MAX_COMPONENTS_IN_SCAN) then
    EJpegDecodeException.Fail(jdeBadLength);

  LScan := FFrame.Scan;
  LScan^.ComponentCount := LCount;
  for LIndex := 0 to LCount - 1 do
  begin
    LId := FSource.ReadByte;
    LTables := FSource.ReadByte;

    // The first component of the frame that has this identifier
    LFound := False;
    LComponentIndex := 0;
    while LComponentIndex < FFrame.ComponentCount do
    begin
      if FFrame.ComponentByIndex[LComponentIndex]^.Id = LId then
      begin
        LFound := True;
        Break;
      end;
      Inc(LComponentIndex);
    end;
    if not LFound then
      EJpegDecodeException.Fail(jdeBadComponentId);

    LComponent := FFrame.ComponentByIndex[LComponentIndex];
    LScan^.Components[LIndex] := LComponentIndex;
    LComponent^.DcTableNumber := (LTables shr 4) and 15;
    LComponent^.AcTableNumber := LTables and 15;
  end;

  LScan^.SpectralStart := FSource.ReadByte;
  LScan^.SpectralEnd := FSource.ReadByte;
  LValue := FSource.ReadByte;
  LScan^.ApproximationHigh := (LValue shr 4) and 15;
  LScan^.ApproximationLow := LValue and 15;

  FNextRestartNumber := 0;
end;

procedure TJpegMarkerReader.ReadHuffmanTables;
var
  LLength: Integer;
  LBits: array[0..16] of Byte;
  LValues: array[0..255] of Byte;
  LIndex: Integer;
  LCount: Integer;
  LNumber: Integer;
  LAlternating: Boolean;
  LDefinition: PJpegHuffmanDefinition;
begin
  LLength := ReadLength;
  Dec(LLength, 2);

  while LLength > 16 do
  begin
    LNumber := FSource.ReadByte;

    LBits[0] := 0;
    LCount := 0;
    for LIndex := 1 to 16 do
    begin
      LBits[LIndex] := Byte(FSource.ReadByte);
      Inc(LCount, LBits[LIndex]);
    end;
    Dec(LLength, 1 + 16);

    if (LCount > 256) or (LCount > LLength) then
      EJpegDecodeException.Fail(jdeBadHuffmanTable);

    FillChar(LValues, SizeOf(LValues), 0);
    for LIndex := 0 to LCount - 1 do
      LValues[LIndex] := Byte(FSource.ReadByte);
    Dec(LLength, LCount);

    // Bit 4 of the number tells an AC table
    LAlternating := (LNumber and $10) <> 0;
    if LAlternating then
      Dec(LNumber, $10);
    if (LNumber < 0) or (LNumber >= JPEG_HUFFMAN_TABLES) then
      EJpegDecodeException.Fail(jdeBadHuffmanTableIndex);

    if LAlternating then
      LDefinition := FFrame.AcDefinition[LNumber]
    else
      LDefinition := FFrame.DcDefinition[LNumber];
    LDefinition^.Defined := True;
    Move(LBits, LDefinition^.Bits, SizeOf(LBits));
    Move(LValues, LDefinition^.Values, SizeOf(LValues));
  end;

  if LLength <> 0 then
    EJpegDecodeException.Fail(jdeBadLength);
end;

procedure TJpegMarkerReader.ReadQuantizationTables;
var
  LLength: Integer;
  LNumber: Integer;
  LPrecision: Integer;
  LIndex: Integer;
  LValue: Integer;
  LTable: PJpegQuantizationTable;
begin
  LLength := ReadLength;
  Dec(LLength, 2);

  while LLength > 0 do
  begin
    LNumber := FSource.ReadByte;
    LPrecision := LNumber shr 4;
    LNumber := LNumber and $0F;
    if LNumber >= JPEG_QUANTIZATION_TABLES then
      EJpegDecodeException.Fail(jdeBadQuantizationTableIndex);

    LTable := FFrame.Quantization[LNumber];
    LTable^.Defined := True;
    for LIndex := 0 to JPEG_DCT_SIZE2 - 1 do
    begin
      if LPrecision <> 0 then
      begin
        LValue := FSource.ReadByte shl 8;
        Inc(LValue, FSource.ReadByte);
      end
      else
        LValue := FSource.ReadByte;
      // The table is in zigzag order in the stream
      LTable^.Values[JPEG_NATURAL_ORDER[LIndex]] := Word(LValue);
    end;

    Dec(LLength, JPEG_DCT_SIZE2 + 1);
    if LPrecision <> 0 then
      Dec(LLength, JPEG_DCT_SIZE2);
  end;

  if LLength <> 0 then
    EJpegDecodeException.Fail(jdeBadLength);
end;

procedure TJpegMarkerReader.ReadRestartInterval;
var
  LInterval: Integer;
begin
  if ReadLength <> 4 then
    EJpegDecodeException.Fail(jdeBadLength);
  LInterval := FSource.ReadByte shl 8;
  Inc(LInterval, FSource.ReadByte);
  FFrame.RestartInterval := LInterval;
end;

procedure TJpegMarkerReader.ExamineApp0(const AData: array of Byte; ACount: Integer);
begin
  // JFIF: the identifier "JFIF" and a zero
  if (ACount >= APP0_DATA_LENGTH) and (AData[0] = $4A) and (AData[1] = $46) and
     (AData[2] = $49) and (AData[3] = $46) and (AData[4] = 0) then
    FFrame.SawJfif := True;
end;

procedure TJpegMarkerReader.ExamineApp14(const AData: array of Byte; ACount: Integer);
begin
  // Adobe: the identifier "Adobe", then the code of the color transform
  if (ACount >= APP14_DATA_LENGTH) and (AData[0] = $41) and (AData[1] = $64) and
     (AData[2] = $6F) and (AData[3] = $62) and (AData[4] = $65) then
  begin
    FFrame.SawAdobe := True;
    FFrame.AdobeTransform := AData[11];
  end;
end;

procedure TJpegMarkerReader.ReadApplicationMarker;
var
  LLength: Integer;
  LData: array[0..APPN_DATA_LENGTH - 1] of Byte;
  LCount: Integer;
  LIndex: Integer;
begin
  LLength := ReadLength;
  Dec(LLength, 2);

  if LLength >= APPN_DATA_LENGTH then
    LCount := APPN_DATA_LENGTH
  else if LLength > 0 then
    LCount := LLength
  else
    LCount := 0;
  FillChar(LData, SizeOf(LData), 0);
  for LIndex := 0 to LCount - 1 do
    LData[LIndex] := Byte(FSource.ReadByte);
  Dec(LLength, LCount);

  if FUnreadMarker = M_APP0 then
    ExamineApp0(LData, LCount)
  else
    ExamineApp14(LData, LCount);

  if LLength > 0 then
    FSource.Skip(LLength);
end;

procedure TJpegMarkerReader.SkipSegment;
var
  LLength: Integer;
begin
  LLength := ReadLength;
  Dec(LLength, 2);
  if LLength > 0 then
    FSource.Skip(LLength);
end;

procedure TJpegMarkerReader.FindNextMarker;
var
  LByte: Integer;
begin
  repeat
    // Anything that is not FF is not a marker and is dropped
    LByte := FSource.ReadByte;
    while LByte <> $FF do
      LByte := FSource.ReadByte;

    // FF can be repeated as fill; FF 00 is not a marker
    repeat
      LByte := FSource.ReadByte;
    until LByte <> $FF;
    if LByte <> 0 then
      Break;
  until False;
  FUnreadMarker := LByte;
end;

procedure TJpegMarkerReader.FindFirstMarker;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FSource.ReadByte;
  LSecond := FSource.ReadByte;
  if (LFirst <> $FF) or (LSecond <> M_SOI) then
    EJpegDecodeException.Fail(jdeNotJpeg);
  FUnreadMarker := LSecond;
end;

function TJpegMarkerReader.ReadMarkers: TJpegMarkerStop;
begin
  repeat
    if FUnreadMarker = 0 then
    begin
      if not FSawStartOfImage then
        FindFirstMarker
      else
        FindNextMarker;
    end;

    case FUnreadMarker of
      M_SOI:
        ReadStartOfImage;
      M_SOF0, M_SOF1:
        ReadFrameHeader(False, False);
      M_SOF2:
        ReadFrameHeader(True, False);
      M_SOF9:
        ReadFrameHeader(False, True);
      M_SOF10:
        ReadFrameHeader(True, True);
      M_SOF3, M_SOF5, M_SOF6, M_SOF7, M_JPG, M_SOF11, M_SOF13, M_SOF14, M_SOF15:
        EJpegDecodeException.Fail(jdeUnsupportedFrame);
      M_SOS:
        begin
          ReadScanHeader;
          FUnreadMarker := 0;
          Exit(jmsStartOfScan);
        end;
      M_EOI:
        begin
          FUnreadMarker := 0;
          Exit(jmsEndOfImage);
        end;
      M_DHT:
        ReadHuffmanTables;
      M_DQT:
        ReadQuantizationTables;
      M_DRI:
        ReadRestartInterval;
      M_APP0, M_APP14:
        ReadApplicationMarker;
      M_APP0 + 1 .. M_APP14 - 1, M_APP15, M_DAC, M_COM, M_DNL:
        // Not read: there are no arithmetic tables to keep and a comment or
        // another application marker does not change the decoding
        SkipSegment;
      M_RST0 .. M_RST7, M_TEM:
        // Markers without data
        ;
    else
      EJpegDecodeException.Fail(jdeUnknownMarker);
    end;
    FUnreadMarker := 0;
  until False;
end;

procedure TJpegMarkerReader.ReadRestartMarker;
var
  LMarker: Integer;
  LDesired: Integer;
  LAction: Integer;
begin
  if FUnreadMarker = 0 then
    FindNextMarker;

  if FUnreadMarker = M_RST0 + FNextRestartNumber then
    // The marker that was expected
    FUnreadMarker := 0
  else
  begin
    // jpeg_resync_to_restart: the marker is not the one that is expected, so
    // either data was lost (the marker is for a later restart) or there is
    // data that should not be there (an earlier one). Actions: 1 drop the
    // marker and go on, 2 look for the next marker, 3 leave the marker where
    // it is
    LDesired := FNextRestartNumber;
    LMarker := FUnreadMarker;
    repeat
      if LMarker < M_SOF0 then
        LAction := 2
      else if (LMarker < M_RST0) or (LMarker > M_RST7) then
        LAction := 3
      else if (LMarker = M_RST0 + ((LDesired + 1) and 7)) or
              (LMarker = M_RST0 + ((LDesired + 2) and 7)) then
        LAction := 3
      else if (LMarker = M_RST0 + ((LDesired - 1) and 7)) or
              (LMarker = M_RST0 + ((LDesired - 2) and 7)) then
        LAction := 2
      else
        LAction := 1;

      case LAction of
        1:
          begin
            FUnreadMarker := 0;
            Break;
          end;
        2:
          begin
            FindNextMarker;
            LMarker := FUnreadMarker;
          end;
      else
        Break;
      end;
    until False;
  end;

  FNextRestartNumber := (FNextRestartNumber + 1) and 7;
end;

end.
