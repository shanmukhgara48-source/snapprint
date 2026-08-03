from pydantic import BaseModel, Field


class FirebaseAuthRequest(BaseModel):
    id_token: str = Field(min_length=20, max_length=10_000)
    phone: str = Field(pattern=r"^\+[1-9][0-9]{7,14}$")
    role: str = "customer"
    fcm_token: str | None = Field(default=None, max_length=4096)
    referred_by_code: str | None = Field(default=None, min_length=1, max_length=64)


class UserResponse(BaseModel):
    id: str
    firebase_uid: str
    phone: str
    role: str
    is_active: bool
    fcm_token: str | None = None
    referral_code: str | None = None

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
