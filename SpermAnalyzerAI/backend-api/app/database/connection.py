# SpermAnalyzerAI - Database Connection Management
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
from contextlib import contextmanager
from typing import Generator
import os
from loguru import logger

from .models import Base
from ..utils.config import settings

# Database URL
DATABASE_URL = f"sqlite:///{settings.DATABASE_PATH}"

# Create engine with connection pooling
engine = create_engine(
    DATABASE_URL,
    poolclass=StaticPool,
    connect_args={
        "check_same_thread": False,
        "timeout": 20
    },
    echo=settings.DEBUG  # Log SQL queries in debug mode
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_tables():
    """Create all database tables"""
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
        raise

def get_db() -> Generator[Session, None, None]:
    """
    Dependency function to get database session
    Usage with FastAPI: Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        logger.error(f"Database session error: {e}")
        db.rollback()
        raise
    finally:
        db.close()

@contextmanager
def get_db_session() -> Generator[Session, None, None]:
    """
    Context manager for database sessions
    Usage: 
    with get_db_session() as db:
        # use db session
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception as e:
        logger.error(f"Database transaction error: {e}")
        db.rollback()
        raise
    finally:
        db.close()

class DatabaseManager:
    """Database management utilities"""
    
    @staticmethod
    def init_database():
        """Initialize database with tables and initial data"""
        try:
            # Create tables
            create_tables()
            
            # Create necessary directories
            os.makedirs(settings.UPLOAD_PATH, exist_ok=True)
            os.makedirs(settings.RESULTS_PATH, exist_ok=True)
            os.makedirs(os.path.dirname(settings.DATABASE_PATH), exist_ok=True)
            
            logger.info("Database initialized successfully")
            
        except Exception as e:
            logger.error(f"Database initialization failed: {e}")
            raise
    
    @staticmethod
    def cleanup_old_records(days: int = 30):
        """Remove analysis records older than specified days"""
        from datetime import datetime, timedelta
        from .models import AnalysisRecord
        
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            with get_db_session() as db:
                # Get old records
                old_records = db.query(AnalysisRecord).filter(
                    AnalysisRecord.created_at < cutoff_date
                ).all()
                
                # Delete associated files
                for record in old_records:
                    try:
                        if os.path.exists(record.file_path):
                            os.remove(record.file_path)
                    except Exception as e:
                        logger.warning(f"Failed to delete file {record.file_path}: {e}")
                
                # Delete database records
                deleted_count = db.query(AnalysisRecord).filter(
                    AnalysisRecord.created_at < cutoff_date
                ).delete()
                
                logger.info(f"Cleaned up {deleted_count} old analysis records")
                
        except Exception as e:
            logger.error(f"Cleanup failed: {e}")
    
    @staticmethod
    def get_database_stats():
        """Get database statistics"""
        from .models import AnalysisRecord, SystemStats
        
        try:
            with get_db_session() as db:
                total_analyses = db.query(AnalysisRecord).count()
                completed_analyses = db.query(AnalysisRecord).filter(
                    AnalysisRecord.status == "completed"
                ).count()
                failed_analyses = db.query(AnalysisRecord).filter(
                    AnalysisRecord.status == "failed"
                ).count()
                
                # Database file size
                db_size = 0
                if os.path.exists(settings.DATABASE_PATH):
                    db_size = os.path.getsize(settings.DATABASE_PATH)
                
                return {
                    "total_analyses": total_analyses,
                    "completed_analyses": completed_analyses,
                    "failed_analyses": failed_analyses,
                    "database_size_mb": round(db_size / (1024 * 1024), 2),
                    "database_path": settings.DATABASE_PATH
                }
                
        except Exception as e:
            logger.error(f"Failed to get database stats: {e}")
            return {}

# Event listeners for database optimization
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    """Set SQLite optimization settings"""
    cursor = dbapi_connection.cursor()
    # Enable foreign keys
    cursor.execute("PRAGMA foreign_keys=ON")
    # Set journal mode to WAL for better concurrency
    cursor.execute("PRAGMA journal_mode=WAL")
    # Set synchronous mode for better performance
    cursor.execute("PRAGMA synchronous=NORMAL")
    # Set cache size (negative value means KB)
    cursor.execute("PRAGMA cache_size=-64000")  # 64MB cache
    cursor.close()

# Initialize database on module import
if not os.path.exists(settings.DATABASE_PATH):
    DatabaseManager.init_database()