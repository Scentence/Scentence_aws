import os
import psycopg2
from psycopg2 import pool
from contextlib import contextmanager
from dotenv import load_dotenv
import logging

load_dotenv()

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# DB 설정
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME", "perfume_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
}

RECOM_DB_CONFIG = {
    **DB_CONFIG,
    "dbname": os.getenv("RECOM_DB_NAME", "recom_db"),
}

_pg_pool = None
_recom_pg_pool = None
_nmap_pg_pool = None  # [개선] 향수지도 전용 Connection Pool (다른 API 격리)


def initialize_pool():
    global _pg_pool
    try:
        if not _pg_pool:
            logger.info(f"🔌 Connecting to perfume_db at {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
            _pg_pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=1, 
                maxconn=10, 
                connect_timeout=10,
                **DB_CONFIG
            )
            logger.info("✅ DB Connection Pool created successfully")
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"❌ Error while connecting to PostgreSQL: {error}")
        _pg_pool = None  # 명시적으로 None 설정


def initialize_recom_pool():
    global _recom_pg_pool
    try:
        if not _recom_pg_pool:
            logger.info(f"🔌 Connecting to recom_db at {RECOM_DB_CONFIG['host']}:{RECOM_DB_CONFIG['port']}...")
            _recom_pg_pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=1, 
                maxconn=10, 
                connect_timeout=10,
                **RECOM_DB_CONFIG
            )
            logger.info("✅ Recom DB Connection Pool created successfully")
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"❌ Error while connecting to Recom DB: {error}")
        _recom_pg_pool = None  # 명시적으로 None 설정


def close_pool():
    global _pg_pool
    if _pg_pool:
        _pg_pool.closeall()
        logger.info("🛑 DB Connection Pool closed")


def close_recom_pool():
    global _recom_pg_pool
    if _recom_pg_pool:
        _recom_pg_pool.closeall()
        logger.info("🛑 Recom DB Connection Pool closed")


# [개선] 향수지도 전용 Connection Pool (다른 API와 격리)
def initialize_nmap_pool():
    """향수지도 전용 DB Connection Pool 초기화 (EC2 프로덕션 최적화)"""
    global _nmap_pg_pool
    try:
        if not _nmap_pg_pool:
            # [개선] EC2 배포: 싱글 워커 환경에 맞춰 보수적 설정
            minconn = int(os.getenv("NMAP_POOL_MIN", "1"))  # 기본 1
            maxconn = int(os.getenv("NMAP_POOL_MAX", "3"))  # 기본 3 (5→3)
            
            if DATABASE_URL:
                logger.info(f"🗺️ [NMap] Connecting via PERFUME_DATABASE_URL... (min:{minconn}, max:{maxconn})")
                _nmap_pg_pool = psycopg2.pool.ThreadedConnectionPool(
                    minconn=minconn,
                    maxconn=maxconn,  # [개선] 프로덕션: 3개로 축소
                    dsn=DATABASE_URL
                )
            else:
                logger.info(f"🗺️ [NMap] Connecting via DB_CONFIG... (min:{minconn}, max:{maxconn})")
                _nmap_pg_pool = psycopg2.pool.ThreadedConnectionPool(
                    minconn=minconn,
                    maxconn=maxconn,  # [개선] 프로덕션: 3개로 축소
                    **DB_CONFIG
                )
            logger.info(f"✅ [NMap] 향수지도 전용 Connection Pool 생성 완료 (max: {maxconn})")
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"❌ [NMap] Connection Pool 생성 실패: {error}")


def close_nmap_pool():
    """향수지도 전용 Connection Pool 종료"""
    global _nmap_pg_pool
    if _nmap_pg_pool:
        _nmap_pg_pool.closeall()
        logger.info("🛑 [NMap] 향수지도 Connection Pool closed")


@contextmanager
def get_db_connection():
    global _pg_pool
    if not _pg_pool:
        initialize_pool()
    
    # pool 초기화 실패 시 예외 발생
    if not _pg_pool:
        raise Exception("Database connection pool is not initialized. Check DB_HOST and DB_PORT.")
    
    conn = _pg_pool.getconn()
    try:
        yield conn
    finally:
        _pg_pool.putconn(conn)


@contextmanager
def get_recom_db_connection():
    global _recom_pg_pool
    if not _recom_pg_pool:
        initialize_recom_pool()
    
    # pool 초기화 실패 시 예외 발생
    if not _recom_pg_pool:
        raise Exception("Recom database connection pool is not initialized. Check DB_HOST and DB_PORT.")
    
    conn = _recom_pg_pool.getconn()
    try:
        yield conn
    finally:
        _recom_pg_pool.putconn(conn)


# [개선] 향수지도 전용 DB Connection (다른 API와 완전 격리)
@contextmanager
def get_nmap_db_connection():
    """향수지도 전용 DB Connection (다른 페이지 영향 방지)"""
    global _nmap_pg_pool
    if not _nmap_pg_pool:
        initialize_nmap_pool()
    conn = _nmap_pg_pool.getconn()
    try:
        yield conn
    finally:
        _nmap_pg_pool.putconn(conn)


# [추가됨] 테이블 자동 생성 함수
def init_db_schema():
    """
    서버 시작 시 또는 배치 시작 시 호출되어
    필요한 테이블이 없으면 자동으로 생성합니다.
    """
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS TB_PERFUME_SIMILARITY (
        perfume_id_a INTEGER NOT NULL,
        perfume_id_b INTEGER NOT NULL,
        score FLOAT NOT NULL,
        PRIMARY KEY (perfume_id_a, perfume_id_b)
    );
    
    -- 기존 인덱스
    CREATE INDEX IF NOT EXISTS idx_sim_score ON TB_PERFUME_SIMILARITY (score DESC);
    CREATE INDEX IF NOT EXISTS idx_sim_a ON TB_PERFUME_SIMILARITY (perfume_id_a);
    
    -- 성능 최적화 인덱스 (유사도 엣지 조회 속도 향상)
    CREATE INDEX IF NOT EXISTS idx_sim_b ON TB_PERFUME_SIMILARITY (perfume_id_b);
    CREATE INDEX IF NOT EXISTS idx_sim_score_a ON TB_PERFUME_SIMILARITY (score DESC, perfume_id_a);
    CREATE INDEX IF NOT EXISTS idx_sim_score_b ON TB_PERFUME_SIMILARITY (score DESC, perfume_id_b);
    """

    # 먼저 pool 초기화 시도
    initialize_pool()
    
    # pool이 생성되지 않았으면 스킵
    if not _pg_pool:
        logger.warning("⚠️ DB connection pool not available, skipping schema initialization")
        return False
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(create_table_sql)
                conn.commit()
        logger.info("✅ Database schema initialized (Table check complete).")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to initialize DB schema: {e}")
        return False
