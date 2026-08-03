from pydantic import BaseModel, Field, field_validator


class AddressCreate(BaseModel):
    full_address: str = Field(min_length=10, max_length=500)
    city: str = Field(min_length=2, max_length=100)
    pincode: str = Field(pattern=r"^[1-9][0-9]{5}$")
    is_default: bool = False

    @field_validator("full_address", "city")
    @classmethod
    def strip_text(cls, value: str) -> str:
        return value.strip()


class AddressOut(BaseModel):
    id: str
    full_address: str
    city: str
    pincode: str
    is_default: bool

    model_config = {"from_attributes": True}
