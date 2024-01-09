using CSV
using DataFrames

# Function to read a CSV file
function read_csv(filepath)
    return CSV.read(filepath, DataFrame)
end

# Function to write a DataFrame to a CSV file
function write_csv(df, filepath)
    CSV.write(filepath, df)
end