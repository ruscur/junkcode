# This is my first time ever writing nim, plz no bully
import std/parseopt
import std/os
import std/strformat
import std/strutils

proc printHelp() =
  echo("Usage: veem --kernel=<kernel_dir> --buildroot=<buildroot_dir>")
  echo("\nOptional args:")
  echo("\t-a=<arch>\t\t--arch=<arch>")
  echo("\t-p=<platform>\t\t--platform=<platform>")
  echo("\t-o=<dir>\t\t--append=<dir>\tOverlay a directory to /root")
  echo("\nMake sure you have ARCH and CROSS_COMPILE set correctly!")
  quit(1)

type
  Arch = enum
    ppc64le
    ppc64be
    ppc32
    x86_64
    arm64
  Platform = enum
    pseries
    powernv

proc getQemuBinary(arch: Arch): string =
  case arch
  of ppc64le, ppc64be:
    return findExe("qemu-system-ppc64")
  of ppc32:
    return findExe("qemu-system-ppc")
  of x86_64:
    return findExe("qemu-system-x86_64")
  of arm64:
    return findExe("qemu-system-aarch64")

var kernelDir: string
var buildrootDir: string
var overlayDir: string = "/tmp/overlay"
var arch: Arch
var platform: Platform
var appendDirs: seq[string]

proc parseArgs() =
  var parser = initOptParser(commandLineParams())

  for kind, key, val in parser.getopt():
    case kind
    #echo(fmt"got cmdArgument: {key}")
    of cmdLongOption, cmdShortOption:
    #echo(fmt"got option: {key} {val}")
      case key
      of "k", "kernel":
        kernelDir = expandTilde(val)
      of "b", "buildroot":
        buildrootDir = expandTilde(val)
      of "a", "arch":
        arch = parseEnum[Arch](val)
      of "p", "platform":
        platform = parseEnum[Platform](val)
      of "o", "append":
        appendDirs.add(expandTilde(val))
      else:
        printHelp()
    of cmdArgument, cmdEnd:
      printHelp()

proc quitIfNonZero(ret: int) =
  if ret != 0:
    quit(ret)

proc cleanOverlay() =
  removeDir(overlayDir)
  createDir(overlayDir)

proc makeKernel() =
  # We're not going to touch config options here.
  setCurrentDir(kernelDir)
  quitIfNonZero(execShellCmd("make -j`nproc`"))
  quitIfNonZero(execShellCmd(fmt"make modules_install -j`nproc` INSTALL_MOD_PATH={overlayDir}"))

proc appendOverlay() =
  # Copy anything specified into the overlay before we build
  createDir(overlayDir / "/root")
  for dir in appendDirs:
    copyDirWithPermissions(dir, overlayDir / "/root")

proc makeBuildroot() =
  setCurrentDir(buildrootDir)
  quitIfNonZero(execShellCmd("make"))

proc runQemu() =
  let cmd = getQemuBinary(arch)
  quitIfNonZero(execShellCmd(fmt"{cmd} -m 2G -machine {platform},usb=off -cpu POWER9 -nodefaults -nographic  -chardev stdio,id=charserial0,mux=on -device spapr-vty,chardev=charserial0,reg=0x30000000 -mon chardev=charserial0,mode=readline -netdev user,id=bridge0,net=192.168.122.0/24,dhcpstart=192.168.122.4 -initrd {buildrootDir}/output/images/rootfs.cpio.zst -kernel {kernelDir}/vmlinux"))

proc main() =
  parseArgs()

  if not (dirExists(kernelDir) and dirExists(buildrootDir)):
    printHelp()

  for dir in appendDirs:
    if not dirExists(dir):
      printHelp()

  if not declared(arch) or not declared(platform):
    printHelp()

  if not existsEnv("ARCH") or not existsEnv("CROSS_COMPILE"):
    printHelp()

  cleanOverlay()
  appendOverlay()
  makeKernel()
  makeBuildroot()
  runQemu()

main()
