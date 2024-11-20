# Constants for bit fields
NR_BITS = 8
TYPE_BITS = 8
SIZE_BITS = 14
DIR_BITS = 2

NR_MASK = (1 << NR_BITS) - 1
TYPE_MASK = (1 << TYPE_BITS) - 1
SIZE_MASK = (1 << SIZE_BITS) - 1
DIR_MASK = (1 << DIR_BITS) - 1

NR_SHIFT = 0
TYPE_SHIFT = NR_SHIFT + NR_BITS
SIZE_SHIFT = TYPE_SHIFT + TYPE_BITS
DIR_SHIFT = SIZE_SHIFT + SIZE_BITS

# IOCTL directions
NONE = 0  # No ioctl direction
WRITE = 1  # Write ioctl direction
READ = 2  # Read ioctl direction


def command(direction: int, typ: int, nr: int, size: int) -> int:
    """Generate an ioctl command from the supplied arguments."""
    return (
        ((direction) << DIR_SHIFT)
        | ((typ) << TYPE_SHIFT)
        | ((nr) << NR_SHIFT)
        | ((size) << SIZE_SHIFT)
    )
