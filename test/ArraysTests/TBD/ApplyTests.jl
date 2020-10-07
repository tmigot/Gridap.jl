module ApplyTests

using Test
using Gridap.Arrays
using Gridap.Arrays: ArrayWithCounter, reset_counter!
using FillArrays
using Gridap.Mappings

a = rand(3,2,4)
test_array(a,a)

a = rand(3,2,4)
a = CartesianIndices(a)
test_array(a,a)

a = rand(3,2)
a = CartesianIndices(a)
c = lazy_map(-,a)
test_array(c,-a)

a = rand(12)
c = lazy_map(-,a)
test_array(c,-a)

a = rand(12)
b = rand(12)
c = lazy_map(-,a,b)
test_array(c,a.-b)

c = lazy_map(Float64,-,a,b)
test_array(c,a.-b)

a = rand(0)
b = rand(0)
c = lazy_map(-,a,b)
test_array(c,a.-b)

a = fill(rand(2,3),12)
b = rand(12)
c = lazy_map(Broadcasting(-),a,b)
test_array(c,[ai.-bi for (ai,bi) in zip(a,b)])

a = fill(rand(2,3),0)
b = rand(0)
c = lazy_map(Broadcasting(-),a,b)
test_array(c,[ai.-bi for (ai,bi) in zip(a,b)])

a = fill(rand(2,3),12)
b = rand(12)
c = lazy_map(Broadcasting(-),a,b)
d = lazy_map(Broadcasting(+),a,c)
e = lazy_map(Broadcasting(*),d,c)
test_array(e,[((ai.-bi).+ai).*(ai.-bi) for (ai,bi) in zip(a,b)])

a = fill(rand(Int,2,3),12)
b = fill(rand(Int,1,3),12)
c = map(array_cache,(a,b))
i = 1
v = getitems!(c,(a,b),i)
v == map((ci,ai) -> getindex!(ci,ai,i),c,(a,b))

i
c
a
b

@test c == (nothing,nothing)
@test v == (a[i],b[i])

a = fill(rand(Int,2,3),12)
b = fill(rand(Int,1,3),12)
ai = testitem(a)
@test ai == a[1]
ai, bi = testitems(a,b)
@test ai == a[1]
@test bi == b[1]

a = fill(rand(Int,2,3),0)
b = fill(1,0)
ai = testitem(a)
@test ai == Array{Int,2}(undef,0,0)
ai, bi = testitems(a,b)
@test ai == Array{Int,2}(undef,0,0)
@test bi == zero(Int)

a = fill(+,10)
x = rand(10)
y = rand(10)
v = lazy_map(a,x,y)
r = [(xi+yi) for (xi,yi) in zip(x,y)]
test_array(v,r)
v = lazy_map(Float64,a,x,y)
test_array(v,r)

a = Fill(Broadcasting(+),10)
x = [rand(2,3) for i in 1:10]
y = [rand(1,3) for i in 1:10]
v = lazy_map(a,x,y)
r = [(xi.+yi) for (xi,yi) in zip(x,y)]
test_array(v,r)

a = Fill(Broadcasting(+),10)
x = [rand(mod(i-1,3)+1,3) for i in 1:10]
y = [rand(1,3) for i in 1:10]
v = lazy_map(a,x,y)
r = [(xi.+yi) for (xi,yi) in zip(x,y)]
test_array(v,r)

# Test the intermediate results caching mechanism

a = ArrayWithCounter(fill(rand(2,3),12))
b = ArrayWithCounter(rand(12))
c = lazy_map(Broadcasting(-),a,b)
d = lazy_map(Broadcasting(+),a,c)
e = lazy_map(Broadcasting(*),d,c)
r = [ (ai.-bi).*(ai.+(ai.-bi)) for (ai,bi) in zip(a,b)]
cache = array_cache(e)
reset_counter!(a)
reset_counter!(b)
for i in 1:length(e)
  ei = getindex!(cache,e,i)
  ei = getindex!(cache,e,i)
  ei = getindex!(cache,e,i)
end

@test all(a.counter .== 2)
@test all(b.counter .== 1)

l = 10
ai = 1.0
bi = 2.0
a = Fill(ai,l)
b = Fill(bi,l)
c = lazy_map(+,a,b)
r = map(+,a,b)
test_array(c,r)
@test isa(c,Fill)

l = 10
ai = [8 0; 0 4]
a = Fill(ai,l)
c = lazy_map(inv,a)
r = map(inv,a)
test_array(c,r)
@test isa(c,Fill)

l = 10
ai = [8 0; 0 4]
a = fill(ai,l)
c = lazy_map(inv,a)
r = map(inv,a)
test_array(c,r)

l = 0
ai = [8 0; 0 4]
a = fill(ai,l)
c = lazy_map(inv,a)
r = map(inv,a)
test_array(c,r)

ai = [8 0; 0 4]
a = CompressedArray([ai,],Int[])
c = lazy_map(inv,a)
r = map(inv,a)
test_array(c,r)

l = 10
ai = [8, 0]
a = fill(ai,l)
f(ai) = ai[2]-ai[1]
c = lazy_map(f,a)
r = map(f,a)
test_array(c,r)

g(ai) = ai[2]-ai[1]
import Gridap.Arrays: testitem!
testitem!(c,::typeof(g),ai) = zero(eltype(ai))
l = 0
ai = [8, 0]
a = fill(ai,l)
c = lazy_map(g,a)
r = map(g,a)
test_array(c,r)


#f = rand(10)
#a = rand(10)
#@test lazy_map(f,a) === f
#
#f = fill(rand(4),10)
#a = rand(10)
#@test lazy_map(f,a) === f
#
#f = fill(rand(4),10)
#g = fill(rand(4),10)
#a = rand(10)
#h = lazy_map_all((f,g),a)
#@test h[1] === f
#@test h[2] === g

#l = 10
#ai = 1.0
#bi = 2.0
#a = fill(ai,l)
#b = fill(bi,l)
#c = lazy_map(+,a,b)
#d = lazy_map(c,a,b)
#@test c == d
#@test typeof(d) == typeof(c)

end # module
