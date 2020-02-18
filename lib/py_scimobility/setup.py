""" setup script for science mobility embedding project project. """
#!/usr/bin/env python
# encoding: utf-8

from setuptools import find_packages
from setuptools import setup

setup(name='py_scimobility',
      version='0.1',
      description='package for the science mobility embedding project',
      author='Dakota Murray, Jisung Yoon, YY Ahn',
      packages=find_packages(exclude=('tests',)),
     )
