from pydantic import BaseModel


class AddressCreate(BaseModel):
    full_address: str
    city: str
    pincode: str
    is_default: bool = False


class AddressOut(BaseModel):
    id: str
    full_address: str
    city: str
    pincode: str
    is_default: bool

    model_config = {"from_attributes": True}
