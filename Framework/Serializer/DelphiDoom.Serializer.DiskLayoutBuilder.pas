{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the builder of the layouts on disk         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.DiskLayoutBuilder;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  DelphiDoom.Serializer.Intf,
  DelphiDoom.Serializer.Types;

type
  /// <summary>
  ///   Works out the layout on disk of a record from its type information. The layout on disk is the one
  ///   that the 32 bit compiler gives to the same declaration: every pointer and every NativeInt is 4
  ///   bytes, aligned to 4, and the other fields keep their size and their alignment. The builder first
  ///   proves that it understands the record, working out again the layout in memory of the running
  ///   program (offsets and size must be the ones of the compiler), then applies the same rules with the
  ///   sizes of 32 bit. A field with an unnamed type has no type information: it is taken as plain bytes
  ///   when that is certain, otherwise it must be described (DescribeArray)
  /// </summary>
  TDiskLayoutBuilder = class
  strict private
    type
      TShape = record
        NativeSize: Integer;
        NativeAlign: Integer;
        DiskSize: Integer;
        DiskAlign: Integer;
        /// <summary>Plain bytes of a field with an unnamed type: the size includes the padding after it</summary>
        Opaque: Boolean;
        Kind: string;
        Segments: TArray<TDiskLayoutSegment>;
      end;

      TDescription = record
        Element: PTypeInfo;
        Count: Integer;
      end;

      TItem = record
        Name: string;
        Offset: Integer;
        Shape: TShape;
      end;
    const
      DISK_REFERENCE_SIZE = 4;
      MAX_OPAQUE_ALIGN = 4;
  strict private
    FContext: TRttiContext;
    FDescriptions: TDictionary<string, TDescription>;
    FShapes: TDictionary<PTypeInfo, TShape>;
    class function RoundUp(AValue: Integer; AAlign: Integer): Integer; static;
    class function Smaller(ALeft: Integer; ARight: Integer): Integer; static;
    class function DescriptionKey(const ARecord: PTypeInfo; const AField: string): string; static;
    class function RawShape(ASize: Integer; AAlign: Integer; const AKind: string): TShape; static;
    class function ReferenceShape: TShape; static;
    class function OpaqueShape(AOffset: Integer; ASpan: Integer): TShape; static;
    class function ArrayShape(const AElement: TShape; ACount: Integer): TShape; static;
    class function HasReferences(const AShape: TShape): Boolean; static;
    class function SameShape(const ALeft: TShape; const ARight: TShape): Boolean; static;
    class procedure Simplify(var AShape: TShape); static;
    class function Merge(const ASegments: TArray<TDiskLayoutSegment>): TArray<TDiskLayoutSegment>; static;
    class function NativeFits(var AItems: TArray<TItem>; ACap: Integer; ATotal: Integer;
      out ARecordAlign: Integer; out AWhere: string): Boolean; static;
    function OrdinalShape(const AType: TRttiType): TShape;
    function FieldShape(const ARecord: TRttiType; const AField: TRttiField; ASpan: Integer): TShape;
    function CollectItems(const ARecord: TRttiType): TArray<TItem>;
    function RecordShape(const ARecord: TRttiType; out AFieldLines: TArray<string>): TShape;
    function ShapeOf(const ATypeInfo: PTypeInfo; const AOwner: string; const AField: string): TShape;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The field AField of the record ARecord, whose type has no name, is ACount elements of AElement</summary>
    procedure DescribeArray(const ARecord: PTypeInfo; const AField: string; const AElement: PTypeInfo;
      ACount: Integer);
    /// <summary>The layout of a record; ESerializerException when the record cannot be understood</summary>
    function Build(const ATypeInfo: PTypeInfo): IDiskLayout;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Serializer.DiskLayout;

const
  SNativeIntName = 'NativeInt';
  SNativeUIntName = 'NativeUInt';

{ TDiskLayoutBuilder }

constructor TDiskLayoutBuilder.Create;
begin
  inherited Create;
  FContext := TRttiContext.Create;
  FDescriptions := TDictionary<string, TDescription>.Create;
  FShapes := TDictionary<PTypeInfo, TShape>.Create;
end;

destructor TDiskLayoutBuilder.Destroy;
begin
  FShapes.Free;
  FDescriptions.Free;
  FContext.Free;
  inherited Destroy;
end;

class function TDiskLayoutBuilder.RoundUp(AValue: Integer; AAlign: Integer): Integer;
begin
  Result := ((AValue + AAlign - 1) div AAlign) * AAlign;
end;

class function TDiskLayoutBuilder.Smaller(ALeft: Integer; ARight: Integer): Integer;
begin
  if ALeft < ARight then
    Result := ALeft
  else
    Result := ARight;
end;

class function TDiskLayoutBuilder.DescriptionKey(const ARecord: PTypeInfo; const AField: string): string;
begin
  Result := IntToHex(NativeUInt(ARecord), 2 * SizeOf(Pointer)) + '.' + LowerCase(AField);
end;

class function TDiskLayoutBuilder.RawShape(ASize: Integer; AAlign: Integer; const AKind: string): TShape;
begin
  Result := Default(TShape);
  Result.NativeSize := ASize;
  Result.NativeAlign := AAlign;
  Result.DiskSize := ASize;
  Result.DiskAlign := AAlign;
  Result.Kind := AKind;
  SetLength(Result.Segments, 1);
  Result.Segments[0] := Default(TDiskLayoutSegment);
  Result.Segments[0].Size := ASize;
end;

class function TDiskLayoutBuilder.ReferenceShape: TShape;
begin
  Result := Default(TShape);
  Result.NativeSize := SizeOf(Pointer);
  Result.NativeAlign := SizeOf(Pointer);
  Result.DiskSize := DISK_REFERENCE_SIZE;
  Result.DiskAlign := DISK_REFERENCE_SIZE;
  Result.Kind := 'ref';
  SetLength(Result.Segments, 1);
  Result.Segments[0] := Default(TDiskLayoutSegment);
  Result.Segments[0].Reference := True;
end;

class function TDiskLayoutBuilder.OpaqueShape(AOffset: Integer; ASpan: Integer): TShape;
var
  LAlign: Integer;
begin
  // the true alignment is not known: the largest one that the place and the size allow, up to 4
  LAlign := MAX_OPAQUE_ALIGN;
  while (LAlign > 1) and ((AOffset mod LAlign <> 0) or (ASpan mod LAlign <> 0)) do
    LAlign := LAlign div 2;
  Result := RawShape(ASpan, LAlign, 'bytes');
  Result.Opaque := True;
end;

class function TDiskLayoutBuilder.ArrayShape(const AElement: TShape; ACount: Integer): TShape;
var
  LIndex: Integer;
  LSegment: Integer;
  LCount: Integer;
begin
  Result := Default(TShape);
  Result.NativeSize := AElement.NativeSize * ACount;
  Result.NativeAlign := AElement.NativeAlign;
  Result.DiskSize := AElement.DiskSize * ACount;
  Result.DiskAlign := AElement.DiskAlign;
  Result.Kind := 'array';
  LCount := Length(AElement.Segments);
  SetLength(Result.Segments, LCount * ACount);
  for LIndex := 0 to ACount - 1 do
    for LSegment := 0 to LCount - 1 do
    begin
      Result.Segments[LIndex * LCount + LSegment] := AElement.Segments[LSegment];
      Inc(Result.Segments[LIndex * LCount + LSegment].NativeOffset, LIndex * AElement.NativeSize);
      Inc(Result.Segments[LIndex * LCount + LSegment].DiskOffset, LIndex * AElement.DiskSize);
    end;
  Simplify(Result);
end;

class function TDiskLayoutBuilder.HasReferences(const AShape: TShape): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AShape.Segments) do
    if AShape.Segments[LIndex].Reference then
      Exit(True);
  Result := False;
end;

class function TDiskLayoutBuilder.SameShape(const ALeft: TShape; const ARight: TShape): Boolean;
var
  LIndex: Integer;
begin
  if (ALeft.NativeSize <> ARight.NativeSize) or (ALeft.DiskSize <> ARight.DiskSize) or
    (Length(ALeft.Segments) <> Length(ARight.Segments)) then
    Exit(False);
  for LIndex := 0 to High(ALeft.Segments) do
    if (ALeft.Segments[LIndex].Reference <> ARight.Segments[LIndex].Reference) or
      (ALeft.Segments[LIndex].NativeOffset <> ARight.Segments[LIndex].NativeOffset) or
      (ALeft.Segments[LIndex].Size <> ARight.Segments[LIndex].Size) then
      Exit(False);
  Result := True;
end;

class procedure TDiskLayoutBuilder.Simplify(var AShape: TShape);
begin
  // no pointer inside and the same size: memory and disk are the same bytes, padding included
  if (AShape.NativeSize = AShape.DiskSize) and not HasReferences(AShape) then
  begin
    SetLength(AShape.Segments, 1);
    AShape.Segments[0] := Default(TDiskLayoutSegment);
    AShape.Segments[0].Size := AShape.NativeSize;
  end
  else
    AShape.Segments := Merge(AShape.Segments);
end;

class function TDiskLayoutBuilder.Merge(const ASegments: TArray<TDiskLayoutSegment>): TArray<TDiskLayoutSegment>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, Length(ASegments));
  LCount := 0;
  for LIndex := 0 to High(ASegments) do
  begin
    if (LCount > 0) and not ASegments[LIndex].Reference and not Result[LCount - 1].Reference and
      (Result[LCount - 1].NativeOffset + Result[LCount - 1].Size = ASegments[LIndex].NativeOffset) and
      (Result[LCount - 1].DiskOffset + Result[LCount - 1].Size = ASegments[LIndex].DiskOffset) then
      Inc(Result[LCount - 1].Size, ASegments[LIndex].Size)
    else
    begin
      Result[LCount] := ASegments[LIndex];
      Inc(LCount);
    end;
  end;
  SetLength(Result, LCount);
end;

function TDiskLayoutBuilder.OrdinalShape(const AType: TRttiType): TShape;
var
  LSize: Integer;
  LAlign: Integer;
begin
  // a NativeInt is an integer of 32 bits for the 32 bit compiler and of 64 for the other one
  if SameText(AType.Name, SNativeIntName) or SameText(AType.Name, SNativeUIntName) then
    Exit(ReferenceShape);
  LSize := AType.TypeSize;
  LAlign := LSize;
  // a set of more than 32 elements is an array of bytes
  if not (LSize in [1, 2, 4, 8]) then
    LAlign := 1;
  Result := RawShape(LSize, LAlign, 'value');
end;

function TDiskLayoutBuilder.ShapeOf(const ATypeInfo: PTypeInfo; const AOwner: string;
  const AField: string): TShape;
var
  LType: TRttiType;
  LArray: TRttiArrayType;
  LLines: TArray<string>;
begin
  if FShapes.TryGetValue(ATypeInfo, Result) then
    Exit;
  LType := FContext.GetType(ATypeInfo);
  if LType = nil then
    raise ESerializerException.Create(SDiskLayoutNoTypeInfo);
  case LType.TypeKind of
    tkInteger, tkChar, tkWChar, tkEnumeration, tkSet, tkInt64:
      Result := OrdinalShape(LType);
    tkFloat:
      begin
        // an Extended is 10 bytes for the 32 bit compiler and 8 for the other one
        if GetTypeData(ATypeInfo).FloatType = ftExtended then
          raise ESerializerException.CreateFmt(SDiskLayoutUnsupportedType, [AField, AOwner, LType.Name]);
        Result := RawShape(LType.TypeSize, LType.TypeSize, 'value');
      end;
    tkString:
      Result := RawShape(LType.TypeSize, 1, 'text');
    tkPointer, tkProcedure, tkClass, tkClassRef:
      Result := ReferenceShape;
    tkRecord:
      Result := RecordShape(LType, LLines);
    tkArray:
      begin
        LArray := TRttiArrayType(LType);
        if LArray.ElementType = nil then
          raise ESerializerException.CreateFmt(SDiskLayoutUnsupportedType, [AField, AOwner, LType.Name]);
        Result := ArrayShape(ShapeOf(LArray.ElementType.Handle, AOwner, AField), LArray.TotalElementCount);
        if Result.NativeSize <> LType.TypeSize then
          raise ESerializerException.CreateFmt(SDiskLayoutNotUnderstood, [LType.Name]);
      end;
  else
    // strings, dynamic arrays, interfaces, methods, variants: never in a record that is saved raw
    raise ESerializerException.CreateFmt(SDiskLayoutUnsupportedType, [AField, AOwner, LType.Name]);
  end;
  FShapes.AddOrSetValue(ATypeInfo, Result);
end;

function TDiskLayoutBuilder.FieldShape(const ARecord: TRttiType; const AField: TRttiField;
  ASpan: Integer): TShape;
var
  LDescription: TDescription;
  LElement: TShape;
begin
  if AField.FieldType <> nil then
    Exit(ShapeOf(AField.FieldType.Handle, ARecord.Name, AField.Name));
  if not FDescriptions.TryGetValue(DescriptionKey(ARecord.Handle, AField.Name), LDescription) then
    Exit(OpaqueShape(AField.Offset, ASpan));
  LElement := ShapeOf(LDescription.Element, ARecord.Name, AField.Name);
  Result := ArrayShape(LElement, LDescription.Count);
  // what is left after the elements can only be the padding before the next field
  if (LDescription.Count <= 0) or (Result.NativeSize > ASpan) or (ASpan - Result.NativeSize >= SizeOf(Int64)) then
    raise ESerializerException.CreateFmt(SDiskLayoutWrongCount,
      [AField.Name, ARecord.Name, LDescription.Count, LElement.NativeSize, ASpan]);
end;

function TDiskLayoutBuilder.CollectItems(const ARecord: TRttiType): TArray<TItem>;
var
  LFields: TArray<TRttiField>;
  LField: TRttiField;
  LIndex: Integer;
  LOther: Integer;
  LNext: Integer;
  LCount: Integer;
  LItem: TItem;
begin
  LFields := ARecord.GetFields;
  // by offset, keeping the order of the declaration for the fields of a variant part
  for LIndex := 1 to High(LFields) do
  begin
    LField := LFields[LIndex];
    LOther := LIndex - 1;
    while (LOther >= 0) and (LFields[LOther].Offset > LField.Offset) do
    begin
      LFields[LOther + 1] := LFields[LOther];
      Dec(LOther);
    end;
    LFields[LOther + 1] := LField;
  end;

  SetLength(Result, Length(LFields));
  LCount := 0;
  for LIndex := 0 to High(LFields) do
  begin
    LNext := ARecord.TypeSize;
    for LOther := LIndex + 1 to High(LFields) do
      if LFields[LOther].Offset > LFields[LIndex].Offset then
      begin
        LNext := LFields[LOther].Offset;
        Break;
      end;
    LItem.Name := LFields[LIndex].Name;
    LItem.Offset := LFields[LIndex].Offset;
    LItem.Shape := FieldShape(ARecord, LFields[LIndex], LNext - LItem.Offset);

    // the fields of a variant part lie on each other: only the same value seen in more ways is supported
    if (LCount > 0) and (LItem.Offset < Result[LCount - 1].Offset + Result[LCount - 1].Shape.NativeSize) then
    begin
      if LItem.Offset <> Result[LCount - 1].Offset then
        raise ESerializerException.CreateFmt(SDiskLayoutVariant, [LItem.Name, ARecord.Name]);
      if Result[LCount - 1].Shape.Opaque and not LItem.Shape.Opaque and
        (LItem.Shape.NativeSize <= Result[LCount - 1].Shape.NativeSize) then
        Result[LCount - 1] := LItem
      else if not (LItem.Shape.Opaque and (LItem.Shape.NativeSize <= Result[LCount - 1].Shape.NativeSize)) and
        not SameShape(Result[LCount - 1].Shape, LItem.Shape) then
        raise ESerializerException.CreateFmt(SDiskLayoutVariant, [LItem.Name, ARecord.Name]);
      Continue;
    end;
    Result[LCount] := LItem;
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

class function TDiskLayoutBuilder.NativeFits(var AItems: TArray<TItem>; ACap: Integer; ATotal: Integer;
  out ARecordAlign: Integer; out AWhere: string): Boolean;
var
  LIndex: Integer;
  LEnd: Integer;
  LAlign: Integer;
  LAfterOpaque: Boolean;
begin
  LEnd := 0;
  ARecordAlign := 1;
  AWhere := '(size)';
  LAfterOpaque := False;
  for LIndex := 0 to High(AItems) do
  begin
    LAlign := Smaller(AItems[LIndex].Shape.NativeAlign, ACap);
    // a packed record whose fields happen to be aligned looks like any other record: its place tells that
    // it is packed (no padding before it, where its alignment would ask for some)
    if (AItems[LIndex].Shape.Kind = 'record') and not LAfterOpaque and (AItems[LIndex].Offset = LEnd) and
      (RoundUp(LEnd, LAlign) <> LEnd) then
    begin
      AItems[LIndex].Shape.NativeAlign := 1;
      AItems[LIndex].Shape.DiskAlign := 1;
      LAlign := 1;
    end;
    if LAlign > ARecordAlign then
      ARecordAlign := LAlign;
    // the size of a field with an unnamed type is not known: the field after it cannot be checked
    if not AItems[LIndex].Shape.Opaque and not LAfterOpaque and
      (RoundUp(LEnd, LAlign) <> AItems[LIndex].Offset) then
    begin
      AWhere := AItems[LIndex].Name;
      Exit(False);
    end;
    LEnd := AItems[LIndex].Offset + AItems[LIndex].Shape.NativeSize;
    LAfterOpaque := AItems[LIndex].Shape.Opaque;
  end;
  Result := RoundUp(LEnd, ARecordAlign) = ATotal;
end;

function TDiskLayoutBuilder.RecordShape(const ARecord: TRttiType; out AFieldLines: TArray<string>): TShape;
const
  CAPS: array[0..3] of Integer = (8, 4, 2, 1);
var
  LItems: TArray<TItem>;
  LCap: Integer;
  LCapIndex: Integer;
  LNativeAlign: Integer;
  LFound: Boolean;
  LIndex: Integer;
  LSegment: Integer;
  LCount: Integer;
  LNativeEnd: Integer;
  LDiskEnd: Integer;
  LDiskOffset: Integer;
  LDiskAlign: Integer;
  LNextAlign: Integer;
  LPadding: Integer;
  LWhere: string;
  LFirstWhere: string;
begin
  LItems := CollectItems(ARecord);

  // the alignment of the record ({$ALIGN 8}, 4, 2 or packed): the one that gives the offsets of the compiler
  LFound := False;
  LCap := 1;
  LNativeAlign := 1;
  for LCapIndex := Low(CAPS) to High(CAPS) do
    if NativeFits(LItems, CAPS[LCapIndex], ARecord.TypeSize, LNativeAlign, LWhere) then
    begin
      LCap := CAPS[LCapIndex];
      LFound := True;
      Break;
    end
    else if LCapIndex = Low(CAPS) then
      LFirstWhere := LWhere;
  if not LFound then
    raise ESerializerException.CreateFmt(SDiskLayoutNotUnderstood, [ARecord.Name + ' at ' + LFirstWhere]);

  Result := Default(TShape);
  Result.NativeSize := ARecord.TypeSize;
  Result.NativeAlign := LNativeAlign;
  Result.DiskAlign := 1;
  Result.Kind := 'record';
  SetLength(AFieldLines, Length(LItems));
  LCount := 0;
  LNativeEnd := 0;
  LDiskEnd := 0;
  for LIndex := 0 to High(LItems) do
  begin
    LDiskAlign := Smaller(LItems[LIndex].Shape.DiskAlign, LCap);
    if LDiskAlign > Result.DiskAlign then
      Result.DiskAlign := LDiskAlign;
    if LItems[LIndex].Shape.Opaque then
    begin
      // plain bytes keep the padding that they have in memory before and after them; that is right only
      // if neither depends on the width of a pointer
      LPadding := LItems[LIndex].Offset - LNativeEnd;
      if LIndex = High(LItems) then
        LNextAlign := LNativeAlign
      else if LItems[LIndex + 1].Shape.Opaque then
        LNextAlign := 1
      else
        LNextAlign := Smaller(LItems[LIndex + 1].Shape.NativeAlign, LCap);
      if (LPadding >= MAX_OPAQUE_ALIGN) or (LNextAlign > MAX_OPAQUE_ALIGN) then
        raise ESerializerException.CreateFmt(SDiskLayoutDescribeField, [LItems[LIndex].Name, ARecord.Name]);
      LDiskOffset := LDiskEnd + LPadding;
    end
    else
      LDiskOffset := RoundUp(LDiskEnd, LDiskAlign);
    // the layout on disk is by definition the one of the 32 bit program
    if (SizeOf(Pointer) = DISK_REFERENCE_SIZE) and (LDiskOffset <> LItems[LIndex].Offset) then
      raise ESerializerException.CreateFmt(SDiskLayoutNotIdentity, [ARecord.Name]);

    SetLength(Result.Segments, LCount + Length(LItems[LIndex].Shape.Segments));
    for LSegment := 0 to High(LItems[LIndex].Shape.Segments) do
    begin
      Result.Segments[LCount] := LItems[LIndex].Shape.Segments[LSegment];
      Inc(Result.Segments[LCount].NativeOffset, LItems[LIndex].Offset);
      Inc(Result.Segments[LCount].DiskOffset, LDiskOffset);
      Inc(LCount);
    end;
    AFieldLines[LIndex] := Format('%d %d %s %s',
      [LDiskOffset, LItems[LIndex].Shape.DiskSize, LItems[LIndex].Name, LItems[LIndex].Shape.Kind]);
    LNativeEnd := LItems[LIndex].Offset + LItems[LIndex].Shape.NativeSize;
    LDiskEnd := LDiskOffset + LItems[LIndex].Shape.DiskSize;
  end;
  Result.DiskSize := RoundUp(LDiskEnd, Result.DiskAlign);
  // and a record with no pointer inside is the same for the two compilers
  if ((SizeOf(Pointer) = DISK_REFERENCE_SIZE) or not HasReferences(Result)) and
    (Result.DiskSize <> Result.NativeSize) then
    raise ESerializerException.CreateFmt(SDiskLayoutNotIdentity, [ARecord.Name]);
  Simplify(Result);
end;

procedure TDiskLayoutBuilder.DescribeArray(const ARecord: PTypeInfo; const AField: string;
  const AElement: PTypeInfo; ACount: Integer);
var
  LDescription: TDescription;
begin
  if not Assigned(ARecord) then
    raise EArgumentNilException.Create('ARecord');
  if not Assigned(AElement) then
    raise EArgumentNilException.Create('AElement');
  LDescription.Element := AElement;
  LDescription.Count := ACount;
  FDescriptions.AddOrSetValue(DescriptionKey(ARecord, AField), LDescription);
  // a layout worked out before the description is no longer the right one
  FShapes.Clear;
end;

function TDiskLayoutBuilder.Build(const ATypeInfo: PTypeInfo): IDiskLayout;
var
  LType: TRttiType;
  LShape: TShape;
  LLines: TArray<string>;
  LLayout: TDiskLayout;
begin
  if not Assigned(ATypeInfo) then
    raise ESerializerException.Create(SDiskLayoutNoTypeInfo);
  LType := FContext.GetType(ATypeInfo);
  if LType = nil then
    raise ESerializerException.Create(SDiskLayoutNoTypeInfo);
  if LType.TypeKind = tkRecord then
    LShape := RecordShape(LType, LLines)
  else
  begin
    LShape := ShapeOf(ATypeInfo, LType.Name, '');
    LLines := nil;
  end;
  LLayout := TDiskLayout.Create(LType.Name, LShape.NativeSize, LShape.DiskSize, Merge(LShape.Segments), LLines);
  Result := LLayout;
  // the layout on disk is by definition the one of the 32 bit program
  if (SizeOf(Pointer) = DISK_REFERENCE_SIZE) and not LLayout.Identity then
    raise ESerializerException.CreateFmt(SDiskLayoutNotIdentity, [LType.Name]);
end;

end.
