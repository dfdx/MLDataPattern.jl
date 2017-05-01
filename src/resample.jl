"""
    oversample([f], data, [shuffle = true], [obsdim])

Generate a class-balanced version of `data` by repeatedly
sampling existing observations in such a way that the resulting
number of observations will be the same number for every class.
This way, all classes will have as many observations in the
resulting data set as the largest class has in the given
(original) `data`.

The convenience parameter `shuffle` determines if the
resulting data will be shuffled after its creation; if it is not
shuffled then all the repeated samples will be together at the
end, sorted by class. Defaults to `true`.

The optional parameter `obsdim` can be used to specify which
dimension denotes the observations, if that concept makes sense
for the type of `data`. See `?ObsDim` for more information.

```julia
# 6 observations with 3 features each
X = rand(3, 6)
# 2 classes, severely imbalanced
Y = ["a", "b", "b", "b", "b", "a"]

# oversample the class "a" to match "b"
X_bal, Y_bal = oversample((X,Y))

# this results in a bigger dataset with repeated data
@assert size(X_bal) == (3,8)
@assert length(Y_bal) == 8

# now both "a", and "b" have 4 observations each
@assert sum(Y_bal .== "a") == 4
@assert sum(Y_bal .== "b") == 4
```

For this function to work, the type of `data` must implement
[`nobs`](@ref) and [`getobs`](@ref). For example, the following
code allows `oversample` to work on a `DataTable`.

```julia
# Make DataTables.jl work
LearnBase.getobs(data::DataTable, i) = data[i,:]
LearnBase.nobs(data::DataTable) = nrow(data)
```

You can use the parameter `f` to specify how to extract or
retrieve the targets from each observation of the given `data`.
Note that if `data` is a tuple, then it will be assumed that the
last element of the tuple contains the targets and `f` will be
applied to each observation in that element.

```julia
julia> data = DataTable(Any[rand(6), rand(6), [:a,:b,:b,:b,:b,:a]], [:X1,:X2,:Y])
6×3 DataTables.DataTable
│ Row │ X1        │ X2          │ Y │
├─────┼───────────┼─────────────┼───┤
│ 1   │ 0.226582  │ 0.0443222   │ a │
│ 2   │ 0.504629  │ 0.722906    │ b │
│ 3   │ 0.933372  │ 0.812814    │ b │
│ 4   │ 0.522172  │ 0.245457    │ b │
│ 5   │ 0.505208  │ 0.11202     │ b │
│ 6   │ 0.0997825 │ 0.000341996 │ a │

julia> getobs(oversample(row->row[:Y], data))
8×3 DataTables.DataTable
│ Row │ X1        │ X2          │ Y │
├─────┼───────────┼─────────────┼───┤
│ 1   │ 0.0997825 │ 0.000341996 │ a │
│ 2   │ 0.505208  │ 0.11202     │ b │
│ 3   │ 0.226582  │ 0.0443222   │ a │
│ 4   │ 0.0997825 │ 0.000341996 │ a │
│ 5   │ 0.504629  │ 0.722906    │ b │
│ 6   │ 0.522172  │ 0.245457    │ b │
│ 7   │ 0.226582  │ 0.0443222   │ a │
│ 8   │ 0.933372  │ 0.812814    │ b │
```

see [`DataSubset`](@ref) for more information on data subsets.

see also [`undersample`](@ref) and [`stratifiedobs`](@ref).
"""
oversample(data; shuffle=true, obsdim=default_obsdim(data)) =
    oversample(identity, data, shuffle, convert(LearnBase.ObsDimension,obsdim))

oversample(data, shuffle::Bool, obsdim=default_obsdim(data)) =
    oversample(identity, data, shuffle, obsdim)

oversample(f, data; shuffle=true, obsdim=default_obsdim(data)) =
    oversample(f, data, shuffle, convert(LearnBase.ObsDimension,obsdim))

function oversample(f, data, shuffle::Bool, obsdim=default_obsdim(data))
    lm = labelmap(eachtarget(f, data, obsdim))
    maxcount = maximum(length, values(lm))

    # firstly we will start by keeping everything
    inds = collect(1:nobs(data, obsdim))
    sizehint!(inds, nlabel(lm)*maxcount)

    for (lbl, inds_for_lbl) in lm
        num_extra_needed = maxcount - length(inds_for_lbl)
        while num_extra_needed > length(inds_for_lbl)
            num_extra_needed-=length(inds_for_lbl)
            append!(inds, inds_for_lbl)
        end
        append!(inds, sample(inds_for_lbl, num_extra_needed; replace=false))
    end

    shuffle && shuffle!(inds)
    datasubset(data, inds, obsdim)
end

"""
    undersample([f], data, [shuffle = false], [obsdim])

Generate a class-balanced version of `data` by subsampling its
observations in such a way that the resulting number of
observations will be the same number for every class. This way,
all classes will have as many observations in the resulting data
set as the smallest class has in the given (original) `data`.

The convenience parameter `shuffle` determines if the
resulting data will be shuffled after its creation; if it is not
shuffled then all the observations will be in their original
order. Defaults to `false`.

The optional parameter `obsdim` can be used to specify which
dimension denotes the observations, if that concept makes sense
for the type of `data`. See `?ObsDim` for more information.

```julia
# 6 observations with 3 features each
X = rand(3, 6)
# 2 classes, severely imbalanced
Y = ["a", "b", "b", "b", "b", "a"]

# subsample the class "b" to match "a"
X_bal, Y_bal = undersample((X,Y))

# this results in a smaller dataset
@assert size(X_bal) == (3,4)
@assert length(Y_bal) == 4

# now both "a", and "b" have 2 observations each
@assert sum(Y_bal .== "a") == 2
@assert sum(Y_bal .== "b") == 2
```

For this function to work, the type of `data` must implement
[`nobs`](@ref) and [`getobs`](@ref). For example, the following
code allows `undersample` to work on a `DataTable`.

```julia
# Make DataTables.jl work
LearnBase.getobs(data::DataTable, i) = data[i,:]
LearnBase.nobs(data::DataTable) = nrow(data)
```

You can use the parameter `f` to specify how to extract or
retrieve the targets from each observation of the given `data`.
Note that if `data` is a tuple, then it will be assumed that the
last element of the tuple contains the targets and `f` will be
applied to each observation in that element.

```julia
julia> data = DataTable(Any[rand(6), rand(6), [:a,:b,:b,:b,:b,:a]], [:X1,:X2,:Y])
6×3 DataTables.DataTable
│ Row │ X1        │ X2          │ Y │
├─────┼───────────┼─────────────┼───┤
│ 1   │ 0.226582  │ 0.0443222   │ a │
│ 2   │ 0.504629  │ 0.722906    │ b │
│ 3   │ 0.933372  │ 0.812814    │ b │
│ 4   │ 0.522172  │ 0.245457    │ b │
│ 5   │ 0.505208  │ 0.11202     │ b │
│ 6   │ 0.0997825 │ 0.000341996 │ a │

julia> getobs(undersample(row->row[:Y], data))
4×3 DataTables.DataTable
│ Row │ X1        │ X2          │ Y │
├─────┼───────────┼─────────────┼───┤
│ 1   │ 0.226582  │ 0.0443222   │ a │
│ 2   │ 0.504629  │ 0.722906    │ b │
│ 3   │ 0.522172  │ 0.245457    │ b │
│ 4   │ 0.0997825 │ 0.000341996 │ a │
```

see [`DataSubset`](@ref) for more information on data subsets.

see also [`oversample`](@ref) and [`stratifiedobs`](@ref).
"""
undersample(data; shuffle=false, obsdim=default_obsdim(data)) =
    undersample(identity, data, shuffle, convert(LearnBase.ObsDimension,obsdim))

undersample(data, shuffle::Bool, obsdim=default_obsdim(data)) =
    undersample(identity, data, shuffle, obsdim)

undersample(f, data; shuffle=false, obsdim=default_obsdim(data)) =
    undersample(f, data, shuffle, convert(LearnBase.ObsDimension,obsdim))

function undersample(f, data, shuffle::Bool, obsdim=default_obsdim(data))
    lm = labelmap(eachtarget(f, data, obsdim))
    mincount = minimum(length, values(lm))

    inds = Int[]
    sizehint!(inds, nlabel(lm)*mincount)

    for (lbl, inds_for_lbl) in lm
        append!(inds, sample(inds_for_lbl, mincount; replace=false))
    end

    shuffle ? shuffle!(inds) : sort!(inds)
    datasubset(data, inds, obsdim)
end

# Make sure the R people find the functionality
@deprecate upsample(args...; kw...) oversample(args...; kw...)
@deprecate downsample(args...; kw...) undersample(args...; kw...)
