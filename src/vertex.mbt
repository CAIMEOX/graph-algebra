///|
pub type VertRep Error

///|
pub trait Vertex {
  extract(VertRep) -> Self
  rep(Self) -> VertRep
}

///|
pub impl Vertex for VertRep with extract(self) {
  match self {
    VertRep(x) => x
  }
}

///|
pub impl Vertex for VertRep with rep(self) { self }

///|
type! StringVertex String

///|
pub impl Vertex for String with extract(self) {
  match self {
    VertRep(StringVertex(x)) => x
    _ => abort("Expected StringVertex")
  }
}

///|
pub impl Vertex for String with rep(self) { VertRep(StringVertex(self)) }

///|
type! IntVertex Int

///|
pub impl Vertex for Int with extract(self) {
  match self {
    VertRep(IntVertex(x)) => x
    _ => abort("Expected IntVertex")
  }
}

///|
pub impl Vertex for Int with rep(self) { VertRep(IntVertex(self)) }

///|
type! UnitVertex Unit

///|
pub impl Vertex for Unit with extract(_) { () }

///|
pub impl Vertex for Unit with rep(_) { VertRep(UnitVertex(())) }
