{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the contracts                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes;

type
  /// <summary>The Huffman expansion of the id engine (CAL_HuffExpand), with the dictionary of a file</summary>
  IKeenHuffman = interface
    ['{5A1E7C34-9B02-4D6F-8E13-C47A0B95D2F1}']
    /// <summary>
    ///   Expands ADestLength bytes from ASource, starting at ASourceOffset (the bits of a byte are taken from
    ///   the lowest). EKeenDataException when the data end before that
    /// </summary>
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
    /// <summary>
    ///   Like Expand, but data that end early are not an error: the bytes they cannot give stay zero. The C reads
    ///   what is after the data in that case (whatever the buffer had)
    /// </summary>
    function ExpandAvailable(const ASource: TBytes; ASourceOffset, ADestLength: Integer): TBytes;
  end;

  /// <summary>The RLEW expansion of the maps (CA_RLEWexpand)</summary>
  IKeenRlew = interface
    ['{C83D0F52-1A6B-4E97-B4C5-7E29A1D80F36}']
    /// <summary>
    ///   Expands ADestLength bytes (words, the odd byte is not written) from the words of ASource that start
    ///   at ASourceOffset. A word equal to ATag is followed by a count and a value
    /// </summary>
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer;
      ATag: Word): TBytes;
  end;

  /// <summary>Where the files of the game are: a folder, or the memory of a test</summary>
  IKeenDataFiles = interface
    ['{2F6B91D8-40C3-4A75-9E0D-83B5C6A1E274}']
    function Exists(const AName: string): Boolean;
    /// <summary>A new stream on the file, that the caller owns; EKeenFileNotFoundException if it is not there</summary>
    function OpenStream(const AName: string): TStream;
    /// <summary>The whole file; EKeenFileNotFoundException if it is not there</summary>
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>The offsets that start every file of chunks (EGAHEAD, AUDIOHHD): 32 bit, -1 for a chunk that is not there</summary>
  IKeenOffsetTable = interface
    ['{B7094E1A-D6F2-43C8-A951-0E8C3D72B5F6}']
    /// <summary>Entries of the table, one more than the chunks: the last is the end of the file</summary>
    function GetCount: Integer;
    function GetOffset(AIndex: Integer): Integer;
    /// <summary>True if the chunk has no data (offset -1, a sparse tile)</summary>
    function IsSparse(AIndex: Integer): Boolean;
    /// <summary>Where the data of the chunk end: the offset of the next chunk that is there</summary>
    function EndOf(AIndex: Integer): Integer;
    property Count: Integer read GetCount;
    property Offsets[AIndex: Integer]: Integer read GetOffset; default;
  end;

  /// <summary>How long a chunk is once expanded, when the file does not say</summary>
  IKeenChunkLayout = interface
    ['{18D6A0C3-92E7-4F5B-B340-6C71E5A9D082}']
    /// <summary>
    ///   The expanded length of the chunk, or -1 if the chunk starts with a 32 bit number that says it
    ///   (the pictures and the sprites; the tiles have a length that is the same for all)
    /// </summary>
    function ImplicitLength(AIndex: Integer): Integer;
    /// <summary>
    ///   True for a chunk whose data may be shorter than what the header and the length say: the shareware files
    ///   have 40 of the 72 8x8 tiles that graphkdr.h declares, and an audio file shorter than its header. The
    ///   chunk is then read up to the end of the data and what is missing is zero (a short read in the C)
    /// </summary>
    function IsLenient(AIndex: Integer): Boolean;
  end;

  /// <summary>A file made of chunks: the graphics file or the audio file</summary>
  IKeenChunkSource = interface
    ['{E4D18A63-7B95-4C20-B3F7-5A0C92E86D14}']
    function GetChunkCount: Integer;
    /// <summary>False for a chunk with no data (a sparse tile)</summary>
    function HasChunk(AIndex: Integer): Boolean;
    /// <summary>The bytes of the chunk as they are in the file; empty for a sparse chunk</summary>
    function ReadCompressed(AIndex: Integer): TBytes;
    /// <summary>The expanded bytes of the chunk; empty for a sparse chunk</summary>
    function Read(AIndex: Integer): TBytes;
    property ChunkCount: Integer read GetChunkCount;
  end;

  /// <summary>One map of the game: its name, its size and its 3 planes of tiles (background, foreground, info)</summary>
  IKeenMap = interface
    ['{91C5F7B2-3E08-4D6A-A4B1-F2D70E39C85A}']
    function GetNumber: Integer;
    function GetName: string;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetHeader: TKeenMapHeader;
    /// <summary>The planes are Width * Height words, row after row</summary>
    function GetPlane(APlane: Integer): TArray<Word>;
    /// <summary>The word of a plane at the tile (X, Y)</summary>
    function GetTile(APlane, AX, AY: Integer): Word;
    property Number: Integer read GetNumber;
    property Name: string read GetName;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    property Header: TKeenMapHeader read GetHeader;
    property Planes[APlane: Integer]: TArray<Word> read GetPlane;
  end;

  /// <summary>The table that says what every tile is (the bytes of MAPHEAD after the first 502)</summary>
  IKeenTileInfo = interface
    ['{07A3E9D4-5C61-4B28-8F10-D6B24C9E7A53}']
    /// <summary>The table as it is in the file</summary>
    function GetBytes: TBytes;
    /// <summary>How many tics a background tile stays before the next of its animation</summary>
    function Speed(ATile: Integer): Byte;
    /// <summary>How far the next tile of the animation of a background tile is (signed char); 0 = no animation</summary>
    function Animation(ATile: Integer): ShortInt;
    function NorthWall(ATile: Integer): Byte;
    function EastWall(ATile: Integer): Byte;
    function SouthWall(ATile: Integer): Byte;
    function WestWall(ATile: Integer): Byte;
    /// <summary>The same as Animation for a masked (foreground) tile</summary>
    function MaskedAnimation(ATile: Integer): ShortInt;
    function InTile(ATile: Integer): Byte;
    function MaskedSpeed(ATile: Integer): Byte;
    property Bytes: TBytes read GetBytes;
  end;

  /// <summary>The maps of KDREAMS.MAP</summary>
  IKeenMapSource = interface
    ['{D2B8460E-F917-4A3C-95E7-1C0B6A8D3F29}']
    function GetRlewTag: Word;
    function GetTileInfo: IKeenTileInfo;
    /// <summary>True if the slot has a map (an offset above 0)</summary>
    function HasMap(AIndex: Integer): Boolean;
    /// <summary>The numbers of the maps that are there, in order</summary>
    function MapNumbers: TArray<Integer>;
    /// <summary>Reads the header and the planes of a map (CA_CacheMap)</summary>
    function LoadMap(AIndex: Integer): IKeenMap;
    property RlewTag: Word read GetRlewTag;
    property TileInfo: IKeenTileInfo read GetTileInfo;
  end;

  /// <summary>The graphics of the game, by what they are: tables, pictures, tiles</summary>
  IKeenGraphics = interface
    ['{6E0B35C9-A281-47D4-B8F6-3D95C1A07E82}']
    function GetChunks: IKeenChunkSource;
    function GetPictureTable: TArray<TKeenPictureEntry>;
    function GetMaskedPictureTable: TArray<TKeenPictureEntry>;
    function GetSpriteTable: TArray<TKeenSpriteEntry>;
    /// <summary>Planar bytes of a picture: 4 planes of Width * Height bytes</summary>
    function PicturePlanar(AIndex: Integer): TBytes;
    /// <summary>Planar bytes of a masked picture: the mask and 4 planes of Width * Height bytes</summary>
    function MaskedPicturePlanar(AIndex: Integer): TBytes;
    /// <summary>The planar bytes of a sprite, without shifts: the mask and 4 planes of Width * Height bytes</summary>
    function SpritePlanar(AIndex: Integer): TBytes;
    /// <summary>32 bytes of an 8x8 tile; empty if the tile has no data</summary>
    function Tile8(AIndex: Integer): TBytes;
    /// <summary>40 bytes of a masked 8x8 tile</summary>
    function Tile8Masked(AIndex: Integer): TBytes;
    /// <summary>128 bytes of a 16x16 tile of the background; empty if the tile has no data</summary>
    function Tile16(AIndex: Integer): TBytes;
    /// <summary>160 bytes of a masked 16x16 tile of the foreground; empty if the tile has no data</summary>
    function Tile16Masked(AIndex: Integer): TBytes;
    property Chunks: IKeenChunkSource read GetChunks;
    property PictureTable: TArray<TKeenPictureEntry> read GetPictureTable;
    property MaskedPictureTable: TArray<TKeenPictureEntry> read GetMaskedPictureTable;
    property SpriteTable: TArray<TKeenSpriteEntry> read GetSpriteTable;
  end;

  /// <summary>The three files of the game, opened</summary>
  IKeenGameData = interface
    ['{4C9A2E71-B053-4F8D-A6E4-82D17B0C5F93}']
    function GetGraphics: IKeenGraphics;
    function GetMaps: IKeenMapSource;
    function GetAudio: IKeenChunkSource;
    property Graphics: IKeenGraphics read GetGraphics;
    property Maps: IKeenMapSource read GetMaps;
    property Audio: IKeenChunkSource read GetAudio;
  end;

  /// <summary>Turns an image of EGA colors into the bytes of an image file</summary>
  IKeenImageEncoder = interface
    ['{A04C7E93-5D18-4B62-9F3A-C81E0D456B27}']
    function Encode(const AImage: TKeenChunkyImage): TBytes;
  end;

  /// <summary>Draws a map of the game and saves it as an image file</summary>
  IKeenMapExporter = interface
    ['{7D29B1F6-E0A4-4C35-8B71-3F5A92C0D148}']
    /// <summary>Saves the map of the slot AMapNumber; the file is overwritten</summary>
    procedure SaveMapPicture(AMapNumber: Integer; const APath: string);
  end;

  /// <summary>Draws a whole map at once: the background tiles and, over them, the masked tiles of the foreground</summary>
  IKeenMapRenderer = interface
    ['{F3185D6A-0B47-4E92-9C0A-A7E5D21C8B64}']
    function Render(const AMap: IKeenMap; const AGraphics: IKeenGraphics): TKeenChunkyImage;
  end;

  /// <summary>
  ///   Shows a part of a map as the game does (the tile refresh manager on the video memory of the EGA, with the
  ///   sprites) and saves the 320x200 screen as an image file
  /// </summary>
  IKeenViewExporter = interface
    ['{B6C2E8F4-17A3-4D59-8E0B-92F5D3A61C07}']
    /// <summary>The screen of the map of the slot AMapNumber with the origin at the global position (AGlobalX, AGlobalY)</summary>
    procedure SaveViewPicture(AMapNumber, AGlobalX, AGlobalY: Integer; const ASprites: array of TKeenViewSprite;
      const APath: string);
  end;

  /// <summary>The 4 planes of the video memory of the EGA, 64 KB each; an offset wraps at 64 KB</summary>
  IKeenEgaMemory = interface
    ['{2B7E40D9-6C15-4A83-9F0E-D1A538C6B472}']
    function ReadByte(APlane, AOffset: Integer): Byte;
    procedure WriteByte(APlane, AOffset: Integer; AValue: Byte);
    /// <summary>The copy of the latches: the byte of the four planes at ASourceOffset goes to ADestOffset (write mode 1)</summary>
    procedure CopyByte(ASourceOffset, ADestOffset: Integer);
    /// <summary>Every pixel of the memory takes the color (VW_ClearVideo)</summary>
    procedure Fill(AColor: Byte);
    /// <summary>A copy of the 64 KB of a plane</summary>
    function PlaneBytes(APlane: Integer): TBytes;
  end;

  /// <summary>
  ///   The sprites of the game with their shifted copies (CAL_CacheSprite): the sprite of the chunk
  ///   ASpriteChunk (STARTSPRITES and more) is made once and kept
  /// </summary>
  IKeenSpriteCache = interface
    ['{C9150E7A-3D28-4B64-A1F7-0E8B92D6C345}']
    function GetSprite(ASpriteChunk: Integer): TKeenSprite;
    /// <summary>The line of the sprite table of the chunk (width, origin, shifts...)</summary>
    function GetEntry(ASpriteChunk: Integer): TKeenSpriteEntry;
  end;

  /// <summary>
  ///   The video manager of the EGA (id_vw.c and id_vw_ae.asm): the drawing routines of the game on the planar
  ///   memory. X of the block routines is in bytes (8 pixels), Y in pixels; the pixel routines have X and Y
  ///   in pixels. A block is drawn at BufferOfs only where the C says so (VW_MaskBlock and VW_MemToScreen are
  ///   given the destination offset)
  /// </summary>
  IKeenVideo = interface
    ['{5E3A8B21-D794-4F06-B2C8-71A0F4E5963D}']
    function GetMemory: IKeenEgaMemory;
    function GetLineWidth: Integer;
    function GetBufferOfs: Integer;
    procedure SetBufferOfs(AValue: Integer);
    function GetDisplayOfs: Integer;
    procedure SetDisplayOfs(AValue: Integer);
    function GetPanX: Integer;
    procedure SetPanX(AValue: Integer);
    function GetPanY: Integer;
    procedure SetPanY(AValue: Integer);
    function GetPanSX: Integer;
    procedure SetPanSX(AValue: Integer);
    function GetPanSY: Integer;
    procedure SetPanSY(AValue: Integer);
    function GetPanAdjust: Integer;
    procedure SetPanAdjust(AValue: Integer);
    function GetCrtcStart: Integer;
    function GetPelPan: Integer;
    /// <summary>VW_SetLineWidth: bytes of a row of the virtual screen, and the table of the start of each row</summary>
    procedure SetLineWidth(AWidth: Integer);
    /// <summary>The offset of the row ARow from the start of a page (ylookup)</summary>
    function YLookup(ARow: Integer): Integer;
    /// <summary>VW_SetScreen: where the card starts to show the memory and the pel panning (0..7)</summary>
    procedure SetScreen(ACrtc, APelPan: Integer);
    procedure ClearVideo(AColor: Integer);
    procedure Plot(AX, AY, AColor: Integer);
    procedure Hlin(AXLow, AXHigh, AY, AColor: Integer);
    procedure Vlin(AYLow, AYHigh, AX, AColor: Integer);
    procedure Bar(AX, AY, AWidth, AHeight, AColor: Integer);
    /// <summary>VW_MaskBlock: the mask at AOffset of AData and then 4 planes, each APlaneSize bytes</summary>
    procedure MaskBlock(const AData: TBytes; AOffset, ADest, AWide, AHeight, APlaneSize: Integer);
    /// <summary>VW_MemToScreen: 4 planes of AWide * AHeight bytes</summary>
    procedure MemToScreen(const ASource: TBytes; ADest, AWide, AHeight: Integer);
    /// <summary>VW_ScreenToMem: the planes 0..3 of the block in a new array</summary>
    function ScreenToMem(ASource, AWide, AHeight: Integer): TBytes;
    /// <summary>VW_ScreenToScreen: a copy with the latches (the memory is the same: the blocks can overlap)</summary>
    procedure ScreenToScreen(ASource, ADest, AWide, AHeight: Integer);
    procedure DrawTile8(AX, AY, ATile: Integer);
    procedure DrawTile8Masked(AX, AY, ATile: Integer);
    procedure DrawTile16(AX, AY, ATile: Integer);
    procedure DrawTile16Masked(AX, AY, ATile: Integer);
    /// <summary>VW_DrawPic: AChunk is the number of the chunk (STARTPICS and more)</summary>
    procedure DrawPic(AX, AY, AChunk: Integer);
    /// <summary>VW_DrawMPic: AChunk is STARTPICM and more</summary>
    procedure DrawMaskedPic(AX, AY, AChunk: Integer);
    /// <summary>VW_DrawSprite: X and Y in pixels, the shift is the one of X; AChunk is STARTSPRITES and more</summary>
    procedure DrawSprite(AX, AY, AChunk: Integer);
    property Memory: IKeenEgaMemory read GetMemory;
    property LineWidth: Integer read GetLineWidth;
    property BufferOfs: Integer read GetBufferOfs write SetBufferOfs;
    property DisplayOfs: Integer read GetDisplayOfs write SetDisplayOfs;
    property PanX: Integer read GetPanX write SetPanX;
    property PanY: Integer read GetPanY write SetPanY;
    property PanSX: Integer read GetPanSX write SetPanSX;
    property PanSY: Integer read GetPanSY write SetPanSY;
    property PanAdjust: Integer read GetPanAdjust write SetPanAdjust;
    /// <summary>The offset where the card starts to show the screen (the last VW_SetScreen)</summary>
    property CrtcStart: Integer read GetCrtcStart;
    property PelPan: Integer read GetPelPan;
  end;

  /// <summary>The clock of the game (TimeCount, 70 tics a second)</summary>
  IKeenClock = interface
    ['{8A46D1F3-0B97-4E25-83C1-B5F02E9D7A61}']
    function GetTimeCount: Integer;
    procedure SetTimeCount(AValue: Integer);
    /// <summary>
    ///   What a loop that waits for TimeCount does between two looks (the C spins; the real clock sleeps, a
    ///   clock of a test moves the time on)
    /// </summary>
    procedure Idle;
    property TimeCount: Integer read GetTimeCount write SetTimeCount;
  end;

  /// <summary>The mouse as the input manager sees it (the driver of the DOS mouse: the movement since the last look and the buttons)</summary>
  IKeenMouse = interface
    ['{6A2D9F04-C1B7-4E83-95A6-0D3E7B8F21C5}']
    function IsPresent: Boolean;
    /// <summary>INL_GetMouseDelta: how far the mouse moved since the last call, in mickeys</summary>
    procedure GetDelta(out ADeltaX, ADeltaY: Integer);
    /// <summary>INL_GetMouseButtons: bit 0 the left button, bit 1 the right one, bit 2 the middle one</summary>
    function GetButtons: Word;
  end;

  /// <summary>The joysticks of the game port: the position of an axis and the buttons</summary>
  IKeenJoysticks = interface
    ['{D84F3B16-7E02-4A59-8C61-B9A05E2C7D43}']
    function IsPresent(AJoy: Integer): Boolean;
    /// <summary>IN_GetJoyAbs: the absolute position (the count of the timing loop of the game port)</summary>
    procedure GetAbs(AJoy: Integer; out AX, AY: Word);
    /// <summary>INL_GetJoyButtons: bit 0 the first button, bit 1 the second (1 = pressed)</summary>
    function GetButtons(AJoy: Integer): Word;
  end;

  /// <summary>What the loops that wait for the user do between two looks: read the devices (the keyboard interrupt did it in the DOS)</summary>
  IKeenInputPump = interface
    ['{0B73E5A8-92D1-4F46-A3C0-6E8D14B7F952}']
    procedure Pump;
  end;

  /// <summary>
  ///   The input manager (id_in.c): the keyboard as the table of the keys that are down, the last scan code
  ///   and ASCII code, the controls of the players (keyboard, mouse, joystick) and the demo buffer
  /// </summary>
  IKeenInput = interface
    ['{E9A1C470-5D38-4B6F-8021-C7F34A9E6B15}']
    function GetLastScan: Byte;
    procedure SetLastScan(AValue: Byte);
    function GetLastAscii: Byte;
    procedure SetLastAscii(AValue: Byte);
    function GetPaused: Boolean;
    procedure SetPaused(AValue: Boolean);
    function GetDemoMode: TKeenDemoMode;
    function GetMousePresent: Boolean;
    function GetKeyboardDef(AIndex: Integer): TKeenKeyboardDef;
    procedure SetKeyboardDef(AIndex: Integer; const AValue: TKeenKeyboardDef);
    function GetJoystickDef(AJoy: Integer): TKeenJoystickDef;
    function GetControl(APlayer: Integer): TKeenControlType;
    function GetJoystickPresent(AJoy: Integer): Boolean;
    /// <summary>
    ///   INL_KeyService: what the keyboard interrupt does with the byte of the port $60: the prefix $E0, the pause
    ///   key, a make code (key down) or a break code (key up), and the ASCII code of the key
    /// </summary>
    procedure KeyService(AByte: Byte);
    /// <summary>IN_Startup: looks for the mouse and the joysticks (the parameters -nomouse and -nojoys turn them off)</summary>
    procedure Startup(AUseMouse, AUseJoysticks: Boolean);
    procedure Shutdown;
    /// <summary>IN_Default: the control of the player 0; the keyboard if it was not saved or the device is not there</summary>
    procedure SetDefault(AGotIt: Boolean; AControl: TKeenControlType);
    /// <summary>IN_SetKeyHook: what is called after each make or break code (not after the prefix $E0)</summary>
    procedure SetKeyHook(const AHook: TProc);
    function IsKeyDown(AScan: Integer): Boolean;
    /// <summary>IN_ClearKey: the key is up and, if it was the last scan code, there is none</summary>
    procedure ClearKey(AScan: Integer);
    procedure ClearKeysDown;
    procedure SetControlType(APlayer: Integer; AType: TKeenControlType);
    /// <summary>IN_SetupJoy: the range of the axes of a joystick; the dead zone is the middle fifth</summary>
    procedure SetupJoystick(AJoy: Integer; AMinX, AMaxX, AMinY, AMaxY: Word);
    function ReadControl(APlayer: Integer): TKeenControlInfo;
    function ReadCursor: TKeenControlInfo;
    function IsUserInput: Boolean;
    /// <summary>IN_UserInput: waits for ADelay tics or an input; true if there was one</summary>
    function UserInput(ADelay: Integer; AClear: Boolean): Boolean;
    /// <summary>IN_AckBack: waits for a key or a button</summary>
    procedure AckBack;
    /// <summary>IN_Ack: waits until nothing is pressed and then for a key or a button</summary>
    procedure Ack;
    function WaitForKey: Byte;
    function WaitForAscii: Byte;
    /// <summary>IN_GetJoyButtonsDB: the buttons, read again after a tic until the two readings are the same</summary>
    function GetJoystickButtonsDebounced(AJoy: Integer): Word;
    /// <summary>IN_StartDemoRecord: false if the size is 0</summary>
    function StartDemoRecord(ASize: Integer): Boolean;
    procedure StartDemoPlayback(const ABytes: TBytes; ASize: Integer);
    procedure StopDemo;
    /// <summary>The bytes that the recording made</summary>
    function DemoBytes: TBytes;
    property LastScan: Byte read GetLastScan write SetLastScan;
    property LastAscii: Byte read GetLastAscii write SetLastAscii;
    property Paused: Boolean read GetPaused write SetPaused;
    property DemoMode: TKeenDemoMode read GetDemoMode;
    property MousePresent: Boolean read GetMousePresent;
    property KeyboardDefs[AIndex: Integer]: TKeenKeyboardDef read GetKeyboardDef write SetKeyboardDef;
    property JoystickDefs[AJoy: Integer]: TKeenJoystickDef read GetJoystickDef;
    property Controls[APlayer: Integer]: TKeenControlType read GetControl;
    property JoystickPresent[AJoy: Integer]: Boolean read GetJoystickPresent;
  end;

  /// <summary>
  ///   The map that the game plays: the 3 planes of words (background, foreground, info) that the actors and
  ///   the animation of the tiles change. It starts as a copy of a map of the file
  /// </summary>
  IKeenWorkingMap = interface
    ['{F1D40B87-95E2-4C3A-A6D8-3E7C0A52B914}']
    function GetNumber: Integer;
    function GetName: string;
    function GetWidth: Integer;
    function GetHeight: Integer;
    /// <summary>The words of a plane, row after row; the array is the storage (what a caller writes, the map has)</summary>
    function GetPlane(APlane: Integer): TArray<Word>;
    property Number: Integer read GetNumber;
    property Name: string read GetName;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    property Planes[APlane: Integer]: TArray<Word> read GetPlane;
  end;

  /// <summary>
  ///   The tile refresh manager (id_rf.c and id_rf_a.asm): the scrolling of the map on three screens that
  ///   float in the video memory, the tiles that change and the sprites. The map is drawn tile by tile on
  ///   the master screen; each refresh copies to the page being drawn only the tiles that changed (the
  ///   update array) and then draws the sprites over them in priority order
  /// </summary>
  IKeenRefresh = interface
    ['{3C8F9A60-1E75-4D2B-B409-A6D5E3170C82}']
    function GetTics: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    function GetOriginXScreen: Integer;
    function GetOriginYScreen: Integer;
    function GetMasterOfs: Integer;
    function GetOriginXMax: Integer;
    function GetOriginYMax: Integer;
    function GetOriginXMin: Integer;
    function GetOriginYMin: Integer;
    function GetMapWidth: Integer;
    function GetMapHeight: Integer;
    function GetLastTimeCount: Integer;
    /// <summary>RF_NewMap: the map that is played (RF_MarkTileGraphics and RF_NewPosition come next)</summary>
    procedure NewMap(const AMap: IKeenWorkingMap);
    /// <summary>RF_MarkTileGraphics: the animation chains of the tiles of the map (what the C leaves in the info plane)</summary>
    procedure MarkTileGraphics;
    procedure NewPosition(AX, AY: Integer);
    procedure Scroll(AX, AY: Integer);
    /// <summary>RF_PlaceSprite: the sprite is at the global coordinates (1/16 of a pixel)</summary>
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk: Integer;
      ADraw: TKeenDrawType; APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
    procedure Refresh;
    procedure ForceRefresh;
    /// <summary>The function that Refresh calls before it shows the page (RF_SetRefreshHook); nil for none</summary>
    procedure SetRefreshHook(const AHook: TProc);
    /// <summary>The update array of the page being drawn: for the tests (what changes, what a sprite covers)</summary>
    function UpdateSnapshot(APage: Integer): TBytes;
    /// <summary>The page that Refresh draws next (otherpage) and the one that is shown (screenpage)</summary>
    function GetOtherPage: Integer;
    function GetScreenPage: Integer;
    property Tics: Integer read GetTics;
    property OriginXGlobal: Integer read GetOriginXGlobal;
    property OriginYGlobal: Integer read GetOriginYGlobal;
    property OriginXTile: Integer read GetOriginXTile;
    property OriginYTile: Integer read GetOriginYTile;
    property OriginXScreen: Integer read GetOriginXScreen;
    property OriginYScreen: Integer read GetOriginYScreen;
    property MasterOfs: Integer read GetMasterOfs;
    property OriginXMin: Integer read GetOriginXMin;
    property OriginXMax: Integer read GetOriginXMax;
    property OriginYMin: Integer read GetOriginYMin;
    property OriginYMax: Integer read GetOriginYMax;
    property MapWidth: Integer read GetMapWidth;
    property MapHeight: Integer read GetMapHeight;
    property OtherPage: Integer read GetOtherPage;
    property ScreenPage: Integer read GetScreenPage;
    /// <summary>lasttimecount: the value of TimeCount at the last refresh (for the gravity of a frame)</summary>
    property LastTimeCount: Integer read GetLastTimeCount;
  end;

  /// <summary>US_RndT: the random numbers of the game, a table of 256 bytes that is read one after the other</summary>
  IKeenRandom = interface
    ['{8D31F7A2-04C9-4B65-A2E8-5C0A9B17D3E6}']
    /// <summary>US_InitRndT: where the table starts: the low byte of the time if ARandomize, otherwise 0</summary>
    procedure Initialize(ARandomize: Boolean; ATime: Integer);
    /// <summary>The next byte of the table (the index goes up before it is read)</summary>
    function RndT: Byte;
  end;

  /// <summary>
  ///   The states of the actors (statetype[]). The table is a copy that can change: ClipToSprite takes
  ///   the flag "push to floor" away from a state for the length of a call
  /// </summary>
  IKeenStateTable = interface
    ['{4E9B05C3-D718-4A26-8F31-A7C6E2B09D54}']
    function GetCount: Integer;
    function GetDef(AIndex: Integer): TKeenStateDef;
    procedure SetPushToFloor(AIndex: Integer; AValue: Boolean);
    property Count: Integer read GetCount;
    property Defs[AIndex: Integer]: TKeenStateDef read GetDef; default;
  end;

  /// <summary>
  ///   The functions that the states call. The C has a pointer in each state; the table has the number of the
  ///   function (DelphiDoom.Keen.ActionIds) and this contract runs it. A function with no code is an
  ///   EKeenException when it is called: the game does not go on with a state that does nothing by mistake
  /// </summary>
  IKeenActions = interface
    ['{A17C60E5-3B94-4D82-96F0-C25D8E1B7A39}']
    /// <summary>think(ob)</summary>
    procedure Think(AAction: Word; AObject: PKeenObject);
    /// <summary>contact(ob, hit)</summary>
    procedure Contact(AAction: Word; AObject, AOther: PKeenObject);
    /// <summary>react(ob)</summary>
    procedure React(AAction: Word; AObject: PKeenObject);
  end;

  /// <summary>The list of the actors (objarray): the player and the score box first, the others as they are made</summary>
  IKeenObjectList = interface
    ['{6B0DA9F1-2E57-4C38-B4A6-91F3D87C5E02}']
    function GetCount: Integer;
    function GetNew: PKeenObject;
    function GetPlayer: PKeenObject;
    function GetScoreObj: PKeenObject;
    function GetFirst: PKeenObject;
    function GetObject(ASlot: Integer): PKeenObject;
    /// <summary>InitObjArray: every actor is free; the player and the score box get the first two places</summary>
    procedure Init;
    /// <summary>
    ///   GetNewObj: a free place at the end of the list, cleared and active. If the list is full the dummy
    ///   actor, that nothing uses (AUseDummy), or an EKeenException
    /// </summary>
    function GetNewObj(AUseDummy: Boolean): PKeenObject;
    /// <summary>RemoveObj: the actor leaves the list and the refresh manager; its link to the next is not touched</summary>
    procedure RemoveObj(AGone: PKeenObject);
    /// <summary>The actor after AObject, nil at the end of the list</summary>
    function NextOf(AObject: PKeenObject): PKeenObject;
    property Count: Integer read GetCount;
    /// <summary>"new" of the C: the last actor that GetNewObj gave</summary>
    property New: PKeenObject read GetNew;
    property Player: PKeenObject read GetPlayer;
    property ScoreObj: PKeenObject read GetScoreObj;
    /// <summary>The player: the list starts with it</summary>
    property First: PKeenObject read GetFirst;
    property Objects[ASlot: Integer]: PKeenObject read GetObject; default;
  end;

  /// <summary>What happens in the game that is not the motion of the actors: the things that the C calls from the middle of a frame</summary>
  IKeenGameEvents = interface
    ['{C28E4D70-9A15-4F63-B0D7-3E58A1F96B24}']
    /// <summary>KillKeen</summary>
    procedure KillKeen;
    /// <summary>SD_PlaySound</summary>
    procedure PlaySound(ASound: Integer);
    /// <summary>CheckKeys at the end of a frame (status window, pause, control panel, debug keys)</summary>
    procedure CheckKeys;
    /// <summary>loadedgame: a saved game was loaded from the control panel, so the loop of the frames ends</summary>
    function IsGameLoaded: Boolean;
    /// <summary>FixScoreBox: the start of the loop of the frames (the bomb and the flower are drawn in the score box)</summary>
    procedure BeginPlay;
    /// <summary>godmode = 0: the cheat is off when Keen falls off the world</summary>
    procedure ClearGodMode;
    /// <summary>godmode: Keen cannot be killed</summary>
    function IsGodMode: Boolean;
    /// <summary>jumpcheat: the jump never runs out of time</summary>
    function IsJumpCheat: Boolean;
    /// <summary>The window of CheckEnterLevel (less than 12 bombs for King Boobus Tuber), then IN_Ack and RF_ForceRefresh</summary>
    procedure ShowNeedBombs;
  end;

  /// <summary>
  ///   The functions that put an actor on the map (Spawn* of kd_keen.c, kd_act1.c and kd_act2.c), one for each
  ///   thing of the info plane. Each takes the next actor of the list ("new") and fills it
  /// </summary>
  IKeenActorSpawner = interface
    ['{F4A6B13D-70C8-4E29-A5B1-08D92C7E3F65}']
    procedure SpawnKeen(ATileX, ATileY, ADirection: Integer);
    procedure SpawnWorldKeen(ATileX, ATileY: Integer);
    procedure SpawnBonus(ATileX, ATileY, AType: Integer);
    procedure SpawnDoor(ATileX, ATileY: Integer);
    procedure SpawnBrocco(ATileX, ATileY: Integer);
    procedure SpawnTomat(ATileX, ATileY: Integer);
    procedure SpawnCarrot(ATileX, ATileY: Integer);
    procedure SpawnAspar(ATileX, ATileY: Integer);
    procedure SpawnGrape(ATileX, ATileY: Integer);
    procedure SpawnTater(ATileX, ATileY: Integer);
    procedure SpawnCart(ATileX, ATileY: Integer);
    procedure SpawnFrenchy(ATileX, ATileY: Integer);
    procedure SpawnMelon(ATileX, ATileY, ADirection: Integer);
    procedure SpawnSquasher(ATileX, ATileY: Integer);
    procedure SpawnApel(ATileX, ATileY: Integer);
    procedure SpawnPeaPod(ATileX, ATileY: Integer);
    procedure SpawnPeaBrain(ATileX, ATileY: Integer);
    procedure SpawnBoobus(ATileX, ATileY: Integer);
  end;

  /// <summary>What the actors read and change of the play of the level (c, button0held, playstate, gamestate, GivePoints of kd_play.c)</summary>
  IKeenPlayState = interface
    ['{2B7D54E1-86A3-4C09-9E5F-D13A70C8B462}']
    function GetControl: TKeenControlInfo;
    procedure SetControl(const AValue: TKeenControlInfo);
    function GetButton0Held: Boolean;
    procedure SetButton0Held(AValue: Boolean);
    function GetButton1Held: Boolean;
    procedure SetButton1Held(AValue: Boolean);
    function GetPlayState: TKeenExit;
    procedure SetPlayState(AValue: TKeenExit);
    function GetGameState: PKeenGameState;
    function GetMapOn: Integer;
    procedure SetMapOn(AValue: Integer);
    /// <summary>GivePoints: an extra life at 20000, 40000, 80000...</summary>
    procedure GivePoints(APoints: Integer);
    property Control: TKeenControlInfo read GetControl write SetControl;
    property Button0Held: Boolean read GetButton0Held write SetButton0Held;
    property Button1Held: Boolean read GetButton1Held write SetButton1Held;
    property PlayState: TKeenExit read GetPlayState write SetPlayState;
    property GameState: PKeenGameState read GetGameState;
    /// <summary>mapon of id_ca.c: the map that is loaded (gamestate.mapon is the one to go to next)</summary>
    property MapOn: Integer read GetMapOn write SetMapOn;
  end;

  /// <summary>What the actors need of the view: the tics of the frame, the time, the origin and the sprites (RF_PlaceSprite, RF_RemoveSprite)</summary>
  IKeenActionView = interface
    ['{93C0A1D5-4E78-4B26-8D3F-6A15E2B9C047}']
    function GetTics: Integer;
    function GetLastTimeCount: Integer;
    function GetTimeCount: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    function GetOriginXTileMax: Integer;
    function GetOriginYTileMax: Integer;
    /// <summary>RF_PlaceSprite with spritedraw</summary>
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk, APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
    property Tics: Integer read GetTics;
    property LastTimeCount: Integer read GetLastTimeCount;
    property TimeCount: Integer read GetTimeCount;
    property OriginXGlobal: Integer read GetOriginXGlobal;
    property OriginYGlobal: Integer read GetOriginYGlobal;
    property OriginXTile: Integer read GetOriginXTile;
    property OriginYTile: Integer read GetOriginYTile;
    property OriginXTileMax: Integer read GetOriginXTileMax;
    property OriginYTileMax: Integer read GetOriginYTileMax;
  end;

  /// <summary>The motion functions of kd_play.c that the actors call</summary>
  IKeenActorPhysics = interface
    ['{5E18B0C7-A2D4-4F93-B761-0C8D3A94F5E2}']
    procedure ClipToWalls(AObject: PKeenObject);
    procedure ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
    procedure ClipToSpriteSide(APush, ASolid: PKeenObject);
    procedure NewState(AObject: PKeenObject; AState: Integer);
  end;

  /// <summary>What every group of actions shares: the parts of the game and the helpers of kd_act1.c (DoGravity, AccelerateX, ChangeState...)</summary>
  IKeenActionContext = interface
    ['{C41F7A92-0D63-4B8E-A5C9-27E1B80D4F36}']
    function GetObjects: IKeenObjectList;
    function GetStates: IKeenStateTable;
    function GetRandom: IKeenRandom;
    function GetEvents: IKeenGameEvents;
    function GetView: IKeenActionView;
    function GetPhysics: IKeenActorPhysics;
    function GetPlay: IKeenPlayState;
    function GetMap: IKeenWorkingMap;
    /// <summary>The map of the level that is played</summary>
    procedure SetMap(const AMap: IKeenWorkingMap);
    /// <summary>A tile of a plane (mapsegs[plane]); 0 outside the map, where the C reads other memory</summary>
    function Tile(APlane, ATileX, ATileY: Integer): Integer;
    /// <summary>tinf[NORTHWALL+tile] and the like; 0 for a tile that the table does not have</summary>
    function NorthWall(ATile: Integer): Integer;
    function EastWall(ATile: Integer): Integer;
    function SouthWall(ATile: Integer): Integer;
    function WestWall(ATile: Integer): Integer;
    function InTile(ATile: Integer): Integer;
    procedure ChangeState(AObject: PKeenObject; AState: Integer);
    procedure DoGravity(AObject: PKeenObject);
    procedure AccelerateX(AObject: PKeenObject; ADirection, AMax: Integer);
    procedure FrictionX(AObject: PKeenObject);
    procedure ProjectileThink(AObject: PKeenObject);
    /// <summary>The RF_PlaceSprite of PLACESPRITE: the shape of the actor at its place</summary>
    procedure PlaceSprite(AObject: PKeenObject; APriority: Integer);
    /// <summary>The bounce of PowerReact and ProjectileReact: the speeds after the hit on the floor; gives the speed that is left</summary>
    function BounceOffFloor(AObject: PKeenObject): Cardinal;
    property Objects: IKeenObjectList read GetObjects;
    property States: IKeenStateTable read GetStates;
    property Random: IKeenRandom read GetRandom;
    property Events: IKeenGameEvents read GetEvents;
    property View: IKeenActionView read GetView;
    property Physics: IKeenActorPhysics read GetPhysics;
    property Play: IKeenPlayState read GetPlay;
    property Map: IKeenWorkingMap read GetMap;
  end;

  /// <summary>ChangeToFlower: an enemy that a flower power hits becomes a flower for a while</summary>
  IKeenFlowerChanger = interface
    ['{E0B8D3A6-2F91-4C47-83A5-71D9C46B0E18}']
    procedure ChangeToFlower(AObject: PKeenObject);
  end;

  /// <summary>The functions of kd_keen.c that the rest of the game calls: the score box and the death of Keen</summary>
  IKeenPlayerFunctions = interface
    ['{19C5F7E2-B4A0-4D36-9E81-5A3D08C2F7B4}']
    /// <summary>SpawnScore</summary>
    procedure SpawnScore;
    /// <summary>FixScoreBox</summary>
    procedure FixScoreBox;
    /// <summary>KillKeen</summary>
    procedure KillKeen;
  end;

  /// <summary>A group of the functions of the states: it says if the function is its own and runs it</summary>
  IKeenActionGroup = interface
    ['{7A93E2B4-1C05-4D78-9F6A-B3D81E04C259}']
    function TryThink(AAction: Word; AObject: PKeenObject): Boolean;
    function TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
    function TryReact(AAction: Word; AObject: PKeenObject): Boolean;
  end;

implementation

end.
