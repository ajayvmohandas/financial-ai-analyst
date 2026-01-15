"""Enhanced logger configuration with structured logging."""

import structlog
import sys
from typing import Any, Dict
import os


def configure_logging(log_level: str = "INFO") -> None:
    """Configure structured logging with structlog.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
    """
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer() if os.getenv("LOG_FORMAT") == "json" 
            else structlog.dev.ConsoleRenderer(colors=True)
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Configure standard library logging
    import logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level.upper(), logging.INFO)
    )


# Initialize logger
configure_logging(os.getenv("LOG_LEVEL", "INFO"))
logger = structlog.get_logger()
