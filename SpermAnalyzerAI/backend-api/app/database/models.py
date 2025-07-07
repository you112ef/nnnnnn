# SpermAnalyzerAI - Database Models
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime
from typing import Optional, Dict, Any
import uuid

Base = declarative_base()

class AnalysisRecord(Base):
    """Database model for storing sperm analysis results"""
    __tablename__ = "analysis_records"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    file_type = Column(String, nullable=False)  # 'image' or 'video'
    file_size = Column(Integer, nullable=False)
    
    # Analysis status
    status = Column(String, default="pending")  # pending, processing, completed, failed
    progress = Column(Float, default=0.0)
    error_message = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=func.now())
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    # Analysis results (stored as JSON)
    total_sperm_count = Column(Integer, nullable=True)
    concentration = Column(Float, nullable=True)  # sperm/ml
    motility_percentage = Column(Float, nullable=True)
    
    # CASA Parameters
    vcl = Column(Float, nullable=True)  # Velocity Curvilinear
    vsl = Column(Float, nullable=True)  # Velocity Straight Line
    vap = Column(Float, nullable=True)  # Velocity Average Path
    lin = Column(Float, nullable=True)  # Linearity
    str_value = Column(Float, nullable=True)  # Straightness
    wob = Column(Float, nullable=True)  # Wobble
    alh = Column(Float, nullable=True)  # Amplitude of Lateral Head Displacement
    bcf = Column(Float, nullable=True)  # Beat Cross Frequency
    
    # Morphology percentages
    normal_morphology = Column(Float, nullable=True)
    head_defects = Column(Float, nullable=True)
    neck_defects = Column(Float, nullable=True)
    tail_defects = Column(Float, nullable=True)
    
    # Velocity data and tracking results (JSON)
    velocity_data = Column(JSON, nullable=True)
    tracking_data = Column(JSON, nullable=True)
    detection_data = Column(JSON, nullable=True)
    
    # Analysis metadata
    analysis_duration = Column(Float, nullable=True)  # seconds
    frame_count = Column(Integer, nullable=True)
    fps = Column(Float, nullable=True)
    resolution = Column(String, nullable=True)  # "1920x1080"
    
    # Quality assessment
    sample_quality = Column(String, nullable=True)  # excellent, good, poor
    confidence_score = Column(Float, nullable=True)
    
    # Additional metadata
    metadata = Column(JSON, nullable=True)

class SystemStats(Base):
    """Database model for storing system performance statistics"""
    __tablename__ = "system_stats"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    timestamp = Column(DateTime, default=func.now())
    
    # CPU and Memory
    cpu_usage = Column(Float)
    memory_usage = Column(Float)
    memory_total = Column(Float)
    
    # Disk
    disk_usage = Column(Float)
    disk_total = Column(Float)
    
    # Analysis statistics
    total_analyses = Column(Integer, default=0)
    successful_analyses = Column(Integer, default=0)
    failed_analyses = Column(Integer, default=0)
    
    # Model performance
    avg_processing_time = Column(Float, nullable=True)
    
    # Additional metrics
    metadata = Column(JSON, nullable=True)

class UserSession(Base):
    """Database model for tracking user sessions (optional)"""
    __tablename__ = "user_sessions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_token = Column(String, unique=True, nullable=False)
    created_at = Column(DateTime, default=func.now())
    last_activity = Column(DateTime, default=func.now())
    
    # Session metadata
    device_info = Column(JSON, nullable=True)
    analyses_count = Column(Integer, default=0)
    
    # Session status
    is_active = Column(Boolean, default=True)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert session to dictionary"""
        return {
            "id": self.id,
            "session_token": self.session_token,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_activity": self.last_activity.isoformat() if self.last_activity else None,
            "analyses_count": self.analyses_count,
            "is_active": self.is_active
        }