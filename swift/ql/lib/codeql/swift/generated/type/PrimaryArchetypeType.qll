// generated by codegen/codegen.py
import codeql.swift.elements.type.ArchetypeType
import codeql.swift.elements.type.GenericTypeParamType

class PrimaryArchetypeTypeBase extends @primary_archetype_type, ArchetypeType {
  override string toString() { result = "PrimaryArchetypeType" }

  GenericTypeParamType getInterfaceType() {
    exists(GenericTypeParamType x |
      primary_archetype_types(this, x) and
      result = x.resolve()
    )
  }
}
