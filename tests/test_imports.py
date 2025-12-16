"""Basic import tests to verify project structure."""

import sys
from pathlib import Path

# Add src directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


def test_import_main():
    """Test that main module can be imported."""
    from src import main
    assert main is not None


def test_import_data_fetcher():
    """Test that data_fetcher module can be imported."""
    from src import data_fetcher
    assert data_fetcher is not None


def test_import_analyzers():
    """Test that analyzers module can be imported."""
    from src import analyzers
    assert analyzers is not None


def test_import_recommender():
    """Test that recommender module can be imported."""
    from src import recommender
    assert recommender is not None


def test_src_package_version():
    """Test that src package has a version."""
    from src import __version__
    assert __version__ == "0.1.0"
