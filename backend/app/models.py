
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func, Text
from sqlalchemy.orm import relationship
from .database import Base

class List(Base):
    __tablename__ = "lists"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, unique=True, index=True)
    created_at = Column(DateTime, server_default=func.now())

    choices = relationship("Choice", back_populates="list", cascade="all, delete-orphan")

class Choice(Base):
    __tablename__ = "choices"
    id = Column(Integer, primary_key=True, index=True)
    list_id = Column(Integer, ForeignKey("lists.id", ondelete="CASCADE"), nullable=False, index=True)
    text = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    list = relationship("List", back_populates="choices")
