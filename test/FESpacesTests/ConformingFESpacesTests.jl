module ConformingFESpacesTests

using Test
using Gridap
using Gridap.CellValuesGallery
using Gridap.ConformingFESpaces: CellEqClass

model = CartesianDiscreteModel(domain=(0.0,1.0,-1.0,2.0), partition=(2,2))

cell_to_nfaces = [[1,2,4,5,7,8,9,10,14],[2,3,5,6,11,12,10,13,15]]
nface_to_dofs = [[i*10,] for i in 1:15]

cell_to_nfaces = CellValueFromArray(cell_to_nfaces)
nface_to_dofs = CellValueFromArray(nface_to_dofs)

D = 2
order = 2
orders = fill(order,D)
polytope = Polytope(fill(HEX_AXIS,D)...)
fe = LagrangianRefFE{D,Float64}(polytope, orders)

cell_to_dofs = CellEqClass(cell_to_nfaces,nface_to_dofs,fe)

r = [
  [10, 70, 20, 90, 140, 100, 40, 80, 50],
  [20, 110, 30, 100, 150, 130, 50, 120, 60]]
test_index_cell_array(cell_to_dofs,r)


model = CartesianDiscreteModel(domain=(0.0,1.0,-1.0,2.0), partition=(2,2))

D = pointdim(model)

grid = Grid(model,D)
trian = Triangulation(grid)
graph = GridGraph(model)
labels = FaceLabels(model)
tags = [1,2,3,4]

order = 1
orders = fill(order,D)
polytope = Polytope(fill(HEX_AXIS,D)...)
fe = LagrangianRefFE{D,Float64}(polytope, orders)

fespace = ConformingFESpace(fe,trian,graph,labels,tags)

@test num_free_dofs(fespace) == 5
@test num_diri_dofs(fespace) == 4

@test diri_tags(fespace) === tags

r = [[-1, 1, 2, 3], [1, -2, 3, 4], [2, 3, -3, 5], [3, 4, 5, -4]]

@test r == collect(fespace.cell_eqclass)

order = 2
orders = fill(order,D)
polytope = Polytope(fill(HEX_AXIS,D)...)
fe = LagrangianRefFE{D,Float64}(polytope, orders)

tags = [1,2,3,4,6,5]
fespace = ConformingFESpace(fe,trian,graph,labels,tags)

@test num_free_dofs(fespace) == 15
@test num_diri_dofs(fespace) == 10

r = [[-1, -7, -2, 5, 12, 6, 1, 4, 2],
  [-2, -8, -3, 6, 13, 8, 2, 7, 3],
  [1, 4, 2, 9, 14, 10, -4, -9, -5],
  [2, 7, 3, 10, 15, 11, -5, -10, -6]]

@test r == collect(fespace.cell_eqclass)

fun(x) = sin(x[1])*cos(x[2])

free_vals, diri_vals = interpolate_values(fespace,fun)

rf = [
  0.0, 0.420735, 0.73846, 0.217117, 0.0, 0.464521,
  0.598194, 0.815312, 0.0, 0.151174, 0.265335,
  0.239713, 0.660448, 0.078012, 0.214936]

rd = [
  0.0, 0.259035, 0.454649, -0.0, -0.199511,
  -0.350175, 0.133673, 0.368291, -0.102956, -0.283662]

@test isapprox(free_vals,rf,rtol=1.0e-5)
@test isapprox(diri_vals,rd,rtol=1.0e-5)

diri_vals = interpolate_diri_values(fespace,fun)
@test isapprox(diri_vals,rd,rtol=1.0e-5)

diri_vals = interpolate_diri_values(fespace,fill(fun,length(tags)))
@test isapprox(diri_vals,rd,rtol=1.0e-5)

uh = FEFunction(fespace,free_vals,diri_vals)

@test free_dofs(uh) === free_vals
@test diri_dofs(uh) === diri_vals
@test FESpace(uh) === fespace

zh = zero(fespace)

@test free_dofs(zh) == zeros(Float64,num_free_dofs(fespace))
@test diri_dofs(zh) == zeros(Float64,num_diri_dofs(fespace))
@test FESpace(zh) === fespace


U = TrialFESpace(fespace,fun)

zh = zero(U)
@test free_dofs(zh) == zeros(Float64,num_free_dofs(U))
@test diri_dofs(zh) === U.diri_dofs
@test FESpace(zh) === U

cellbasis = CellBasis(fespace)

quad = CellQuadrature(trian,order=2)

a(v,u) = varinner(v,u)

bfun(x) = x[2]

b(v) = varinner(v,CellField(trian,bfun))

mmat = integrate(a(cellbasis,cellbasis),trian,quad)

bvec = integrate(b(cellbasis),trian,quad)

cellids = IdentityCellNumber(Int,length(bvec))
bvec2 = apply_constraints(fespace,bvec,cellids)
dofs = celldofids(fespace)

@test bvec2 === bvec

@test dofs == fespace.cell_eqclass

mmat2 = apply_constraints_rows(fespace,mmat,cellids)
dofs = celldofids(fespace)

@test mmat2 === mmat

@test dofs == fespace.cell_eqclass

mmat3 = apply_constraints_cols(fespace,mmat,cellids)
dofs = celldofids(fespace)

@test mmat3 === mmat

@test dofs == fespace.cell_eqclass

uh = interpolate(fespace,fun)
@test isa(uh,FEFunction)

q = coordinates(quad)
uhq = evaluate(uh,q)

grad_uh = gradient(uh)
grad_uhq = evaluate(grad_uh,q)

v = collect(uhq)
g = collect(grad_uhq)

test_index_cell_field(uh,q,v,g)

test_fe_space(fespace,15,10,mmat,bvec,fun)

fespace = ConformingFESpace(Float64,model,order,tags)

model = CartesianDiscreteModel(domain=(0.0,1.0,0.0,1.0), partition=(2,2))

order = 1
fespace = ConformingFESpace(Float64,model,order,tags)

grid = Grid(model,D)
trian = Triangulation(grid)

fun1(x) = x[1]
uh1 = interpolate(fespace,fun1)

fun2(x) = x[1]*x[2]
uh2 = interpolate(fespace,fun2)

fun3(x) = sin(x[1])*cos(x[2])
uh3 = interpolate(fespace,fun3)

quad = CellQuadrature(trian,order=2)
q = coordinates(quad)
uhq = evaluate(uh1,q)


#writevtk(trian,"trian",nref=3,
#  cellfields=["uh1"=>uh1,"uh2"=>uh2,"uh3"=>uh3])


# NOT WORKING for order == 2

model = CartesianDiscreteModel(domain=(0.0,1.0,0.0,1.0), partition=(2,2))
trian = Triangulation(model)

order = 2
tags = [1,2,3,4,6,5]
fespace = ConformingFESpace(Float64,model,order,tags)

fun(x) = x[1] + x[2]
uh = interpolate(fespace,fun)

#writevtk(trian,"trian", nref=4, cellfields=["uh"=>uh])

end # module

