///|
trait Graph {
  empty() -> Self
  vertex(VertRep) -> Self
  overlay(Self, Self) -> Self
  connect(Self, Self) -> Self
}

///|
pub fn vertices[A : Graph, V : Vertex](x : Array[V]) -> A {
  x
  .map(fn { x => Graph::vertex(V::wrap(x)) })
  .fold(init=Graph::empty(), Graph::overlay)
}

///|
pub fn connects[A : Graph, V : Vertex](x : Array[V]) -> A {
  x
  .map(fn { x => Graph::vertex(V::wrap(x)) })
  .fold(init=Graph::empty(), Graph::connect)
}

///|
pub fn edge[A : Graph, V : Vertex](x : V, y : V) -> A {
  Graph::connect(Graph::vertex(V::wrap(x)), Graph::vertex(V::wrap(y)))
}

///|
pub fn clique[A : Graph, V : Vertex](x : Array[V]) -> A {
  x
  .map(fn { x => Graph::vertex(V::wrap(x)) })
  .fold(init=Graph::empty(), Graph::connect)
}
