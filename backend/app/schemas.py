
from pydantic import BaseModel, field_validator
from typing import List as TList, Optional

class ChoiceBase(BaseModel):
    text: str
    @field_validator("text")
    @classmethod
    def non_empty(cls, v):
        if not v or not v.strip():
            raise ValueError("text must not be empty")
        return v.strip()

class ChoiceCreate(ChoiceBase):
    pass

class ChoiceOut(ChoiceBase):
    id: int
    list_id: int
    class Config:
        from_attributes = True

class ListBase(BaseModel):
    name: str
    @field_validator("name")
    @classmethod
    def non_empty(cls, v):
        v = v.strip()
        if not v:
            raise ValueError("name must not be empty")
        return v

class ListCreate(ListBase):
    pass

class ListOut(ListBase):
    id: int
    class Config:
        from_attributes = True

class ListWithChoices(ListOut):
    choices: TList[ChoiceOut] = []
