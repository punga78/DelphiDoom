{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the pure server         }
{                                                                              }
{  Written from the description of the pure server calls of idFileSystem       }
{  (framework\FileSystem.h); licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.PureServer.Intf;

interface

uses
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   The pure server lock: the list of paks a client may read from (the ones that a server and its clients
  ///   share, in the same order), the game code pak (the checksum of the pak that holds the game code, which the
  ///   original reads from the loaded DLL: here the caller gives it) and the restart checksums. Not ported: the paks
  ///   that were just downloaded (<c>isNew</c>), and the restart itself (the use of the restart checksums by <c>Startup</c>).
  /// </summary>
  IGamePureServer = interface
    ['{E4B07C25-6D13-48A9-95F1-0C3A7D82E6B4}']
    /// <summary>The list of the paks the lock holds, in order (empty when there is no lock)</summary>
    function ServerPacks: TArray<IGamePack>;
    /// <summary>
    ///   UpdatePureServerChecksums: locks the list to what is in the search list now: the paks whose status is
    ///   PURE_ALWAYS and, if they were referenced (a file was read from them), PURE_NEUTRAL ones. More than
    ///   128 paks raise EGameFsException
    /// </summary>
    procedure UpdatePureServerChecksums;
    /// <summary>ClearPureChecksums: no lock</summary>
    procedure ClearPureChecksums;
    /// <summary>GetPureServerChecksums: the checksums of the paks of the lock, in order</summary>
    function GetPureServerChecksums: TArray<Cardinal>;
    /// <summary>
    ///   SetPureServerChecksums: sets the lock to the paks a server asks for. A list that is empty or starts with
    ///   zero clears it. The paks found in order are kept; the missing ones are returned in <c>AMissing</c>
    /// </summary>
    function SetPureServerChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
      ALoadedFileFromDir: Boolean = False): TGamePureReply;
    /// <summary>GetPackForChecksum: the pak of the search list (and, if asked, of the addons) with a checksum, nil if none</summary>
    function GetPackForChecksum(AChecksum: Cardinal; ASearchAddons: Boolean = False): IGamePack;
    /// <summary>gamePakChecksum: the checksum of the pak with the game code that is loaded now (0: none)</summary>
    function GetGamePakChecksum: Cardinal;
    procedure SetGamePakChecksum(AChecksum: Cardinal);
    /// <summary>gamePakForOS[]: the pak with the game code for each operating system, by number</summary>
    procedure SetGamePakForOS(const AChecksums: TArray<Cardinal>);
    /// <summary>
    ///   SetPureServerChecksums with the game code: as the function without it, then the DLL is checked. The
    ///   reply is PURE_NODLL (<c>NoDll</c>) when the server has no code for us (<c>AGamePakChecksum</c> is 0) or its
    ///   pak does not hold <c>ADllName</c>; <c>Missing</c> (with <c>AMissingGamePak</c> set when the pak itself is
    ///   not installed) when assets or the code pak are missing; <c>Restart</c> when the code pak found is not the
    ///   loaded one and holds the DLL (the loaded one becomes that pak, as in the original, so that a pure restart
    ///   takes the code from it). If the code pak is the loaded one the answer is the one of the plain function.
    /// </summary>
    function SetPureServerChecksumsWithGamePak(const AChecksums: TArray<Cardinal>; AGamePakChecksum: Cardinal;
      const ADllName: string; out AMissing: TArray<Cardinal>; out AMissingGamePak: Cardinal;
      ALoadedFileFromDir: Boolean = False): TGamePureReply;
    /// <summary>
    ///   GetPureServerChecksums with the code pak: the checksums of the lock and the code pak for an operating system
    ///   (<c>AOS</c> >= 0: <c>gamePakForOS[AOS]</c>, 0 when the system is not known; negative: the loaded one)
    /// </summary>
    function GetPureServerChecksumsForOS(AOS: Integer; out AGamePakChecksum: Cardinal): TArray<Cardinal>;
    /// <summary>
    ///   SetRestartChecksums: remembers the paks (in order) and the code pak a restart in pure mode has to use.
    ///   <c>EGameFsException</c> when a checksum has no pak (the original is a fatal error). An addon pak found
    ///   is added to <c>RestartAddonChecksums</c> (it has to be searched to be marked pure)
    /// </summary>
    procedure SetRestartChecksums(const AChecksums: TArray<Cardinal>; AGamePakChecksum: Cardinal);
    function RestartChecksums: TArray<Cardinal>;
    function RestartAddonChecksums: TArray<Cardinal>;
    function RestartGamePakChecksum: Cardinal;    /// <summary>GetPackStatus: how the pak counts (computed once)</summary>
    function GetPackStatus(const APack: IGamePack): TGamePureStatus;
  end;

implementation

end.
