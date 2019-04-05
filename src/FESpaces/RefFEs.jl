module RefFEs

using Numa.Helpers
using Numa.FieldValues
using Numa.Polytopes
using Numa.Polynomials

export DOFBasis
export RefFE
export LagrangianRefFE
# export shfsps, gradshfsps

# Abstract types and interfaces

"""
Abstract DOF cell basis
"""
abstract type DOFBasis{D,T} end

function nodeevaluate(this::DOFBasis{D,T},
	prebasis::MultivariatePolynomialBasis{D,T})::Array{Float64,2} where {D,T}
	@abstractmethod
end

# evaluate(this::DOFBasis, prebasis::Field{D,T})::Vector{Float64} = @abstractmethod
# Field to be implemented, to answer evaluate and gradient, it can be a local FE
# function or an analytical function

"""
Lagrangian DOF basis, which consists on evaluating the polynomial basis
(prebasis) in a set of points (nodes)
"""
struct LagrangianDOFBasis{D,T} <: DOFBasis{D,T}
  nodes::Array{Point{D}}
end

"""
Evaluate the Lagrangian DOFs basis on a set of nodes
"""
function nodeevaluate(this::LagrangianDOFBasis{D,T},
	prebasis::MultivariatePolynomialBasis{D,T}) where {D,T}
	vals = evaluate(prebasis,this.nodes)
	l = length(prebasis); lt = length(T)
	E = eltype(T)
	b = Array{E,2}(undef,l, l)
	nnd = length(this.nodes)
	@assert nnd*length(T) == length(prebasis)
	function computeb!(a,b,lt,nnd)
		for k in 1:lt
			off = nnd*(k-1)
			for j in 1:size(a,2)
				for i in 1:size(a,1)
					b[i,j+off] = a[i,j][k]
				end
			end
		end
	end
	computeb!(vals,b,lt,nnd)
	return b
end


"""
Abstract Reference Finite Element
"""
abstract type RefFE{D,T} end

dofs(this::RefFE{D,T} where {D,T})::DOFBasis{D,T} = @abstractmethod

# permutation(this::RefFE, nf::Int, cell_vertex_gids::AbstractVector{Int},
# nface_vertex_gids::AbstractVector{Int}, nface_order::Int)::Vector{Int}
# = @abstractmethod
# @santiagobadia : To do in the future, not needed for the moment

polytope(this::RefFE{D,T} where {D,T})::Polytope{D} = @abstractmethod

shapefunctions(this::RefFE{D,T} where {D,T})::MultivariatePolynomialBasis{D,T} = @abstractmethod

nfacetoowndofs(this::RefFE{D,T} where {D,T})::Vector{Vector{Int}} = @abstractmethod

"""
Reference Finite Element a la Ciarlet, i.e., it relies on a local function
(polynomial) space, an array of nodes (DOFs), and a polytope (cell topology).
The rank of the approximating field can be arbitrary. The current implementation
relies on the prebasis (e.g., monomial basis of polynomials) and a
change-of-basis (using the node array) to generate the canonical basis, i.e.,
the shape functions.
"""
struct LagrangianRefFE{D,T} <: RefFE{D,T}
	polytope::Polytope{D}
	dofbasis::LagrangianDOFBasis{D,T}
	shfbasis::MPB_WithChangeOfBasis{D,T}
	nfacedofs::Vector{Vector{Int}}
end

function LagrangianRefFE{D,T}(polytope::Polytope{D},
	orders::Array{Int64,1}) where {D,T}
	nodes=NodesArray(polytope,orders)
	dofsb = LagrangianDOFBasis{D,T}(nodes.coordinates)
	prebasis = TensorProductMonomialBasis{D,T}(orders)
	changeofbasis=inv(nodeevaluate(dofsb,prebasis))
	basis = MPB_WithChangeOfBasis{D,T}(prebasis, changeofbasis)
	nfacedofs=nodes.nfacenodes
	# println(changeofbasis)
	# numdof = size(changeofbasis,1)*length(T)
	LagrangianRefFE{D,T}(polytope, dofsb, basis, nfacedofs)
end

end # module RefFEs