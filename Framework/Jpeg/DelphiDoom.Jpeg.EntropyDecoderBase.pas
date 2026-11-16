{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - what the two entropy decoders have in common             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.EntropyDecoderBase;

interface

uses
  DelphiDoom.Jpeg.BitReader, DelphiDoom.Jpeg.EntropyDecoder, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.HuffmanTable, DelphiDoom.Jpeg.MarkerReader,
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   The part of the decoding that does not depend on the kind of coding:
  ///   the restart markers and the construction of the tables of a scan
  /// </summary>
  TJpegEntropyDecoderBase = class(TInterfacedObject, IJpegEntropyDecoder)
  private
    FRestartsToGo: Integer;
    procedure ProcessRestart;
  protected
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FBits: TJpegBitReader;
    FLastDc: array[0..JPEG_MAX_COMPONENTS_IN_SCAN - 1] of Integer;

    /// <summary>
    ///   Builds the table that the number selects among the definitions
    ///   that the markers gave
    /// </summary>
    /// <exception cref="EJpegDecodeException">There is no such table or it is not valid</exception>
    function BuildTable(ANumber: Integer; AIsDc: Boolean): TJpegHuffmanTable;

    /// <summary>
    ///   Puts the state that restarts at a restart marker back to the start
    ///   (the predictions of the DC; the progressive decoder has more)
    /// </summary>
    procedure ResetState; virtual;

    /// <summary>
    ///   Starts the common state of a scan
    /// </summary>
    procedure StartCommon;

    /// <summary>
    ///   Decodes the blocks of a MCU
    /// </summary>
    procedure DecodeBlocks(const ABlocks: TJpegBlockPointers); virtual; abstract;
  public
    constructor Create(AFrame: TJpegFrame; AMarkers: TJpegMarkerReader;
      ABits: TJpegBitReader);

    procedure StartScan; virtual; abstract;
    procedure DecodeMcu(const ABlocks: TJpegBlockPointers);
  end;

implementation

{ TJpegEntropyDecoderBase }

constructor TJpegEntropyDecoderBase.Create(AFrame: TJpegFrame;
  AMarkers: TJpegMarkerReader; ABits: TJpegBitReader);
begin
  inherited Create;
  FFrame := AFrame;
  FMarkers := AMarkers;
  FBits := ABits;
end;

function TJpegEntropyDecoderBase.BuildTable(ANumber: Integer;
  AIsDc: Boolean): TJpegHuffmanTable;
var
  LDefinition: PJpegHuffmanDefinition;
begin
  if (ANumber < 0) or (ANumber >= JPEG_HUFFMAN_TABLES) then
    EJpegDecodeException.Fail(jdeMissingHuffmanTable);
  if AIsDc then
    LDefinition := FFrame.DcDefinition[ANumber]
  else
    LDefinition := FFrame.AcDefinition[ANumber];
  if not LDefinition^.Defined then
    EJpegDecodeException.Fail(jdeMissingHuffmanTable);
  Result := TJpegHuffmanTable.Create(LDefinition^, AIsDc);
end;

procedure TJpegEntropyDecoderBase.ResetState;
begin
  FillChar(FLastDc, SizeOf(FLastDc), 0);
end;

procedure TJpegEntropyDecoderBase.StartCommon;
begin
  FillChar(FLastDc, SizeOf(FLastDc), 0);
  FBits.Start;
  FRestartsToGo := FFrame.RestartInterval;
end;

procedure TJpegEntropyDecoderBase.ProcessRestart;
begin
  // The bits that are left are padding
  FBits.DiscardBits;
  FMarkers.ReadRestartMarker;
  ResetState;
  FRestartsToGo := FFrame.RestartInterval;

  // The data can be read again only if the marker was used
  if FMarkers.UnreadMarker = 0 then
    FBits.InsufficientData := False;
end;

procedure TJpegEntropyDecoderBase.DecodeMcu(const ABlocks: TJpegBlockPointers);
begin
  if FFrame.RestartInterval <> 0 then
    if FRestartsToGo = 0 then
      ProcessRestart;

  DecodeBlocks(ABlocks);

  Dec(FRestartsToGo);
end;

end.
