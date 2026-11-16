{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - the contracts                            }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  See DelphiDoom.Opl.Types for the copyright notice                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Intf;

interface

type
  /// <summary>
  ///   The callbacks of the C chip (OPL_TIMERHANDLER, OPL_IRQHANDLER, OPL_UPDATEHANDLER) as one small interface
  /// </summary>
  IOplChipListener = interface
    ['{7B1E2C94-5D03-4F6A-A8E1-2C93D0B47F15}']
    /// <summary>A timer was started (interval above 0) or stopped (0)</summary>
    procedure TimerChanged(AChannel: Integer; AIntervalSeconds: Double);
    /// <summary>The interrupt line went on (1) or off (0)</summary>
    procedure IrqChanged(AParam: Integer; ALevel: Integer);
    /// <summary>The chip is about to take a value on the data port: bring the sound up to date</summary>
    procedure BeforeDataWrite(AParam: Integer);
  end;

  /// <summary>The source of the white noise of the rhythm section (rand() of the C library)</summary>
  IOplNoiseSource = interface
    ['{3A6D8E52-0C47-4B19-9F83-61E5B7A2D048}']
    /// <summary>One random bit</summary>
    function NextBit: Integer;
  end;

  /// <summary>
  ///   The tables the chips share (TL_TABLE, SIN_TABLE, ENV_CURVE, AMS_TABLE and VIB_TABLE of the C): built once,
  ///   never changed afterwards
  /// </summary>
  IOplTables = interface
    ['{91F4B0C7-2E68-4D35-BA16-8D07E3C59A42}']
    function GetTotalLevel: TArray<Integer>;
    function GetSinOffsets: TArray<Integer>;
    function GetEnvelopeCurve: TArray<Integer>;
    function GetAmsTable: TArray<Integer>;
    function GetVibTable: TArray<Integer>;
    function GetActiveChip: NativeInt;
    procedure SetActiveChip(AValue: NativeInt);
    /// <summary>TL_TABLE: 16384 entries, plus section then minus section</summary>
    property TotalLevel: TArray<Integer> read GetTotalLevel;
    /// <summary>SIN_TABLE as offsets into TotalLevel: 4 waveforms of 2048 entries</summary>
    property SinOffsets: TArray<Integer> read GetSinOffsets;
    /// <summary>ENV_CURVE: 8193 entries</summary>
    property EnvelopeCurve: TArray<Integer> read GetEnvelopeCurve;
    /// <summary>AMS_TABLE: two depths of 512 entries</summary>
    property AmsTable: TArray<Integer> read GetAmsTable;
    /// <summary>VIB_TABLE: two depths of 512 entries</summary>
    property VibTable: TArray<Integer> read GetVibTable;
    /// <summary>
    ///   cur_chip of the C: the chip whose LFO state the sample loop has cached last. It is the one mutable thing of the
    ///   tables and it only reproduces a defect of the C (see TOplChip.LegacyLfoCache)
    /// </summary>
    property ActiveChip: NativeInt read GetActiveChip write SetActiveChip;
  end;

  /// <summary>One YM3812 (OPL2) chip</summary>
  IOplChip = interface
    ['{C5E02A73-8B14-4F9D-96A0-4D73E1B8F26C}']
    /// <summary>OPLResetChip</summary>
    procedure Reset;
    /// <summary>
    ///   OPLWrite: an even port is the address port, an odd one the data port; returns the interrupt flag (status shr 7)
    /// </summary>
    function Write(APort: Integer; AValue: Integer): Integer;
    /// <summary>The two writes of a register: the address, then the data</summary>
    procedure WriteRegister(ARegister: Byte; AValue: Byte);
    /// <summary>OPLRead: the status on an even port; the data port always gives 0</summary>
    function Read(APort: Integer): Byte;
    /// <summary>OPLTimerOver: a timer expired (0 is timer A, other is timer B); returns the interrupt flag</summary>
    function TimerOver(ATimer: Integer): Integer;
    /// <summary>
    ///   YM3812UpdateOne with stride 1 and full volume: mono samples of 16 bit into the first ACount entries
    /// </summary>
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; ACount: Integer); overload;
    /// <summary>
    ///   YM3812UpdateOne: ALength is the number of 16 bit slots to cover, one sample is written every AStripe slots
    ///   starting at AOffset (2 and an offset of 0 or 1 interleave two chips as the left and the right channel)
    /// </summary>
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; AOffset, ALength, AStripe: Integer;
      AVolume: Single); overload;
    /// <summary>OPLSetTimerHandler, OPLSetIRQHandler and OPLSetUpdateHandler together (nil removes them)</summary>
    procedure SetListener(const AListener: IOplChipListener; ATimerChannelOffset, AIrqParam, AUpdateParam: Integer);
    function GetLegacyLfoCache: Boolean;
    procedure SetLegacyLfoCache(AValue: Boolean);
    /// <summary>
    ///   The C keeps the LFO depth (the bits of the register 0xBD) and the LFO increment of the chip in globals that it
    ///   copies only when the chip that produces samples changes: with one chip, a change of the depth bits after the
    ///   first block of samples is never heard. That is a defect, but the music of OpenXcom is made with it, so it is
    ///   kept (True, the default); False copies them at every block, as the hardware does
    /// </summary>
    property LegacyLfoCache: Boolean read GetLegacyLfoCache write SetLegacyLfoCache;
  end;

implementation

end.
