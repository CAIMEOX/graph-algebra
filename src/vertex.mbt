///|
type VertRep Error

///|
trait Vertex {
  extract(VertRep) -> Self
  rep(Self) -> VertRep
}

///|
impl Vertex for VertRep with extract(self) {
  match self {
    VertRep(x) => x
  }
}

///|
impl Vertex for VertRep with rep(self) { self }

///|
type! StringVertex String

///|
impl Vertex for String with extract(self) {
  match self {
    VertRep(StringVertex(x)) => x
    _ => abort("Expected StringVertex")
  }
}

///|
impl Vertex for String with rep(self) { VertRep(StringVertex(self)) }

///|
type! IntVertex Int

///|
impl Vertex for Int with extract(self) {
  match self {
    VertRep(IntVertex(x)) => x
    _ => abort("Expected IntVertex")
  }
}

///|
impl Vertex for Int with rep(self) { VertRep(IntVertex(self)) }

test "string vertex" {
  let x : Array[String] = ["a", "b", "c"]
  let y : GraphData[String] = vertices(x)
  let y1 : GraphData[String] = clique(x)
  let z : Relation[String] = vertices(x)
  inspect!(y, content="$e + a + b + c")
  inspect!(y1, content="((($e -> a) -> b) -> c)")
  inspect!(
    z,
    content=
      #|Rel[@immut/sorted_set.of(["a", "b", "c"]), @immut/sorted_set.of([])]
    ,
  )
}

test "int vertex" {
  let x : Array[Int] = [1, 2, 3]
  let y : GraphData[Int] = vertices(x)
  let y1 : GraphData[Int] = clique(x)
  let z : Relation[Int] = vertices(x)
  let z1 : Relation[Int] = clique(x)
  inspect!(y, content="$e + 1 + 2 + 3")
  inspect!(y1, content="((($e -> 1) -> 2) -> 3)")
  inspect!(
    z,
    content=
      #|Rel[@immut/sorted_set.of([1, 2, 3]), @immut/sorted_set.of([])]
    ,
  )
  inspect!(
    z1,
    content=
      "Rel[@immut/sorted_set.of([1, 2, 3]), @immut/sorted_set.of([(1, 2), (1, 3), (2, 3)])]"
    ,
  )
}
