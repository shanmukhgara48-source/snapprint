from pydantic import BaseModel


class FirebaseAuthRequest(BaseModel):
    id_token: str          # Firebase ID token — proof the caller owns this UID
    phone: str
    role: str = "customer"
    fcm_token: str | None = None
    referred_by_code: str | None = None  # referral code entered by new user at signup


class UserResponse(BaseModel):
    id: str
    firebase_uid: str
    phone: str
    role: str
    is_active: bool
    fcm_token: str | None = None
    referral_code: str | None = None

    model_config = {"from_attributes": True}
