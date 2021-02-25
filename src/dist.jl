function nint(x::Float64)
    return round(Int, x)
end

function geo_coordinate(x, y)
    PI = 3.141592
    
    deg = nint(x)    
    m = x - deg
    latitude = PI * (deg + 5.0 * m / 3.0) / 180.0

    deg = nint(y)
    m = y - deg
    longitude = PI * (deg + 5.0 * m / 3.0) / 180.0 

    return latitude, longitude
end

function distance2D(xi, yi, xj, yj; dist="EUC_2D")
    if dist == "EUC_2D"
        xd = xi - xj
        yd = yi - yj
        return nint(sqrt(xd*xd + yd*yd))
    elseif dist == "MAN_2D"
        xd = abs(xi - xj)
        yd = abs(yi - yj)
        return nint(xd + yd)
    elseif dist == "MAX_2D"
        xd = abs(xi - xj)
        yd = abs(yi - yj)
        return max(nint(xd), nint(yd))      
    elseif dist == "GEO"
        lat_i, long_i = geo_coordinate(xi, yi)
        lat_j, long_j = geo_coordinate(xj, yj)
        RRR = 6378.388
        q1 = cos(long_i - long_j)
        q2 = cos(lat_i - lat_j)
        q3 = cos(lat_i + lat_j)
        dij =  RRR * acos( 0.5*((1.0+q1)*q2 - (1.0-q1)*q3) ) + 1.0
        return floor(Int, dij) 
    else
        error("Distance function $dist is not supported.")
    end
end

function dist_matrix(x::Vector{Float64}, y::Vector{Float64}; dist="EUC_2D")
    n_nodes = length(x)
    @assert length(x) == length(y)
    
    M = Matrix{Int}(undef, n_nodes, n_nodes)

    for i in 1:n_nodes
        for j in i:n_nodes
            if i == j 
                M[i, j] = 0 
            else
                M[i, j] = distance2D(x[i], y[i], x[j], y[j]; dist=dist)
                M[j, i] = M[i, j]
            end
        end
    end
    return M
end