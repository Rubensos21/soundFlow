from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .db import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    display_name = Column(String(255))
    dob = Column(String(20))
    gender = Column(String(20))
    created_at = Column(TIMESTAMP, server_default=func.now())

    streaming_accounts = relationship("UserStreamingAccount", back_populates="user")


class UserStreamingAccount(Base):
    __tablename__ = "user_streaming_accounts"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    platform = Column(String(20), nullable=False)
    access_token = Column(Text, nullable=False)
    refresh_token = Column(Text)
    expires_at = Column(TIMESTAMP)
    platform_user_id = Column(String(100))
    created_at = Column(TIMESTAMP, server_default=func.now())

    user = relationship("User", back_populates="streaming_accounts")


class AIGeneratedPlaylist(Base):
    __tablename__ = "ai_generated_playlists"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    playlist_name = Column(String(200), nullable=False)
    generation_method = Column(String(20), nullable=False)
    emotion_detected = Column(String(50))
    prompt_used = Column(Text)
    tracks = Column(JSON, nullable=False)
    platform = Column(String(20), nullable=False)
    platform_playlist_id = Column(String(100))
    created_at = Column(TIMESTAMP, server_default=func.now())


class UserMusicProfile(Base):
    __tablename__ = "user_music_profile"
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    favorite_genres = Column(JSON)
    top_artists = Column(JSON)
    recently_played = Column(JSON)
    disliked_genres = Column(JSON)
    last_updated = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


