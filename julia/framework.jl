using CSV
using DataFrames

#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
# READER
#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-

# Function to read a CSV file
function read_csv(filepath)
    return CSV.read(filepath, DataFrame)
end

# Function to write a DataFrame to a CSV file
function write_csv(df, filepath)
    CSV.write(filepath, df)
end

# Function to read a capacitance matrix from a CSV file
function read_capacitance(filepath)
    # Read the CSV file into a DataFrame
    df = CSV.read(filepath, DataFrame, header=false)

    # Replace missing values with NaN
    df = coalesce.(df, NaN)

    # Convert the DataFrame to a matrix
    mat = Matrix(df)

    # Get the size of the matrix
    n = size(mat, 1)

    # Initialize a new matrix
    new_mat = zeros(n, n)

    for i in 1:n
        for j in 1:n
            new_mat[i, j] = mat[i, (n+j-i) % n + 1]    
            if j <= i
                new_mat[i, j] = mat[j, (n+i-j) % n + 1]
            end
        end
    end

    return new_mat 
end

# Function read filepath in order to obtain config and data
function read_data(dataPath, dataName, sfc=false)
    dataLogFile = joinpath(dataPath, dataName * ".log")
    capFilename = "cap_" * dataName * ".log"
    if sfc; capFilename = "capSfc_" * dataName * ".log"; end
    capFile = joinpath(dataPath, capFilename)

    # Check if dataLogFile exists
    if !isfile(dataLogFile)
        error("dataLogFile does not exist: ", dataLogFile)
    end

    configFile = ""
    open(dataLogFile, "r") do file
        lines = readlines(file)
        if length(lines) >= 4
            configFile = lines[4]
        else
            error("dataLogFile does not contain enough lines")
        end
    end

    configFilePath = joinpath("..", configFile)
    # Check if configFile exists
    if !isfile(configFilePath)
        error("configFile does not exist: ", configFilePath)
    end

    config = read_csv(configFilePath)

    # Check if capacitance file exists
    if !isfile(capFile)
        error("Capacitance file does not exist: ", capFile)
    end

    cap = read_capacitance(capFile)
    return config, cap
end

#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
# STRUCTURE
#-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-

function initConfig( )
    """ 
    Datastructure example:
    objectType,theta,positionX,positionY,positionZ,objectParameter1,objectParameter2,objectParameter3,objectParameter4
    icoSphere,0,3.0,0.0,0.0,6,1.0,1.0,1.0
    icoSphere,1,6.0,0.0,0.0,6,1.0,1.0,1.0
    icoSphere,1,0.0,0.0,0.0,6,1.0,1.0,1.0
    """
    
    config = DataFrame( objectType = String[], 
                        theta = Int64[],
                        positionX = Float64[], positionY = Float64[], positionZ = Float64[],
                        objectParameter1 = Int64[], objectParameter2 = Float64[], objectParameter3 = Float64[], objectParameter4 = Float64[] 
                    )
    return config 
end

function initSetting( )
    """ 
    Datastructure example:
    objectParameter1,objectParameter2,objectParameter3
    boxSizeX,boxSizeY,boxSizeZ
    numElemX,numElemY,numElemZ
    tetgenSwitch, rre, mdh
    """
    
    config = DataFrame( objectParameter1 = Any[], objectParameter2 = Any[], objectParameter3 = Any[] )
    return config 
end


function row_it_old( config )
        fused_array = []
        for col in eachcol(config)
            push!(fused_array, col)
        end
        # merge pos_x, pos_y, pos_z and transpose
        # fused_array = hcat(fused_array[1:5]...)
        # merge objectParameter1, objectParameter2, objectParameter3, objectParameter4 and transpose
        # fused_array = hcat(fused_array, fused_array[6:9]...)
        pos = Vector{Float64}[]
        for i in 1:nrow(config)
            push!(pos, [fused_array[3][i], fused_array[4][i], fused_array[5][i]])
        end

        rad = Vector{Float64}[]
        for i in 1:nrow(config)
            push!(rad, [fused_array[7][i], fused_array[8][i], fused_array[9][i]])
        end
            
        df_row = DataFrame(
            objectType = [fused_array[1]],
            theta = [fused_array[2]],
            position = [pos],
            resolution_level = [fused_array[6]],
            radius = [rad]
        )

    return df_row
end

function fuse(dataName, config, cap)

    # Create a new DataFrame with a single row
    new_row = DataFrame()

    new_row[!, :DataName] = [dataName]

    new_row[!, :Config] = [config]

    new_row[!, :Cap] = [cap]

    return new_row
end

