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

    # check if centers are equal
    if center1 == center2
        return true
    end


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

# if therer is a overlap remove the last added and replace it with a new one
function fAddIco!( config, theta, positionX, positionY, positionZ, resolution, radiusX, radiusY, radiusZ )
    # check overlap
    to_remove = Int64[]
    for (ind, row) in enumerate(eachrow(config))
        if row.objectType == "icoSphere"
            if check_overlap([positionX, positionY, positionZ], [radiusX, radiusY, radiusZ], 
                    [row.positionX, row.positionY, row.positionZ], [row.objectParameter2, row.objectParameter3, row.objectParameter4])
                push!(to_remove, ind)
            end
        end
    end
    delete!(config, to_remove)
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

# write function analog to 
#=
func bool setGrid(int offsetInd, int num, real[int] & Mid, real sizeLBox){
    
    if(num == 0){return true;}

    // if only one particle set Mid Point as Position
    if(num == 1){return setPos(offsetInd, Mid, true);}

    IFMACRO(SPECTRUE, TRUE)
    // check the length of the given range
    checkLength(offsetInd, num)
    ENDIFMACRO
    
    // create the array for the grid
    real[int] a(3*num);

    // get the dimension of lattice box
    int dimLBox = int(ceil(num^(1.0/3.0)));

    // get equidistant distances of the particles
    real eqSize = sizeLBox / (dimLBox - 1);

    // set the offset of the particles, such that the mid point of the
    // grid is at the @ center 
    real[int] offset(3); offset = - eqSize  * ( floor(dimLBox/2.0) - ((dimLBox+1) % 2)/2.0  );
    // * ((round(dimLBox/2)-1) + ((dimLBox+1) % 2)/2.0); 
    
    offset = offset + Mid; 
    // set the particles
    real[int] temp(3);
    for(int ind = 0; ind < num; ind++){
        temp[0] = eqSize * (ind % dimLBox) + offset[0];
        temp[1] = eqSize * (div(ind, dimLBox) % dimLBox) + offset[1];
        temp[2] = eqSize * (div(ind, dimLBox * dimLBox) % dimLBox) + offset[2];
        if(!setPos(offsetInd + ind, temp, true)){return false;}
    }

    return true;
}
=#




function cubicArray( dimension, size, config, theta, resolution, radius1, radius2, radius3, fAdd=false )
    # center the array
    offset = - size * ( floor(dimension/2.0) - ((dimension+1) % 2)/2.0  );
    # set the particles
    pos = zeros(3)
    for ind = 1:dimension^3
        pos[1] = size * (ind % dimension) + offset
        pos[2] = size * (div(ind, dimension) % dimension) + offset
        pos[3] = size * (div(ind, dimension^2) % dimension) + offset
        if !fAdd
            addIco( config, theta, pos[1], pos[2], pos[3], resolution, radius1, radius2, radius3 )
        else
            fAddIco( config, theta, pos[1], pos[2], pos[3], resolution, radius1, radius2, radius3 )
        end
    end
end
