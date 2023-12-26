cd(@__DIR__)

# activate the project
cd(dirname(Base.source_path()))
push!(LOAD_PATH, ENV["p_m"]*"/julia");
Base.load_path();

using PyCall
using DelimitedFiles
using LinearAlgebra

is = pyimport("icosphere")


#-----------------------#
#   FUNCTIONS
#-----------------------#

cat!(a, b) = reshape(append!(vec(a), vec(b)), size(a)[1:end-1]..., :)

function writeMatrix(numArg, trafo, matrix)
    matrixOut = Array{Float64}(undef, 0, numArg)
    for row in eachrow(matrix)
        matrixOut = [matrixOut; trafo(row...)']
    end
    return matrixOut
end

function writeRows(outputStream, matrix, delim, int)
    for row in eachrow(matrix)
        if int != -1
            strRow = map(x->string(x)*delim, row)
            strRow = push!(strRow, string(int))
        else
            strRow = map(x->string(x)*delim, row)
            strRow = strRow[1:end-1];
            push!(strRow, string(Int(row[end]))*delim)
        end
        write(outputStream, reduce(*, strRow))
        write(outputStream, "\n")
    end
end

function writeRow(ofs, row, int, delim)
    strRow = reduce(*   , string.(row).*delim)*string(int)*"\n"
    write(ofs, strRow)
end

function writeRowsNew(ofs, matrix, offset, delim)
    for (i, row) in enumerate(eachrow(matrix))
        writeRow(ofs, row, offset + i, delim)
    end
end

#https://iq.opengenus.org/orientation-of-three-ordered-points/#:~:text=Orientation%20of%20three%20ordered%20points%20refers%20to%20the%20different%20ways,i.e.%20clockwise%20and%20anti%2Dclockwise.

function orientation(p1, p2, p3)
    return -sign(×(p1 - p3, p2 - p3) ⋅ p3)
end


#-----------------------#
#   ITERATIONS
#-----------------------#
begin

    offset = 100000
    
    step_nu = [ (1, 50), (10, 140), (20, 240) ]
    
    nu_iter = Vector{Float64}[]; min_nu = step_nu[1][1]
    for (step, max_nu) in step_nu
        nu_iter = [nu_iter; min_nu:step:max_nu-1]
        min_nu = max_nu
    end
    
    nu_ofs = open("meshS/nu.log", "w+")
    
    for (nu_ind, nu) in enumerate(nu_iter)
    
        write(nu_ofs, string(nu)*"\n")
    
        outputStream = open("meshS/" *  string(nu_ind) * ".mesh", "w+")
    
        vertices, faces = is.icosphere(nu)
        faces .+= 1
    
        write(outputStream,
        """
        MeshVersionFormatted 2
        
        Dimension 3
    
        Vertices
        """
        )
    
        write(outputStream, string(size(vertices, 1))*"\n")
    
        labVertices = 1:size(vertices, 1)
    
        labVertices::Vector{Int64} = offset .+ (1:size(vertices, 1))
    
        writeRowsNew(outputStream, vertices, offset, " ")
        offset += size(vertices, 1)
    
        write(outputStream, "\nTriangles\n")
    
        for (idx, elem) in enumerate(eachrow(faces))
            p1 = vertices[elem[1], :]
            p2 = vertices[elem[2], :]
            p3 = vertices[elem[3], :]
            if !(orientation(p1, p2, p3) > 0)
                permute!(faces[idx, :], [2, 1, 3])
            end
        end
    
        write(outputStream, string(size(faces, 1))*"\n")
    
        facesOut::Matrix{Int64}=[faces zeros(Int64, size(faces, 1))]
        writedlm(outputStream, facesOut, " ")
    
        write(outputStream, "\nEdges\n")
    
        edges = zeros(Int64, 3 * size(faces, 1), 3)
        for (rowInd, row) in enumerate(eachrow(edges))
            for i = 1:3
                rowFaceInd = Int(floor((rowInd-1)/3)) + 1
                row .= [faces[rowFaceInd, i], faces[rowFaceInd, i%3+1], 0]  
            end
        end
    
        edges = unique(edges, dims = 1)
        
        write(outputStream, string(size(edges,1))*"\n")
    
        writedlm(outputStream, edges, " ")
    
        write(outputStream, "\nEnd\n")
    
        close(outputStream)
    end
    
    close(nu_ofs)
end