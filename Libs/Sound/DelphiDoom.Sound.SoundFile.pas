{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - ISoundFile over decoded samples                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.SoundFile;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples;

type
  /// <summary>
  ///   One opened sound: serves the samples produced by an ISoundFormat,
  ///   converted to what the caller asks for
  /// </summary>
  /// <remarks>
  ///   Same contract as the sound of the C engine (TSndfileSoundFile): not
  ///   thread safe, no exception leaves a method of ISoundFile
  /// </remarks>
  TSoundFile = class(TInterfacedObject, ISoundFile)
  private
    type
      TTarget = (Bits16, Bits32, Float64);
  private
    FSamples: TSoundSamples;
    FPosition: Int64;
    FEndEventReported: Boolean;
    function Read(ATarget: TTarget; ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer;
    procedure ConvertToShort(ASource, ADestination: Pointer; ACount: Integer);
    procedure ConvertToInt(ASource, ADestination: Pointer; ACount: Integer);
    procedure ConvertToDouble(ASource, ADestination: Pointer; ACount: Integer);
  public
    /// <summary>Takes the ownership of ASamples</summary>
    constructor Create(ASamples: TSoundSamples);
    destructor Destroy; override;

    function GetInfo(out AInfo: TSoundFileInfo): Integer; stdcall;
    function ReadShort(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function ReadInt(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function ReadDouble(ABuffer: Pointer; AFrames: Int64;
      out AFramesRead: Int64): Integer; stdcall;
    function Seek(AFrame: Int64; AWhence: Integer;
      out APosition: Int64): Integer; stdcall;
    function GetErrorText: PAnsiChar; stdcall;
  end;

implementation

{$POINTERMATH ON}

uses
  DelphiDoom.Sound.Convert;

{ TSoundFile }

constructor TSoundFile.Create(ASamples: TSoundSamples);
begin
  inherited Create;
  FSamples := ASamples;
end;

destructor TSoundFile.Destroy;
begin
  FSamples.Free;
  inherited;
end;

function TSoundFile.GetInfo(out AInfo: TSoundFileInfo): Integer;
begin
  AInfo := FSamples.Info;
  Result := SNDFILE_OK;
end;

procedure TSoundFile.ConvertToShort(ASource, ADestination: Pointer;
  ACount: Integer);
var
  LIndex: Integer;
  LOut: PSmallInt;
begin
  LOut := ADestination;
  case FSamples.Kind of
    TSoundSampleKind.Int16:
      Move(ASource^, ADestination^, ACount * SizeOf(SmallInt));
    TSoundSampleKind.Int32:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := SmallInt(PInteger(ASource)[LIndex] shr 16);
    TSoundSampleKind.Float32:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := TSoundConvert.SingleToShort(PSingle(ASource)[LIndex]);
    TSoundSampleKind.Float64:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := TSoundConvert.DoubleToShort(PDouble(ASource)[LIndex]);
  end;
end;

procedure TSoundFile.ConvertToInt(ASource, ADestination: Pointer;
  ACount: Integer);
var
  LIndex: Integer;
  LOut: PInteger;
begin
  LOut := ADestination;
  case FSamples.Kind of
    TSoundSampleKind.Int16:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := Integer(PSmallInt(ASource)[LIndex]) shl 16;
    TSoundSampleKind.Int32:
      Move(ASource^, ADestination^, ACount * SizeOf(Integer));
    TSoundSampleKind.Float32:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := TSoundConvert.SingleToInt(PSingle(ASource)[LIndex]);
    TSoundSampleKind.Float64:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := TSoundConvert.DoubleToInt(PDouble(ASource)[LIndex]);
  end;
end;

procedure TSoundFile.ConvertToDouble(ASource, ADestination: Pointer;
  ACount: Integer);
const
  SCALE_16 = 1.0 / 32768.0;
  SCALE_32 = 1.0 / 2147483648.0;
var
  LIndex: Integer;
  LOut: PDouble;
begin
  LOut := ADestination;
  case FSamples.Kind of
    TSoundSampleKind.Int16:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := PSmallInt(ASource)[LIndex] * SCALE_16;
    TSoundSampleKind.Int32:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := PInteger(ASource)[LIndex] * SCALE_32;
    TSoundSampleKind.Float32:
      for LIndex := 0 to ACount - 1 do
        LOut[LIndex] := PSingle(ASource)[LIndex];
    TSoundSampleKind.Float64:
      Move(ASource^, ADestination^, ACount * SizeOf(Double));
  end;
end;

function TSoundFile.Read(ATarget: TTarget; ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
var
  LEvent: Integer;
  LChannels: Integer;
  LSource: PByte;
  LCount: Integer;
  LItemSize: Integer;
  LTarget: PByte;
  LDirect: Boolean;
  LRemaining, LSwap: Integer;
  LByte: Byte;
begin
  AFramesRead := 0;
  if (AFrames < 0) or ((AFrames > 0) and (ABuffer = nil)) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  if AFrames = 0 then
    Exit(SNDFILE_OK);

  try
    // At the end libsndfile clears the whole buffer
    if FPosition >= FSamples.Info.Frames then
    begin
      case ATarget of
        TTarget.Bits16: LItemSize := SizeOf(SmallInt);
        TTarget.Bits32: LItemSize := SizeOf(Integer);
      else
        LItemSize := SizeOf(Double);
      end;
      FillChar(ABuffer^, AFrames * FSamples.Info.Channels * LItemSize, 0);
      Exit(SNDFILE_OK);
    end;

    // libsndfile has nothing to read this with (the error is SFE_UNIMPLEMENTED)
    if FSamples.ReadsUnimplemented then
      Exit(18);

    AFramesRead := FSamples.Info.Frames - FPosition;
    if AFramesRead > AFrames then
      AFramesRead := AFrames;
    if AFramesRead <= 0 then
      AFramesRead := 0;
    // A codec may have fewer frames than the sound claims
    if FSamples.AvailableFrames >= 0 then
    begin
      LCount := 0;
      if FSamples.AvailableFrames > FPosition then
        LCount := Integer(FSamples.AvailableFrames - FPosition);
      if AFramesRead > LCount then
        AFramesRead := LCount;
    end;
    if (AFramesRead = 0) and (FSamples.ZeroFillChunk = 0) then
    begin
      // Nothing to give, but the decoder may have met an error looking for more
      Result := SNDFILE_OK;
      if not FEndEventReported then
        for LEvent := 0 to High(FSamples.ErrorEvents) do
          if (FSamples.ErrorEvents[LEvent].Frame >= FPosition) and
             (FSamples.ErrorEvents[LEvent].Frame < FPosition + AFrames) then
          begin
            Result := FSamples.ErrorEvents[LEvent].Code;
            FEndEventReported := True;
          end;
      Exit;
    end;

    LChannels := FSamples.Info.Channels;
    LCount := Integer(AFramesRead * LChannels);
    if LCount > 0 then
    begin
      LSource := @FSamples.Data[Integer(FPosition * LChannels *
        TSoundSamples.BytesPerSample(FSamples.Kind))];
      case ATarget of
        TTarget.Bits16:  ConvertToShort(LSource, ABuffer, LCount);
        TTarget.Bits32:    ConvertToInt(LSource, ABuffer, LCount);
      else
        ConvertToDouble(LSource, ABuffer, LCount);
      end;
    end;
    Inc(FPosition, AFramesRead);

    // The codecs that convert through a buffer clear what they did not fill
    if (AFramesRead < AFrames) and (FSamples.ZeroFillChunk <> 0) then
    begin
      case ATarget of
        TTarget.Bits16: LItemSize := SizeOf(SmallInt);
        TTarget.Bits32: LItemSize := SizeOf(Integer);
      else
        LItemSize := SizeOf(Double);
      end;
      LRemaining := Integer(AFrames * LChannels);
      if (ATarget <> TTarget.Bits16) and (FSamples.ZeroFillChunk > 0) then
      begin
        LSwap := (LCount div FSamples.ZeroFillChunk + 1) * FSamples.ZeroFillChunk;
        if LSwap < LRemaining then
          LRemaining := LSwap;
      end
      else if (ATarget <> TTarget.Bits16) and (FSamples.ZeroFillChunk = -2) then
      begin
        // Chunks of 4096 items, each written after what was really decoded
        LSwap := ((LRemaining + 4095) div 4096 - 1) * 4096;
        if LCount < LSwap then
          LSwap := LCount + LRemaining - ((LRemaining + 4095) div 4096 - 1) * 4096
        else
          LSwap := LSwap + LRemaining - LSwap;
        if LSwap < LRemaining then
          LRemaining := LSwap;
      end;
      if FSamples.ZeroFillChunk = -4 then
      begin
        // DWVW: the converters write the whole buffer they decoded through
        // (chunks of 2048), the decoder one item past the sound
        if ATarget <> TTarget.Bits32 then
        begin
          LSwap := (LCount div 2048 + 1) * 2048;
          if LSwap > LRemaining then
            LSwap := LRemaining;
          if LSwap > LCount then
            FillChar((PByte(ABuffer) + LCount * LItemSize)^, (LSwap - LCount) * LItemSize, 0);
        end;
        if FSamples.HasTrailingItem and (LCount < LRemaining) then
          case ATarget of
            TTarget.Bits16:
              PSmallInt(PByte(ABuffer) + LCount * LItemSize)^ :=
                SmallInt(Integer(FSamples.TrailingItem div 65536) - Ord((FSamples.TrailingItem < 0) and ((FSamples.TrailingItem mod 65536) <> 0)));
            TTarget.Bits32:
              PInteger(PByte(ABuffer) + LCount * LItemSize)^ := FSamples.TrailingItem;
          else
            PDouble(PByte(ABuffer) + LCount * LItemSize)^ := FSamples.TrailingItem * (1.0 / 2147483648.0);
          end;
      end
      else
        FillChar((PByte(ABuffer) + LCount * LItemSize)^, (LRemaining - LCount) * LItemSize, 0);
    end;

    // A read that ran into what follows the sound has its tail cleared
    LDirect := FSamples.ReadsDirectly and
      (((ATarget = TTarget.Bits16) and (FSamples.Kind = TSoundSampleKind.Int16)) or
       ((ATarget = TTarget.Bits32) and (FSamples.Kind = TSoundSampleKind.Int32)));
    if (AFramesRead < AFrames) and
      ((FSamples.ExtraItems > 0) or (LDirect and
       (FSamples.BigEndian or (Length(FSamples.PartialBytes) > 0)))) then
    begin
      case ATarget of
        TTarget.Bits16: LItemSize := SizeOf(SmallInt);
        TTarget.Bits32: LItemSize := SizeOf(Integer);
      else
        LItemSize := SizeOf(Double);
      end;
      if FSamples.ExtraItems >= LChannels then
        FillChar((PByte(ABuffer) + LCount * LItemSize)^,
          (AFrames - AFramesRead) * LChannels * LItemSize, 0)
      else
      begin
        // Less than a frame: what was read past the end stays in the buffer
        LTarget := PByte(ABuffer) + LCount * LItemSize;
        if FSamples.ExtraItems > 0 then
        begin
          LSource := @FSamples.Tail[0];
          case ATarget of
            TTarget.Bits16: ConvertToShort(LSource, LTarget, Integer(FSamples.ExtraItems));
            TTarget.Bits32: ConvertToInt(LSource, LTarget, Integer(FSamples.ExtraItems));
          else
            ConvertToDouble(LSource, LTarget, Integer(FSamples.ExtraItems));
          end;
          Inc(LTarget, FSamples.ExtraItems * LItemSize);
        end;
        // Same width as the file: libsndfile reads into the buffer itself
        if LDirect then
        begin
          if Length(FSamples.PartialBytes) > 0 then
            Move(FSamples.PartialBytes[0], LTarget^, Length(FSamples.PartialBytes));
          if FSamples.BigEndian then
          begin
            // It swaps all the items it was asked for, those it did not fill too
            LRemaining := Integer(AFrames * LChannels) - LCount - Integer(FSamples.ExtraItems);
            while LRemaining > 0 do
            begin
              for LSwap := 0 to LItemSize div 2 - 1 do
              begin
                LByte := LTarget[LSwap];
                LTarget[LSwap] := LTarget[LItemSize - 1 - LSwap];
                LTarget[LItemSize - 1 - LSwap] := LByte;
              end;
              Inc(LTarget, LItemSize);
              Dec(LRemaining);
            end;
          end;
        end;
      end;
    end;
    Result := SNDFILE_OK;
    // An error met while decoding what this read asked for
    for LEvent := 0 to High(FSamples.ErrorEvents) do
      if (FSamples.ErrorEvents[LEvent].Frame >= FPosition - AFramesRead) and
         (FSamples.ErrorEvents[LEvent].Frame < FPosition - AFramesRead + AFrames) then
      begin
        Result := FSamples.ErrorEvents[LEvent].Code;
        // The error found past the last frame comes once
        if LEvent = High(FSamples.ErrorEvents) then
          FEndEventReported := True;
      end;
  except
    AFramesRead := 0;
    Result := SNDFILE_ERR_UNEXPECTED;
  end;
end;

function TSoundFile.ReadShort(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := Read(TTarget.Bits16, ABuffer, AFrames, AFramesRead);
end;

function TSoundFile.ReadInt(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := Read(TTarget.Bits32, ABuffer, AFrames, AFramesRead);
end;

function TSoundFile.ReadDouble(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  Result := Read(TTarget.Float64, ABuffer, AFrames, AFramesRead);
end;

function TSoundFile.Seek(AFrame: Int64; AWhence: Integer;
  out APosition: Int64): Integer;
var
  LTarget: Int64;
begin
  APosition := 0;
  // The sounds that cannot be seeked (GSM 6.10) refuse whatever the request
  if FSamples.Info.Seekable = 0 then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);
  case AWhence of
    SNDFILE_SEEK_SET: LTarget := AFrame;
    SNDFILE_SEEK_CUR: LTarget := FPosition + AFrame;
    SNDFILE_SEEK_END: LTarget := FSamples.Info.Frames + AFrame;
  else
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);
  end;

  // libsndfile refuses to move outside of the sound
  if (LTarget < 0) or (LTarget > FSamples.Info.Frames) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);
  // DWVW can only be taken back to its start
  if FSamples.RewindOnly and (LTarget <> 0) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);
  if (FSamples.SeekLimit >= 0) and (LTarget >= FSamples.SeekLimit) and
     (LTarget <> FSamples.Info.Frames) then
    Exit(SNDFILE_ERR_INVALID_ARGUMENT);

  FPosition := LTarget;
  FEndEventReported := False;
  APosition := LTarget;
  Result := SNDFILE_OK;
end;

function TSoundFile.GetErrorText: PAnsiChar;
begin
  Result := PAnsiChar('No Error.');
end;

end.
