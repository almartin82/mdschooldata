"""
Tests for pymdschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pymdschooldata
    assert pymdschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pymdschooldata
    assert hasattr(pymdschooldata, 'fetch_enr')
    assert callable(pymdschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pymdschooldata
    assert hasattr(pymdschooldata, 'get_available_years')
    assert callable(pymdschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pymdschooldata
    assert hasattr(pymdschooldata, '__version__')
    assert isinstance(pymdschooldata.__version__, str)
