using DataFrames
using NLopt
using Random



#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
# CHECK FOR OVERLAP
#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-

min_spacing = 1e-3;

# Ellipsoid equation function
function ellipsoid_eq(x, center, radii)
    return ((x[1] - center[1]) / radii[1])^2 +
           ((x[2] - center[2]) / radii[2])^2 +
           ((x[3] - center[3]) / radii[3])^2 - 1
end

# Distance function
distance(p1, p2) = sqrt(sum((p1 - p2).^2))

# Objective function: distance between points on ellipsoids
function objective(x, grad)
    p1 = x[1:3]
    p2 = x[4:6]
    return distance(p1, p2)
end

function spheres_overlap(center1, radius1, center2, radius2)
    dist = distance(center1, center2)
    return dist <= min_spacing + radius1 + radius2
end

# Modified check_overlap function
x_tolerance = 1e-7;
function check_overlap(center1, radii1, center2, radii2)
    # Calculate the radii of the enveloping spheres
    radius1 = maximum(radii1)
    radius2 = maximum(radii2)

    # Check if the enveloping spheres overlap
    if !spheres_overlap(center1, radius1, center2, radius2)
        return false
    end

    opt = Opt(:LN_COBYLA, 6)
    min_objective!(opt, objective)

    # Add constraints for each ellipsoid
    inequality_constraint!(opt, (x, grad) -> ellipsoid_eq(x[1:3], center1, radii1), 1e-8)
    inequality_constraint!(opt, (x, grad) -> ellipsoid_eq(x[4:6], center2, radii2), 1e-8)

    # Initial guess: centers of the ellipsoids
    x0 = [center1..., center2...]

    xtol = x_tolerance

    # Set optimization parameters
    xtol_rel!(opt, xtol)

    # Perform the optimization
    (minf, minx, ret) = optimize(opt, x0)

    return minf <= min_spacing
end

#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
# ADD CONDUCTORS
#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-

function addIco( config, theta, positionX, positionY, positionZ, resolution, radiusX, radiusY, radiusZ )
    # check overlap
    for row in eachrow(config)
        if row.objectType == "icoSphere"
            if check_overlap([positionX, positionY, positionZ], [radiusX, radiusY, radiusZ], 
                    [row.positionX, row.positionY, row.positionZ], [row.objectParameter2, row.objectParameter3, row.objectParameter4])
                return false
            end
        end
    end
    push!( config, ["icoSphere", theta, positionX, positionY, positionZ, resolution, radiusX, radiusY, radiusZ] )
    return true
end

function addIcoSphere( config, theta, positionX, positionY, positionZ, resolution, radius )
    return addIco( config, theta, positionX, positionY, positionZ, resolution, radius, radius, radius )
end

# distribute Ico randomly within a sphere of radius R, don't forget to set in prior the seed
function randomIco( R, config, theta, resolution, radius1, radius2, radius3 )
    added = false
    while !added
        # random position
        positionX = rand()*2*R - R
        positionY = rand()*2*R - R
        positionZ = rand()*2*R - R
        # check if inside sphere
        if sqrt(positionX^2 + positionY^2 + positionZ^2) < R
            added = addIco( config, theta, positionX, positionY, positionZ, resolution, radius1, radius2, radius3 )
        end
    end

    return true
end

function randomIcoSphere( R, config, theta, resolution, radius )
    return randomIco( R, config, theta, resolution, radius, radius, radius )
end


