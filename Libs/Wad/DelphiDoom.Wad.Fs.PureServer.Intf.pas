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
  ///   share, in the same order). Not ported: the game code pak (the DLL checksum and the PURE_NODLL and
  ///   PURE_RESTART answers it gives), the restart checksums and the paks that were just downloaded.
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
    /// <summary>GetPackStatus: how the pak counts (computed once)</summary>
    function GetPackStatus(const APack: IGamePack): TGamePureStatus;
  end;

implementation

end.
