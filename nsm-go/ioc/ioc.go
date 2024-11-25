// Package ioc generates the proper ioctl command numbers.
//
// Based on C sources from Linux kernel:
// * https://github.com/torvalds/linux/blob/master/include/asm-generic/ioctl.h
// * https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/ioctl.h
package ioc

import (
	"fmt"
)

const (
	cNRBITS    uint = 8
	cTYPEBITS  uint = 8
	cSIZEBITS  uint = 14
	cDIRBITS   uint = 2
	cNRMASK    uint = ((1 << cNRBITS) - 1)
	cTYPEMASK  uint = ((1 << cTYPEBITS) - 1)
	cSIZEMASK  uint = ((1 << cSIZEBITS) - 1)
	cDIRMASK   uint = ((1 << cDIRBITS) - 1)
	cNRSHIFT   uint = 0
	cTYPESHIFT uint = (cNRSHIFT + cNRBITS)
	cSIZESHIFT uint = (cTYPESHIFT + cTYPEBITS)
	cDIRSHIFT  uint = (cSIZESHIFT + cSIZEBITS)

	// NONE - No ioctl direction.
	NONE uint = 0

	// WRITE - Write ioctl direction.
	WRITE uint = 1

	// READ - Read ioctl direction.
	READ uint = 2
)

// Command generates an ioctl command from the supplied arguments.
func Command(dir, typ, nr, size uint) uint {
	// [ioc] Command input: dir: 3, typ: 10, nr: 0, size: 32
	// fmt.Printf("[ioc] Command input: dir: %d, typ: %d, nr: %d, size: %d\n", dir, typ, nr, size)

	// [ioc] cDIRSHIFT: 30, cTYPESHIFT: 8, cNRSHIFT: 0, cSIZESHIFT: 16
	// fmt.Printf("[ioc] cDIRSHIFT: %d, cTYPESHIFT: %d, cNRSHIFT: %d, cSIZESHIFT: %d\n", cDIRSHIFT, cTYPESHIFT, cNRSHIFT, cSIZESHIFT)

	result := (((dir) << cDIRSHIFT) |
		((typ) << cTYPESHIFT) |
		((nr) << cNRSHIFT) |
		((size) << cSIZESHIFT))

	// [ioc] Command output: 3223325184
	// fmt.Printf("[ioc] Command output: %d\n", result)

	return result
}
