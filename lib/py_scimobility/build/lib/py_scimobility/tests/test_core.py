from unittest import TestCase
import warnings

import py_scimobility.core as mob

import numpy as np


class Test_ComputeGeoDistance(TestCase):
    def test_with_all_nan(self):
        """
        Test to ensure that input of all NaN returns NaN
        """
        distance = mob.compute_geo_distance([np.nan, np.nan], [np.nan, np.nan])
        self.assertTrue(np.isnan(distance))

    def test_with_one_nan(self):
        """
        Test to ensure that input of one NaN returns NaN
        """
        distance = mob.compute_geo_distance([1, 1], [-1, np.nan])
        self.assertTrue(np.isnan(distance))

    def test_with_same_coords(self):
        """
        Test that same coordinates returns distance of zero
        """
        distance = mob.compute_geo_distance([1, 1], [1, 1])
        self.assertTrue(distance == 0)

    def test_with_diff_coords_nonzero(self):
        """
        Test that different coordinates returns non-zero distance
        """
        distance = mob.compute_geo_distance([1, 1], [-1, -1])
        self.assertTrue(distance > 0)

    def test_with_invalid_coords(self):
        """
        Test that invalid coordinates returns NaN
        """
        with self.assertRaises(Exception) as context:
            distance = mob.compute_geo_distance([500, 500], [500, 500])
            print(distance)

        self.assertTrue(isinstance(context.exception, ValueError))

    def test_flipped_coords(self):
        """
        Test that invalid coordinates returns NaN
        """
        distance1 = mob.compute_geo_distance([1, -1], [2, -2])
        distance2 = mob.compute_geo_distance([2, -2], [1, -1])

        # Some difference is expected, check that they are nearly the same
        self.assertAlmostEqual(distance1, distance2)
