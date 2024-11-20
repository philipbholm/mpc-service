"""Package response contains commonly used constructs for NSM responses."""

from dataclasses import dataclass
from typing import List, Optional
from enum import Enum


class Digest(str, Enum):
    """Digest types supported by NSM."""
    SHA256 = "SHA256"
    SHA384 = "SHA384"
    SHA512 = "SHA512"


class ErrorCode(str, Enum):
    """Error codes returned by NSM."""
    SUCCESS = "Success"
    INVALID_ARGUMENT = "InvalidArgument"
    INVALID_RESPONSE = "InvalidResponse"
    READ_ONLY_INDEX = "ReadOnlyIndex"
    INVALID_OPERATION = "InvalidOperation"
    BUFFER_TOO_SMALL = "BufferTooSmall"
    INPUT_TOO_LARGE = "InputTooLarge"
    INTERNAL_ERROR = "InternalError"


@dataclass
class DescribePCR:
    """A DescribePCR response."""
    lock: bool
    data: bytes


@dataclass
class ExtendPCR:
    """An ExtendPCR response."""
    data: bytes


@dataclass
class LockPCR:
    """A LockPCR response."""
    pass


@dataclass
class LockPCRs:
    """A LockPCRs response."""
    pass


@dataclass
class DescribeNSM:
    """A DescribeNSM response."""
    version_major: int
    version_minor: int
    version_patch: int
    module_id: str
    max_pcrs: int
    locked_pcrs: List[int]
    digest: Digest


@dataclass
class Attestation:
    """An Attestation response."""
    document: bytes


@dataclass
class GetRandom:
    """A GetRandom response."""
    random: bytes


@dataclass
class Response:
    """NSM Response structure.
    
    One and only one field is set at any time. Always check the error field first.
    """
    describe_pcr: Optional[DescribePCR] = None
    extend_pcr: Optional[ExtendPCR] = None
    lock_pcr: Optional[LockPCR] = None
    lock_pcrs: Optional[LockPCRs] = None
    describe_nsm: Optional[DescribeNSM] = None
    attestation: Optional[Attestation] = None
    get_random: Optional[GetRandom] = None
    error: Optional[ErrorCode] = None

    @classmethod
    def from_cbor(cls, data: bytes) -> 'Response':
        """Create a Response object from CBOR-encoded data.
        
        Args:
            data: CBOR-encoded response data
            
        Returns:
            Decoded Response object
            
        Raises:
            ValueError: If the response data is invalid
        """
        import cbor2
        
        decoded = cbor2.loads(data)
        
        if isinstance(decoded, str):
            # Handle string responses (LockPCR, LockPCRs)
            if decoded == "LockPCR":
                return cls(lock_pcr=LockPCR())
            elif decoded == "LockPCRs":
                return cls(lock_pcrs=LockPCRs())
            else:
                raise ValueError(f"Unknown string response: {decoded}")
                
        elif isinstance(decoded, dict):
            # Handle map responses
            response = cls()
            
            if "Error" in decoded:
                response.error = ErrorCode(decoded["Error"])
                
            if "DescribePCR" in decoded:
                data = decoded["DescribePCR"]
                response.describe_pcr = DescribePCR(
                    lock=data["lock"],
                    data=data["data"]
                )
                
            if "ExtendPCR" in decoded:
                data = decoded["ExtendPCR"]
                response.extend_pcr = ExtendPCR(data=data["data"])
                
            if "DescribeNSM" in decoded:
                data = decoded["DescribeNSM"]
                response.describe_nsm = DescribeNSM(
                    version_major=data["version_major"],
                    version_minor=data["version_minor"],
                    version_patch=data["version_patch"],
                    module_id=data["module_id"],
                    max_pcrs=data["max_pcrs"],
                    locked_pcrs=data["locked_pcrs"],
                    digest=Digest(data["digest"])
                )
                
            if "Attestation" in decoded:
                data = decoded["Attestation"]
                response.attestation = Attestation(document=data["document"])
                
            if "GetRandom" in decoded:
                data = decoded["GetRandom"]
                response.get_random = GetRandom(random=data["random"])
                
            return response
            
        raise ValueError("Invalid response format")