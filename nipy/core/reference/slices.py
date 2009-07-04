"""
A set of methods to get coordinate maps which represent slices in space.

"""
from nipy.core.reference.coordinate_system import CoordinateSystem
from nipy.core.reference.coordinate_map import AffineTransform
from nipy.core.reference.array_coords import ArrayCoordMap
import numpy as np

__docformat__ = 'restructuredtext'


def from_origin_and_columns(origin, colvectors, shape, function_range):
    """
    Return a CoordinateMap representing a slice based on a given origin, 
    a pair of direction vectors which span the slice, and a shape.

    :Parameters:
        origin : the corner of the output coordinates, i.e. the [0]*ndimin
                 point
        colvectors : the steps in each voxel direction
        shape : how many steps in each voxel direction
        function_range : a CoordinateSystem for the output

    :Returns: `CoordinateMap`
    """
    colvectors = np.asarray(colvectors)
    nout = colvectors.shape[1]
    nin = colvectors.shape[0]

    f = np.zeros((nout+1,nin+1))
    for i in range(nin):
        f[0:nout,i] = colvectors[i]
    f[0:nout,-1] = origin
    f[nout, nin] = 1.

    function_domain = CoordinateSystem(['i%d' % d for d in range(len(shape))], 
                                    'slice', function_range.coord_dtype)

    g = AffineTransform(f, function_domain, function_range)
    return ArrayCoordMap.from_shape(g, shape)

def xslice(x, zlim, ylim, function_range, shape):
    """
    Return a slice through a 3d box with x fixed.

    :Parameters:
        y : TODO
            TODO
        zlim : TODO
            TODO
        ylim : TODO
            TODO
        xlim : TODO
            TODO
        shape : TODO
            TODO
        function_range : TODO
            TODO
    """
    origin = [zlim[0],ylim[0],x]
    colvectors = [[(zlim[1]-zlim[0])/(shape[0] - 1.),0,0],
                  [0,(ylim[1]-ylim[0])/(shape[1] - 1.),0]]
    return from_origin_and_columns(origin, colvectors, shape, function_range)

def yslice(y, zlim, xlim, function_range, shape):
    """
    Return a slice through a 3d box with y fixed.

    :Parameters:
        x : TODO
            TODO
        zlim : TODO
            TODO
        ylim : TODO
            TODO
        xlim : TODO
            TODO
        shape : TODO
            TODO
        function_range : TODO
            TODO
    """
    origin = [zlim[0],y,xlim[0]]
    colvectors = [[(zlim[1]-zlim[0])/(shape[0] - 1.),0,0],
                  [0,0,(xlim[1]-xlim[0])/(shape[1] - 1.)]]
    return from_origin_and_columns(origin, colvectors, shape, function_range)

def zslice(z, ylim, xlim, function_range, shape):    
    """
    Return a slice through a 3d box with z fixed.

    :Parameters:
        z : TODO
            TODO
        ylim : TODO
            TODO
        xlim : TODO
            TODO
        shape : TODO
            TODO
        function_range : TODO
            TODO
    """
    origin = [z,xlim[0],ylim[0]]
    colvectors = [[0,(ylim[1]-ylim[0])/(shape[0] - 1.),0],
                  [0,0,(xlim[1]-xlim[0])/(shape[1] - 1.)]]
    return from_origin_and_columns(origin, colvectors, shape, function_range)



def bounding_box(coordmap, shape):
    """
    Determine a valid bounding box from a CoordinateMap instance.

    :Parameters:
        coordmap : `CoordinateMap`

    """
    e = ArrayCoordMap.from_shape(coordmap, shape)
    return [[r.min(), r.max()] for r in e.transposed_values]
    
