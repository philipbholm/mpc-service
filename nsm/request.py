from dataclasses import dataclass
from typing import Any

class Request:
    """Base request interface."""
    
    def encoded(self) -> dict[str, Any]:
        """Returns the encoded form of the request for CBOR serialization."""
        raise NotImplementedError


@dataclass
class DescribePCR(Request):
    """A DescribePCR request."""
    index: int

    def encoded(self) -> dict[str, 'DescribePCR']:
        return {"DescribePCR": self}


@dataclass
class ExtendPCR(Request):
    """An ExtendPCR request."""
    index: int
    data: bytes

    def encoded(self) -> dict[str, 'ExtendPCR']:
        return {"ExtendPCR": self}


@dataclass
class LockPCR(Request):
    """A LockPCR request."""
    index: int

    def encoded(self) -> dict[str, 'LockPCR']:
        return {"LockPCR": self}


@dataclass
class LockPCRs(Request):
    """A LockPCRs request."""
    range: int

    def encoded(self) -> dict[str, 'LockPCRs']:
        return {"LockPCRs": self}


@dataclass
class DescribeNSM(Request):
    """A DescribeNSM request."""

    def encoded(self) -> str:
        return "DescribeNSM"


@dataclass
class Attestation(Request):
    """An Attestation request."""
    user_data: bytes
    nonce: bytes
    public_key: bytes

    def encoded(self) -> dict[str, 'Attestation']:
        return {"Attestation": self}


@dataclass
class GetRandom(Request):
    """A GetRandom request."""

    def encoded(self) -> str:
        return "GetRandom"